import { BaseHandler, HookInput, HandlerResult } from '../types';

export class SecurityHandler extends BaseHandler {
  private secretPatterns = [
    /api[_-]?key.*=.*['"][^'"]+['"]/i,
    /secret.*=.*['"][^'"]+['"]/i,
    /password.*=.*['"][^'"]+['"]/i,
    /token.*=.*['"][^'"]+['"]/i,
    /auth.*=.*['"][^'"]+['"]/i
  ];

  async handle(input: HookInput): Promise<HandlerResult> {
    // Only check file operations
    if (!input.tool_name || !['Write', 'Edit', 'MultiEdit'].includes(input.tool_name)) {
      return this.success();
    }

    const content = input.tool_input?.content || input.tool_input?.new_string;
    if (!content) {
      return this.success();
    }

    // Check for hardcoded secrets
    for (const pattern of this.secretPatterns) {
      if (pattern.test(content)) {
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

    return this.success();
  }

  private isSensitiveFile(filePath: string): boolean {
    const sensitivePaths = ['.env', 'secrets/', 'config/', '.ssh/'];
    return sensitivePaths.some(path => filePath.includes(path));
  }
}