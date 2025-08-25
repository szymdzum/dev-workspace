/**
 * Code validation CLI for Claude Code hooks
 * Runs linting, type checking, and other code quality checks
 */

import { SecureHookBase, HookLogger, runSecureHook, HookResult } from '@claude-dev/hooks';
import { extname } from 'path';

class ValidateCLI extends SecureHookBase {
  private logger: HookLogger;

  // File extensions that should trigger validation
  private readonly VALIDATION_EXTENSIONS = [
    '.ts', '.tsx', '.js', '.jsx', '.vue', '.svelte',
    '.json', '.md', '.yaml', '.yml'
  ];

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
      const filePath = this.getFilePathFromInput(tool_input);

      // Skip if no file path
      if (!filePath) {
        await this.logger.logEvent({
          hookName: 'validate',
          toolName: tool_name || 'unknown',
          duration: Date.now() - startTime,
          result: 'allow',
          metadata: { reason: 'no_file_path' }
        });
        
        return this.allow('No file path to validate');
      }

      // Sanitize file path
      let safePath: string;
      try {
        safePath = this.sanitizePath(filePath);
      } catch (error) {
        await this.logger.logSecurity({
          type: 'path_traversal',
          severity: 'high',
          message: 'Path validation failed',
          details: [error instanceof Error ? error.message : 'Unknown path error'],
          filePath,
          blocked: true
        });
        
        return this.deny('Invalid file path');
      }

      // Check if file should be validated
      const fileExtension = extname(safePath).toLowerCase();
      if (!this.shouldValidateFile(safePath, fileExtension)) {
        await this.logger.logEvent({
          hookName: 'validate',
          toolName: tool_name || 'unknown',
          duration: Date.now() - startTime,
          result: 'allow',
          filePath: safePath,
          fileExtension,
          metadata: { reason: 'file_type_skipped' }
        });
        
        return this.allow(`File type ${fileExtension} skipped`);
      }

      // Skip sensitive files
      if (this.isSensitivePath(safePath)) {
        await this.logger.logSecurity({
          type: 'sensitive_file_access',
          severity: 'low',
          message: 'Sensitive file validation skipped',
          details: [`File: ${safePath}`],
          filePath: safePath,
          blocked: false
        });
        
        return this.allow('Sensitive file skipped');
      }

      // Run validation checks
      const validationResults = await this.runValidationChecks(safePath, fileExtension);
      
      // Check if any validations failed
      const failures = validationResults.filter(result => !result.success);
      
      if (failures.length > 0) {
        const allErrors = failures.flatMap(f => f.errors || []);
        
        await this.logger.logEvent({
          hookName: 'validate',
          toolName: tool_name || 'unknown',
          duration: Date.now() - startTime,
          result: 'deny',
          filePath: safePath,
          fileExtension,
          errors: allErrors,
          metadata: {
            failedChecks: failures.map(f => f.type),
            totalChecks: validationResults.length
          }
        });

        return this.deny(
          `Code validation failed: ${failures.map(f => f.type).join(', ')}`,
          allErrors
        );
      }

      // All validations passed
      await this.logger.logEvent({
        hookName: 'validate',
        toolName: tool_name || 'unknown',
        duration: Date.now() - startTime,
        result: 'allow',
        filePath: safePath,
        fileExtension,
        metadata: {
          checksRun: validationResults.map(r => r.type),
          totalChecks: validationResults.length
        }
      });

      return this.allow();

    } catch (error) {
      await this.logger.logError(error as Error, {
        hookName: 'validate',
        toolName: input?.tool_name,
        duration: Date.now() - startTime
      });

      return this.deny('Validation failed: ' + (error instanceof Error ? error.message : 'Unknown error'));
    }
  }

  /**
   * Extract file path from tool input
   */
  private getFilePathFromInput(toolInput: any): string | null {
    if (!toolInput) return null;
    return toolInput.file_path || toolInput.notebook_path || null;
  }

  /**
   * Check if file should be validated based on extension and path
   */
  private shouldValidateFile(filePath: string, extension: string): boolean {
    // Skip test files for now (they have their own validation)
    if (filePath.includes('__tests__') || filePath.includes('.test.') || filePath.includes('.spec.')) {
      return false;
    }

    // Check extension whitelist
    return this.VALIDATION_EXTENSIONS.includes(extension);
  }

  /**
   * Run all relevant validation checks for the file
   */
  private async runValidationChecks(filePath: string, extension: string): Promise<Array<{
    type: string;
    success: boolean;
    stdout?: string;
    stderr?: string;
    errors?: string[];
  }>> {
    const results = [];

    // Run ESLint for JavaScript/TypeScript files
    if (['.js', '.jsx', '.ts', '.tsx', '.vue', '.svelte'].includes(extension)) {
      results.push(await this.runLintCheck(filePath));
    }

    // Run TypeScript checking for TypeScript files
    if (['.ts', '.tsx'].includes(extension)) {
      results.push(await this.runTypeCheck(filePath));
    }

    // Run JSON validation for JSON files
    if (extension === '.json') {
      results.push(await this.runJsonValidation(filePath));
    }

    // Run Markdown validation for Markdown files
    if (extension === '.md') {
      results.push(await this.runMarkdownValidation(filePath));
    }

    return results;
  }

  /**
   * Run ESLint validation
   */
  private async runLintCheck(filePath: string): Promise<{
    type: string;
    success: boolean;
    stdout?: string;
    stderr?: string;
    errors?: string[];
  }> {
    try {
      // Use nx affected if available, otherwise fall back to direct eslint
      const nxResult = await this.executeSecurely('nx', [
        'affected',
        '-t', 'lint',
        '--files', filePath
      ], { timeout: 30000 });

      if (nxResult.success) {
        return {
          type: 'lint',
          success: true,
          stdout: nxResult.stdout
        };
      }

      // If nx failed, try direct eslint
      const eslintResult = await this.executeSecurely('npx', [
        'eslint',
        filePath,
        '--format', 'compact'
      ], { timeout: 15000 });

      return {
        type: 'lint',
        success: eslintResult.success,
        stdout: eslintResult.stdout,
        stderr: eslintResult.stderr,
        errors: eslintResult.success ? undefined : [eslintResult.stderr || 'Linting failed']
      };

    } catch (error) {
      return {
        type: 'lint',
        success: false,
        errors: [error instanceof Error ? error.message : 'Lint check failed']
      };
    }
  }

  /**
   * Run TypeScript type checking
   */
  private async runTypeCheck(filePath: string): Promise<{
    type: string;
    success: boolean;
    stdout?: string;
    stderr?: string;
    errors?: string[];
  }> {
    try {
      // Try nx affected first
      const nxResult = await this.executeSecurely('nx', [
        'affected',
        '-t', 'typecheck'
      ], { timeout: 60000 });

      if (nxResult.success) {
        return {
          type: 'typecheck',
          success: true,
          stdout: nxResult.stdout
        };
      }

      // Fall back to direct TypeScript checking
      const tscResult = await this.executeSecurely('npx', [
        'tsc',
        '--noEmit',
        '--skipLibCheck',
        filePath
      ], { timeout: 30000 });

      return {
        type: 'typecheck',
        success: tscResult.success,
        stdout: tscResult.stdout,
        stderr: tscResult.stderr,
        errors: tscResult.success ? undefined : [tscResult.stderr || 'Type check failed']
      };

    } catch (error) {
      return {
        type: 'typecheck',
        success: false,
        errors: [error instanceof Error ? error.message : 'Type check failed']
      };
    }
  }

  /**
   * Validate JSON files
   */
  private async runJsonValidation(filePath: string): Promise<{
    type: string;
    success: boolean;
    errors?: string[];
  }> {
    try {
      // Use node to validate JSON
      const result = await this.executeSecurely('node', [
        '-e',
        `try { JSON.parse(require('fs').readFileSync('${filePath}', 'utf8')); console.log('Valid JSON'); } catch(e) { console.error(e.message); process.exit(1); }`
      ], { timeout: 5000 });

      return {
        type: 'json',
        success: result.success,
        errors: result.success ? undefined : [result.stderr || 'Invalid JSON']
      };

    } catch (error) {
      return {
        type: 'json',
        success: false,
        errors: [error instanceof Error ? error.message : 'JSON validation failed']
      };
    }
  }

  /**
   * Basic Markdown validation
   */
  private async runMarkdownValidation(filePath: string): Promise<{
    type: string;
    success: boolean;
    errors?: string[];
  }> {
    try {
      // Basic checks - could be enhanced with markdownlint
      const result = await this.executeSecurely('node', [
        '-e',
        `
        const fs = require('fs');
        const content = fs.readFileSync('${filePath}', 'utf8');
        
        // Basic validation
        if (content.trim().length === 0) {
          console.error('Empty markdown file');
          process.exit(1);
        }
        
        // Check for common issues
        const lines = content.split('\\n');
        const issues = [];
        
        lines.forEach((line, i) => {
          // Check for trailing whitespace
          if (line.match(/\\s+$/)) {
            issues.push(\`Line \${i + 1}: Trailing whitespace\`);
          }
        });
        
        if (issues.length > 0) {
          console.error(issues.join('\\n'));
          process.exit(1);
        }
        
        console.log('Valid markdown');
        `
      ], { timeout: 5000 });

      return {
        type: 'markdown',
        success: result.success,
        errors: result.success ? undefined : result.stderr.split('\n').filter(line => line.trim())
      };

    } catch (error) {
      return {
        type: 'markdown',
        success: false,
        errors: [error instanceof Error ? error.message : 'Markdown validation failed']
      };
    }
  }
}

// Run the CLI if called directly
if (require.main === module) {
  runSecureHook(ValidateCLI);
}