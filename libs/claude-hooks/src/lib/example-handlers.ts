import { BaseHandler, HookInput, HandlerResult } from './types';

/**
 * Example security handler that checks for hardcoded secrets
 */
export class SecurityHandler extends BaseHandler {
  private secretPatterns = [
    /api[_-]?key.*=.*['"][^'"]+['"]/i,
    /secret.*=.*['"][^'"]+['"]/i,
    /password.*=.*['"][^'"]+['"]/i,
    /token.*=.*['"][^'"]+['"]/i,
    /auth.*=.*['"][^'"]+['"]/i
  ];

  async handle(input: HookInput): Promise<HandlerResult> {
    this.debug(`Checking tool: ${input.tool_name}`);
    
    // Only check file operations
    if (!input.tool_name || !['Write', 'Edit', 'MultiEdit'].includes(input.tool_name)) {
      this.debug(`Skipping non-file operation: ${input.tool_name}`, true);
      return this.success();
    }

    const content = input.tool_input?.content || input.tool_input?.new_string;
    if (!content) {
      this.debug('No content to check');
      return this.success();
    }

    this.debug(`Checking content length: ${content.length} chars`, true);

    // Check for hardcoded secrets
    this.debug(`Checking ${this.secretPatterns.length} secret patterns`, true);
    for (const pattern of this.secretPatterns) {
      if (pattern.test(content)) {
        this.debug(`Secret pattern matched: ${pattern.source}`);
        return this.fail(
          `Potential hardcoded secret detected in ${input.tool_input?.file_path || 'file'}. ` +
          'Please use environment variables instead.'
        );
      }
    }

    // Log sensitive file operations
    const filePath = input.tool_input?.file_path || '';
    if (this.isSensitiveFile(filePath)) {
      console.log(`🔐 Editing sensitive file: ${filePath}`);
    }

    this.debug('Security checks passed');
    return this.success();
  }

  private isSensitiveFile(filePath: string): boolean {
    const sensitivePaths = ['.env', 'secrets/', 'config/', '.ssh/'];
    return sensitivePaths.some(path => filePath.includes(path));
  }
}

/**
 * Example bash command validator
 */
export class BashHandler extends BaseHandler {
  private dangerousCommands = [
    'sudo rm -rf /',
    'rm -rf /',
    'chmod -R 777 /',
    'chown -R root /',
    'dd if=/dev/zero',
  ];

  private requireConfirmationPatterns = [
    /rm\s+-rf\s+/,
    /sudo\s+/,
    /chmod\s+777/,
    /truncate\s+/,
    /drop\s+database/i,
    /delete\s+from.*where/i
  ];

  async handle(input: HookInput): Promise<HandlerResult> {
    this.debug(`Processing bash command`);
    
    const command = input.tool_input?.command;
    if (!command) {
      this.debug('No command provided');
      return this.success();
    }

    this.debug(`Command: ${command}`, true);

    // Block extremely dangerous commands
    this.debug(`Checking ${this.dangerousCommands.length} dangerous command patterns`, true);
    for (const dangerousCmd of this.dangerousCommands) {
      if (command.includes(dangerousCmd)) {
        this.debug(`Blocked dangerous command: ${dangerousCmd}`);
        return this.fail(
          `🚫 Blocked dangerous command: "${dangerousCmd}". This could damage your system.`
        );
      }
    }

    // Warn about potentially risky commands
    this.debug(`Checking ${this.requireConfirmationPatterns.length} risky command patterns`, true);
    for (const pattern of this.requireConfirmationPatterns) {
      if (pattern.test(command)) {
        this.debug(`Risky pattern matched: ${pattern.source}`);
        console.warn(`⚠️ Potentially destructive command: ${command}`);
        console.warn('Please double-check this command before proceeding.');
        break;
      }
    }

    // Log all commands for audit trail
    console.log(`🔧 Executing: ${command}`);
    this.debug('Bash command validation passed');

    return this.success();
  }
}