/**
 * Final check CLI for Claude Code hooks
 * Runs comprehensive validation before allowing Stop/completion
 */

import { SecureHookBase, HookLogger, runSecureHook, HookResult } from '@claude-dev/hooks';

class FinalCheckCLI extends SecureHookBase {
  private logger: HookLogger;

  constructor() {
    super();
    this.logger = new HookLogger();
  }

  async main(): Promise<HookResult> {
    const startTime = Date.now();
    
    try {
      // Read and sanitize input from stdin
      const input = await this.readAndSanitizeStdin();
      
      // Extract relevant data
      const { tool_name, tool_input, session_id } = input;

      // Only run final checks on Stop events
      if (tool_name !== 'Stop' && tool_name !== 'SubagentStop') {
        await this.logger.logEvent({
          hookName: 'final-check',
          toolName: tool_name || 'unknown',
          duration: Date.now() - startTime,
          result: 'allow',
          metadata: { reason: 'not_stop_event' }
        });
        
        return this.allow();
      }

      console.log('🔍 Running final quality checks...');

      // Run comprehensive validation suite
      const validationResults = await this.runFinalValidation();
      
      // Check for any critical failures
      const criticalFailures = validationResults.filter(result => result.critical && !result.success);
      
      if (criticalFailures.length > 0) {
        const allErrors = criticalFailures.flatMap(f => f.errors || []);
        
        await this.logger.logEvent({
          hookName: 'final-check',
          toolName: tool_name || 'Stop',
          duration: Date.now() - startTime,
          result: 'deny',
          errors: allErrors,
          metadata: {
            criticalFailures: criticalFailures.length,
            totalChecks: validationResults.length,
            failedChecks: criticalFailures.map(f => f.name)
          }
        });

        return this.deny(
          'Quality gate failed - critical issues found',
          [
            '🚫 Critical issues must be resolved before completion:',
            ...allErrors.slice(0, 10), // Limit to first 10 errors
            ...(allErrors.length > 10 ? [`... and ${allErrors.length - 10} more errors`] : [])
          ]
        );
      }

      // Check for warnings
      const warnings = validationResults.filter(result => !result.success && !result.critical);
      
      if (warnings.length > 0) {
        console.log('⚠️  Non-critical issues found but allowing completion:');
        warnings.forEach(warning => {
          console.log(`  • ${warning.name}: ${warning.errors?.[0] || 'Check failed'}`);
        });
      }

      // Generate session report
      const sessionReport = await this.generateSessionReport(session_id);
      
      await this.logger.logEvent({
        hookName: 'final-check',
        toolName: tool_name || 'Stop',
        duration: Date.now() - startTime,
        result: 'allow',
        metadata: {
          checksRun: validationResults.length,
          criticalPassed: validationResults.filter(r => r.critical && r.success).length,
          warningsFound: warnings.length,
          sessionReport: sessionReport ? 'generated' : 'failed'
        }
      });

      // Close session analytics
      await this.logger.updateSession({
        endTime: new Date().toISOString(),
        totalEvents: validationResults.length
      });

      console.log('✅ Quality gate passed - all critical checks successful');
      
      if (sessionReport) {
        console.log('\n📊 Session Analytics:');
        console.log(sessionReport);
      }

      return this.allow();

    } catch (error) {
      await this.logger.logError(error as Error, {
        hookName: 'final-check',
        toolName: input?.tool_name,
        duration: Date.now() - startTime
      });

      return this.deny('Final check failed: ' + (error instanceof Error ? error.message : 'Unknown error'));
    }
  }

  /**
   * Run comprehensive validation suite
   */
  private async runFinalValidation(): Promise<Array<{
    name: string;
    success: boolean;
    critical: boolean;
    duration: number;
    errors?: string[];
    stdout?: string;
  }>> {
    const results = [];

    console.log('  • Running lint checks...');
    results.push(await this.runCheck('lint', true, async () => {
      return await this.executeSecurely('nx', ['affected', '-t', 'lint', '--bail'], { timeout: 60000 });
    }));

    console.log('  • Running type checks...');
    results.push(await this.runCheck('typecheck', true, async () => {
      // Try nx typecheck first, fall back to tsc
      const nxResult = await this.executeSecurely('nx', ['affected', '-t', 'typecheck'], { timeout: 120000 });
      
      if (nxResult.success) {
        return nxResult;
      }
      
      // Fall back to direct TypeScript check
      return await this.executeSecurely('npx', ['tsc', '--noEmit', '--skipLibCheck'], { timeout: 60000 });
    }));

    console.log('  • Running tests...');
    results.push(await this.runCheck('test', false, async () => {
      return await this.executeSecurely('nx', ['affected', '-t', 'test', '--bail'], { timeout: 180000 });
    }));

    console.log('  • Checking build status...');
    results.push(await this.runCheck('build', false, async () => {
      return await this.executeSecurely('nx', ['affected', '-t', 'build'], { timeout: 300000 });
    }));

    console.log('  • Security scan...');
    results.push(await this.runCheck('security', true, async () => {
      // Run a basic security scan
      const auditResult = await this.executeSecurely('npm', ['audit', '--audit-level', 'high'], { timeout: 30000 });
      
      // npm audit returns non-zero for vulnerabilities, but we want to allow moderate/low
      if (auditResult.stderr.includes('found 0 vulnerabilities') || 
          !auditResult.stderr.includes('high') && !auditResult.stderr.includes('critical')) {
        return { success: true, stdout: auditResult.stdout, stderr: auditResult.stderr };
      }
      
      return auditResult;
    }));

    console.log('  • Dependency check...');
    results.push(await this.runCheck('dependencies', false, async () => {
      // Check for unused dependencies
      const result = await this.executeSecurely('npx', ['depcheck', '--ignores', 'typescript,@types/*'], { timeout: 30000 });
      
      // depcheck returns 0 even with unused deps, so we check output
      if (result.stdout.includes('No depcheck issue')) {
        return { success: true, stdout: result.stdout, stderr: result.stderr };
      }
      
      return result;
    }));

    return results;
  }

  /**
   * Run a single validation check with timing and error handling
   */
  private async runCheck(
    name: string, 
    critical: boolean, 
    checkFn: () => Promise<{ success: boolean; stdout: string; stderr: string; errors?: string[] }>
  ): Promise<{
    name: string;
    success: boolean;
    critical: boolean;
    duration: number;
    errors?: string[];
    stdout?: string;
  }> {
    const startTime = Date.now();
    
    try {
      const result = await checkFn();
      
      return {
        name,
        success: result.success,
        critical,
        duration: Date.now() - startTime,
        errors: result.success ? undefined : [result.stderr || `${name} check failed`],
        stdout: result.stdout
      };
      
    } catch (error) {
      return {
        name,
        success: false,
        critical,
        duration: Date.now() - startTime,
        errors: [error instanceof Error ? error.message : `${name} check error`]
      };
    }
  }

  /**
   * Generate session analytics report
   */
  private async generateSessionReport(sessionId?: string): Promise<string | null> {
    try {
      const analytics = await this.logger.generateAnalytics(1);
      
      const report = `
Files modified: ${analytics.sessionStats.filesModified}
Tools used: ${analytics.sessionStats.toolsUsed.length} (${analytics.sessionStats.toolsUsed.join(', ')})
Hook executions: ${analytics.sessionStats.hookExecutions}
Security violations: ${analytics.securityMetrics.totalViolations}
Avg hook duration: ${analytics.sessionStats.avgHookDuration}ms
      `.trim();

      return report;
      
    } catch (error) {
      console.error('Failed to generate session report:', error);
      return null;
    }
  }
}

// Run the CLI if called directly
if (require.main === module) {
  runSecureHook(FinalCheckCLI);
}