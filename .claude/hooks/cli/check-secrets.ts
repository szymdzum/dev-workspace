/**
 * Security check CLI for Claude Code hooks
 * Scans code for hardcoded secrets and security violations
 */

import { SecureHookBase, HookLogger, runSecureHook, HookResult } from '@claude-dev/hooks';

class CheckSecretsCLI extends SecureHookBase {
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
      const content = this.getContentFromInput(tool_input);
      const filePath = this.getFilePathFromInput(tool_input) || undefined;

      // Skip if no content to check
      if (!content) {
        await this.logger.logEvent({
          hookName: 'check-secrets',
          toolName: tool_name || 'unknown',
          duration: Date.now() - startTime,
          result: 'allow',
          filePath,
          metadata: { reason: 'no_content_to_check' }
        });
        
        return this.allow('No content to check');
      }

      // Sanitize file path if provided
      let safePath: string | undefined;
      if (filePath) {
        try {
          safePath = this.sanitizePath(filePath);
          
          // Check if it's a sensitive file we should skip
          if (this.isSensitivePath(safePath)) {
            await this.logger.logSecurity({
              type: 'sensitive_file_access',
              severity: 'medium',
              message: 'Sensitive file access skipped',
              details: [`File: ${safePath}`],
              filePath: safePath,
              blocked: false
            });
            
            return this.allow('Sensitive file skipped for security');
          }
        } catch (error) {
          // Path traversal or other path security issue
          await this.logger.logSecurity({
            type: 'path_traversal',
            severity: 'high',
            message: 'Path security violation',
            details: [error instanceof Error ? error.message : 'Unknown path error'],
            filePath,
            blocked: true
          });
          
          return this.deny('Path security violation detected');
        }
      }

      // Scan for hardcoded secrets
      const violations = this.scanForSecrets(content);
      
      if (violations.length > 0) {
        // Log security violation
        await this.logger.logSecurity({
          type: 'hardcoded_secret',
          severity: 'critical',
          message: 'Hardcoded secrets detected in code',
          details: violations.map(v => `${v.type}: ${v.message}`),
          filePath: safePath,
          blocked: true
        });

        // Log event
        await this.logger.logEvent({
          hookName: 'check-secrets',
          toolName: tool_name || 'unknown',
          duration: Date.now() - startTime,
          result: 'deny',
          filePath: safePath,
          errors: violations.map(v => v.message),
          metadata: {
            violationCount: violations.length,
            violationTypes: violations.map(v => v.type)
          }
        });

        return this.deny(
          'Hardcoded secrets detected in code. Please use environment variables or secure configuration instead.',
          violations.map(v => `${v.type}: ${v.message}`)
        );
      }

      // Check for other security issues
      const otherViolations = this.checkForSecurityIssues(content);
      
      if (otherViolations.length > 0) {
        for (const violation of otherViolations) {
          await this.logger.logSecurity({
            type: violation.type as any,
            severity: violation.severity,
            message: violation.message,
            details: violation.details,
            filePath: safePath,
            blocked: violation.severity === 'critical'
          });
        }

        const criticalViolations = otherViolations.filter(v => v.severity === 'critical');
        if (criticalViolations.length > 0) {
          await this.logger.logEvent({
            hookName: 'check-secrets',
            toolName: tool_name || 'unknown',
            duration: Date.now() - startTime,
            result: 'deny',
            filePath: safePath,
            errors: criticalViolations.map(v => v.message)
          });

          return this.deny(
            'Critical security violations detected',
            criticalViolations.map(v => v.message)
          );
        }
      }

      // All checks passed
      await this.logger.logEvent({
        hookName: 'check-secrets',
        toolName: tool_name || 'unknown',
        duration: Date.now() - startTime,
        result: 'allow',
        filePath: safePath,
        metadata: {
          checksPerformed: ['secrets', 'security_patterns'],
          violationsFound: otherViolations.length
        }
      });

      return this.allow();

    } catch (error) {
      await this.logger.logError(error as Error, {
        hookName: 'check-secrets',
        toolName: 'unknown',
        duration: Date.now() - startTime
      });

      return this.deny('Security check failed: ' + (error instanceof Error ? error.message : 'Unknown error'));
    }
  }

  /**
   * Extract content from various tool input formats
   */
  private getContentFromInput(toolInput: any): string | null {
    if (!toolInput) return null;
    
    // Write tool
    if (toolInput.content) return toolInput.content;
    
    // Edit tool
    if (toolInput.new_string) return toolInput.new_string;
    if (toolInput.old_string) return toolInput.old_string;
    
    // MultiEdit tool
    if (toolInput.edits && Array.isArray(toolInput.edits)) {
      return toolInput.edits.map((edit: any) => edit.new_string || edit.old_string || '').join('\n');
    }
    
    return null;
  }

  /**
   * Extract file path from various tool input formats
   */
  private getFilePathFromInput(toolInput: any): string | null {
    if (!toolInput) return null;
    
    return toolInput.file_path || toolInput.notebook_path || null;
  }

  /**
   * Check for other security issues beyond secrets
   */
  private checkForSecurityIssues(content: string): Array<{
    type: string;
    severity: 'low' | 'medium' | 'high' | 'critical';
    message: string;
    details: string[];
  }> {
    const violations = [];

    // Check for eval() usage
    if (/\beval\s*\(/gi.test(content)) {
      violations.push({
        type: 'dangerous_eval',
        severity: 'high' as const,
        message: 'Use of eval() detected - security risk',
        details: ['eval() can execute arbitrary code and poses security risks']
      });
    }

    // Check for process.env in non-config files
    const envMatches = content.match(/process\.env\.(\w+)/gi);
    if (envMatches && envMatches.length > 5) {
      violations.push({
        type: 'excessive_env_usage',
        severity: 'medium' as const,
        message: 'Excessive process.env usage detected',
        details: [`Found ${envMatches.length} environment variable references`]
      });
    }

    // Check for SQL injection patterns
    const sqlPatterns = [
      /\$\{[^}]*\}\s*INTO\s+/gi,
      /['"].*\+.*['"].*WHERE/gi,
      /query\s*\+=\s*['"].*['"].*WHERE/gi
    ];

    for (const pattern of sqlPatterns) {
      if (pattern.test(content)) {
        violations.push({
          type: 'potential_sql_injection',
          severity: 'high' as const,
          message: 'Potential SQL injection vulnerability',
          details: ['Use parameterized queries instead of string concatenation']
        });
        break;
      }
    }

    // Check for hardcoded URLs with credentials
    if (/https?:\/\/[^\/\s"']*:[^\/\s"']*@/gi.test(content)) {
      violations.push({
        type: 'url_with_credentials',
        severity: 'critical' as const,
        message: 'URL with embedded credentials detected',
        details: ['Remove credentials from URLs and use secure authentication']
      });
    }

    // Check for commented-out credentials
    const commentedSecrets = [
      /\/\/.*(?:password|secret|key|token)\s*[:=]/gi,
      /#.*(?:password|secret|key|token)\s*[:=]/gi,
      /\/\*.*(?:password|secret|key|token)\s*[:=].*\*\//gi
    ];

    for (const pattern of commentedSecrets) {
      if (pattern.test(content)) {
        violations.push({
          type: 'commented_credentials',
          severity: 'medium' as const,
          message: 'Commented-out credentials detected',
          details: ['Remove commented credentials from code']
        });
        break;
      }
    }

    return violations;
  }
}

// Run the CLI if called directly
if (require.main === module) {
  runSecureHook(CheckSecretsCLI);
}