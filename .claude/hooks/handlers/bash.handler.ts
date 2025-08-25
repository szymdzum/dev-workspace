import { BaseHandler, HookInput, HandlerResult } from '../types';

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
    const command = input.tool_input?.command;
    if (!command) {
      return this.success();
    }

    // Block extremely dangerous commands
    for (const dangerousCmd of this.dangerousCommands) {
      if (command.includes(dangerousCmd)) {
        return this.fail(
          `🚫 Blocked dangerous command: "${dangerousCmd}". This could damage your system.`
        );
      }
    }

    // Warn about potentially risky commands
    for (const pattern of this.requireConfirmationPatterns) {
      if (pattern.test(command)) {
        console.warn(`⚠️ Potentially destructive command: ${command}`);
        console.warn('Please double-check this command before proceeding.');
        break;
      }
    }

    // Log all commands for audit trail
    console.log(`🔧 Executing: ${command}`);

    return this.success();
  }
}