/**
 * Security Handler - Keep secrets out of your code
 * 
 * Prevents hardcoded secrets, API keys, and other sensitive data
 * from being written to files.
 */

import { TypedHandler } from './base';
import { PreToolUseInput } from '../types/claude-code';
import { PreToolUseResponse } from '../types/responses';
import { isToolUse } from '../types/helpers';

/**
 * Configuration for security handler
 */
export interface SecurityConfig {
  /** Patterns to detect secrets */
  secretPatterns: RegExp[];
  
  /** Additional custom patterns */
  customPatterns: RegExp[];
  
  /** Paths considered sensitive */
  sensitivePaths: string[];
  
  /** Whether to block or just warn */
  blockOnSecrets: boolean;
}

/**
 * Security handler that prevents secrets from being written
 */
export class SecurityHandler extends TypedHandler<'PreToolUse'> {
  readonly event = 'PreToolUse' as const;
  private securityConfig: SecurityConfig;
  
  constructor(config: Partial<SecurityConfig> = {}) {
    super();
    
    this.securityConfig = {
      secretPatterns: [
        /api[_-]?key.*=.*['"][^'"]+['"]/i,
        /secret.*=.*['"][^'"]+['"]/i,
        /password.*=.*['"][^'"]+['"]/i,
        /token.*=.*['"][^'"]+['"]/i,
        /auth.*=.*['"][^'"]+['"]/i,
        // Common secret formats
        /sk-[a-zA-Z0-9]{40,}/i, // OpenAI API keys
        /ghp_[a-zA-Z0-9]{36}/i, // GitHub personal access tokens
        /[a-zA-Z0-9_-]{32,}/i, // Generic long strings (be careful with this)
      ],
      customPatterns: [],
      sensitivePaths: ['.env', 'secrets/', 'config/', '.ssh/', 'credentials'],
      blockOnSecrets: true,
      ...config
    };
  }
  
  async handle(input: PreToolUseInput): Promise<PreToolUseResponse> {
    this.debug(`Checking tool: ${input.tool_name}`);
    
    // Only check file operations that write content
    if (!this.isFileWriteOperation(input)) {
      this.debug(`Skipping non-write operation: ${input.tool_name}`, true);
      return this.success();
    }
    
    // Extract content to check
    const content = this.getContentToCheck(input);
    if (!content) {
      this.debug('No content to check');
      return this.success();
    }
    
    this.debug(`Checking content length: ${content.length} chars`, true);
    
    // Check for secrets
    const secretMatch = this.findSecrets(content);
    if (secretMatch) {
      const filePath = this.getFilePath(input);
      const message = `Potential hardcoded secret detected in ${filePath || 'file'}: ${secretMatch.type}`;
      
      this.debug(`Secret detected: ${secretMatch.pattern.source}`);
      
      if (this.securityConfig.blockOnSecrets) {
        return {
          hookSpecificOutput: {
            hookEventName: 'PreToolUse',
            permissionDecision: 'deny',
            permissionDecisionReason: `${message}. Please use environment variables instead.`
          }
        };
      } else {
        console.warn(`⚠️ ${message}`);
        return {
          hookSpecificOutput: {
            hookEventName: 'PreToolUse',
            permissionDecision: 'ask',
            permissionDecisionReason: `${message}. Are you sure you want to proceed?`
          }
        };
      }
    }
    
    // Check for sensitive file operations
    const filePath = this.getFilePath(input);
    if (filePath && this.isSensitiveFile(filePath)) {
      console.log(`🔐 Editing sensitive file: ${filePath}`);
      return {
        systemMessage: `🔐 Modifying sensitive file: ${filePath}`,
        continue: true
      };
    }
    
    this.debug('Security checks passed');
    return this.success();
  }
  
  /**
   * Check if this is a file write operation
   */
  private isFileWriteOperation(input: PreToolUseInput): boolean {
    return ['Write', 'Edit', 'MultiEdit'].includes(input.tool_name);
  }
  
  /**
   * Extract content that needs to be checked
   */
  private getContentToCheck(input: PreToolUseInput): string | null {
    if (isToolUse(input, 'Write')) {
      return input.tool_input.content;
    }
    
    if (isToolUse(input, 'Edit')) {
      return input.tool_input.new_text;
    }
    
    if (isToolUse(input, 'MultiEdit')) {
      return input.tool_input.edits
        .map(edit => edit.new_text)
        .join('\n');
    }
    
    return null;
  }
  
  /**
   * Get file path from tool input
   */
  private getFilePath(input: PreToolUseInput): string | null {
    const toolInput = input.tool_input as any;
    return toolInput?.file_path || null;
  }
  
  /**
   * Find secrets in content
   */
  private findSecrets(content: string): { type: string; pattern: RegExp } | null {
    const allPatterns = [
      ...this.securityConfig.secretPatterns.map(p => ({ pattern: p, type: 'Built-in secret pattern' })),
      ...this.securityConfig.customPatterns.map(p => ({ pattern: p, type: 'Custom secret pattern' }))
    ];
    
    for (const { pattern, type } of allPatterns) {
      if (pattern.test(content)) {
        return { type, pattern };
      }
    }
    
    return null;
  }
  
  /**
   * Check if file path is sensitive
   */
  private isSensitiveFile(filePath: string): boolean {
    return this.securityConfig.sensitivePaths.some(path => 
      filePath.includes(path)
    );
  }
}

/**
 * Builder for security handler configuration
 */
export class SecurityHandlerBuilder {
  private config: Partial<SecurityConfig> = {};
  
  /**
   * Add custom secret patterns
   */
  addPatterns(patterns: RegExp[]): this {
    this.config.customPatterns = [
      ...(this.config.customPatterns || []),
      ...patterns
    ];
    return this;
  }
  
  /**
   * Add sensitive paths
   */
  addSensitivePaths(paths: string[]): this {
    this.config.sensitivePaths = [
      ...(this.config.sensitivePaths || []),
      ...paths
    ];
    return this;
  }
  
  /**
   * Set whether to block or ask on secrets
   */
  blockSecrets(block = true): this {
    this.config.blockOnSecrets = block;
    return this;
  }
  
  /**
   * Build the handler
   */
  build(): SecurityHandler {
    return new SecurityHandler(this.config);
  }
}

/**
 * Factory for common security configurations
 */
export const Security = {
  /**
   * Standard security checks
   */
  standard(): SecurityHandler {
    return new SecurityHandler();
  },
  
  /**
   * Strict security (blocks on any secret)
   */
  strict(): SecurityHandler {
    return new SecurityHandlerBuilder()
      .blockSecrets(true)
      .build();
  },
  
  /**
   * Permissive security (asks user)
   */
  permissive(): SecurityHandler {
    return new SecurityHandlerBuilder()
      .blockSecrets(false)
      .build();
  },
  
  /**
   * Custom builder
   */
  custom(): SecurityHandlerBuilder {
    return new SecurityHandlerBuilder();
  }
};