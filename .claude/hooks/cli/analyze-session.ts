/**
 * Session analytics CLI for Claude Code hooks
 * Generates comprehensive analytics reports and insights
 */

import { SecureHookBase, HookLogger, runSecureHook, HookResult } from '@claude-dev/hooks';

class AnalyzeSessionCLI extends SecureHookBase {
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

      console.log('📊 Generating session analytics...');

      // Generate comprehensive analytics report
      const report = await this.generateComprehensiveReport();
      
      // Write report to file
      const reportPath = await this.saveReport(report, session_id);
      
      // Log the analytics generation
      await this.logger.logEvent({
        hookName: 'analyze-session',
        toolName: tool_name || 'analyze',
        duration: Date.now() - startTime,
        result: 'allow',
        metadata: {
          reportPath,
          reportSize: report.length
        }
      });

      // Output summary to console
      console.log('\n' + report);
      console.log(`\n📄 Full report saved to: ${reportPath}`);

      return this.allow();

    } catch (error) {
      await this.logger.logError(error as Error, {
        hookName: 'analyze-session',
        toolName: input?.tool_name || 'analyze',
        duration: Date.now() - startTime
      });

      console.error('❌ Analytics generation failed:', error instanceof Error ? error.message : 'Unknown error');
      return this.allow(); // Don't block on analytics failures
    }
  }

  /**
   * Generate comprehensive analytics report
   */
  private async generateComprehensiveReport(): Promise<string> {
    try {
      const analytics = await this.logger.generateAnalytics(7); // Last 7 days
      const fullReport = await this.logger.generateReport();
      
      // Add additional insights
      const insights = await this.generateInsights(analytics);
      const performance = await this.analyzePerformanceTrends();
      const security = await this.generateSecuritySummary(analytics);

      return `
${fullReport}

🔍 Additional Insights
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${insights}

⚡ Performance Trends
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${performance}

🔒 Security Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${security}

📈 Next Steps
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${this.generateNextSteps(analytics)}
      `.trim();
      
    } catch (error) {
      console.error('Failed to generate comprehensive report:', error);
      throw error;
    }
  }

  /**
   * Generate behavioral insights
   */
  private async generateInsights(analytics: any): Promise<string> {
    const insights = [];
    
    // File type analysis
    const fileTypes = Object.keys(analytics.sessionStats.toolsUsed || {});
    if (fileTypes.length > 0) {
      insights.push(`Primary file types: ${fileTypes.slice(0, 3).join(', ')}`);
    }

    // Productivity analysis
    const avgDuration = analytics.sessionStats.avgHookDuration || 0;
    if (avgDuration > 2000) {
      insights.push(`Slow validation detected (${avgDuration}ms avg) - consider optimization`);
    } else if (avgDuration < 100) {
      insights.push(`Fast validation performance (${avgDuration}ms avg) - excellent!`);
    }

    // Error patterns
    const errorRate = analytics.sessionStats.blockedOperations / analytics.sessionStats.totalEvents;
    if (errorRate > 0.1) {
      insights.push(`High error rate (${Math.round(errorRate * 100)}%) - review common issues`);
    } else if (errorRate < 0.05) {
      insights.push(`Low error rate (${Math.round(errorRate * 100)}%) - quality coding practices`);
    }

    // Tool usage patterns
    const toolStats = analytics.toolUsage || {};
    const mostUsedTool = Object.entries(toolStats).sort(([,a], [,b]) => (b as any).uses - (a as any).uses)[0];
    if (mostUsedTool) {
      insights.push(`Most used tool: ${mostUsedTool[0]} (${(mostUsedTool[1] as any).uses} times)`);
    }

    return insights.length > 0 ? insights.map(i => `• ${i}`).join('\n') : 'No specific insights available';
  }

  /**
   * Analyze performance trends
   */
  private async analyzePerformanceTrends(): Promise<string> {
    try {
      // Read recent performance data
      const perfData = await this.readPerformanceHistory();
      
      if (perfData.length === 0) {
        return 'No performance data available';
      }

      const trends = [];
      
      // Calculate average durations by hook
      const hookTrends = this.calculateHookTrends(perfData);
      for (const [hook, trend] of Object.entries(hookTrends)) {
        if (trend.samples > 5) { // Only show trends with enough data
          const direction = trend.trend > 0.1 ? '📈 Slower' : trend.trend < -0.1 ? '📉 Faster' : '➡️ Stable';
          trends.push(`${hook}: ${direction} (${Math.round(trend.avgDuration)}ms avg)`);
        }
      }

      return trends.length > 0 ? trends.join('\n') : 'Performance trends stable';
      
    } catch (error) {
      return 'Performance analysis unavailable';
    }
  }

  /**
   * Generate security summary
   */
  private async generateSecuritySummary(analytics: any): Promise<string> {
    const security = analytics.securityMetrics || {};
    const summary = [];

    if (security.totalViolations === 0) {
      summary.push('🛡️ No security violations detected - excellent!');
    } else {
      summary.push(`⚠️ Total security violations: ${security.totalViolations}`);
      
      const topViolations = Object.entries(security.violationsByType || {})
        .sort(([,a], [,b]) => (b as number) - (a as number))
        .slice(0, 3);
      
      if (topViolations.length > 0) {
        summary.push('Top violation types:');
        topViolations.forEach(([type, count]) => {
          summary.push(`  • ${type}: ${count}`);
        });
      }
    }

    summary.push(`🚫 Operations blocked: ${security.blockedOperations || 0}`);
    summary.push(`📁 Sensitive file accesses: ${security.sensitiveFileAccesses || 0}`);

    return summary.join('\n');
  }

  /**
   * Generate actionable next steps
   */
  private generateNextSteps(analytics: any): Promise<string> {
    const steps = [];
    
    // Based on error patterns
    const errorRate = analytics.sessionStats.blockedOperations / analytics.sessionStats.totalEvents;
    if (errorRate > 0.1) {
      steps.push('1. Review and fix common validation errors');
      steps.push('2. Consider adding pre-commit hooks to catch issues early');
    }

    // Based on security issues
    if (analytics.securityMetrics.totalViolations > 0) {
      steps.push('3. Review security best practices documentation');
      steps.push('4. Set up automated secret scanning in CI/CD');
    }

    // Based on performance
    if (analytics.sessionStats.avgHookDuration > 2000) {
      steps.push('5. Optimize slow validation processes');
      steps.push('6. Consider running non-critical checks asynchronously');
    }

    // Based on tool usage
    const toolUsage = analytics.toolUsage || {};
    const lowSuccessTools = Object.entries(toolUsage)
      .filter(([, stats]) => (stats as any).successRate < 0.8)
      .slice(0, 2);
    
    if (lowSuccessTools.length > 0) {
      steps.push(`7. Improve success rate for: ${lowSuccessTools.map(([tool]) => tool).join(', ')}`);
    }

    if (steps.length === 0) {
      steps.push('🎉 Everything looks great! Keep up the excellent work!');
    }

    return Promise.resolve(steps.join('\n'));
  }

  /**
   * Save report to file
   */
  private async saveReport(report: string, sessionId?: string): Promise<string> {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `analytics-${sessionId || 'unknown'}-${timestamp}.txt`;
    const reportDir = `${this.PROJECT_DIR}/.claude/runtime/reports`;
    const reportPath = `${reportDir}/${filename}`;

    try {
      // Ensure directory exists
      await this.executeSecurely('mkdir', ['-p', reportDir]);
      
      // Write report to file
      const escapedReport = report.replace(/'/g, "'\"'\"'");
      await this.executeSecurely('sh', ['-c', `echo '${escapedReport}' > "${reportPath}"`]);
      
      return reportPath;
      
    } catch (error) {
      console.error('Failed to save report:', error);
      return 'console-only';
    }
  }

  /**
   * Read performance history for trend analysis
   */
  private async readPerformanceHistory(): Promise<any[]> {
    try {
      const perfDir = `${this.PROJECT_DIR}/.claude/runtime/logs`;
      const result = await this.executeSecurely('find', [
        perfDir,
        '-name', 'performance-*.jsonl',
        '-mtime', '-7', // Last 7 days
        '-exec', 'cat', '{}', '+'
      ]);

      if (!result.success || !result.stdout) {
        return [];
      }

      const lines = result.stdout.trim().split('\n').filter(line => line.trim());
      const perfData = [];

      for (const line of lines) {
        try {
          perfData.push(JSON.parse(line));
        } catch {
          // Skip invalid JSON lines
        }
      }

      return perfData;
      
    } catch (error) {
      console.error('Failed to read performance history:', error);
      return [];
    }
  }

  /**
   * Calculate performance trends for each hook
   */
  private calculateHookTrends(perfData: any[]): Record<string, {
    avgDuration: number;
    trend: number;
    samples: number;
  }> {
    const hookData: Record<string, number[]> = {};
    
    // Group performance data by hook
    for (const perf of perfData) {
      if (!hookData[perf.hookName]) {
        hookData[perf.hookName] = [];
      }
      hookData[perf.hookName].push(perf.duration);
    }

    const trends: Record<string, any> = {};
    
    for (const [hookName, durations] of Object.entries(hookData)) {
      if (durations.length < 3) continue; // Need at least 3 samples
      
      const avgDuration = durations.reduce((sum, d) => sum + d, 0) / durations.length;
      
      // Simple linear trend calculation
      const n = durations.length;
      const sumX = (n * (n + 1)) / 2;
      const sumY = durations.reduce((sum, d) => sum + d, 0);
      const sumXY = durations.reduce((sum, d, i) => sum + (i + 1) * d, 0);
      const sumX2 = (n * (n + 1) * (2 * n + 1)) / 6;
      
      const trend = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
      
      trends[hookName] = {
        avgDuration,
        trend,
        samples: n
      };
    }
    
    return trends;
  }
}

// Run the CLI if called directly
if (require.main === module) {
  runSecureHook(AnalyzeSessionCLI);
}