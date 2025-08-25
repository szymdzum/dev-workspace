/**
 * Validation Handler - Nx-powered quality control
 * 
 * Runs lint and type checks on affected projects only.
 * Prevents bad code from entering the codebase.
 */

import { execSync } from 'child_process';
import { TypedHandler } from './base';
import { PostToolUseInput, ToolName } from '../types/claude-code';
import { PostToolUseResponse } from '../types/responses';

/**
 * Configuration for validation handler
 */
export interface ValidationConfig {
  /** Targets to run (e.g., ['lint', 'build', 'test']) */
  targets: string[];
  
  /** Only validate affected projects (recommended) */
  affectedOnly: boolean;
  
  /** Stop on first error */
  bail: boolean;
  
  /** Tools that trigger validation */
  triggerTools: ToolName[];
  
  /** File extensions that trigger validation */
  triggerExtensions: string[];
  
  /** Minimum number of changed files to trigger batch validation */
  batchThreshold: number;
}

/**
 * Validation handler that runs Nx commands on affected code
 */
export class ValidationHandler extends TypedHandler<'PostToolUse'> {
  readonly event = 'PostToolUse' as const;
  private changedFiles = new Set<string>();
  private validationConfig: ValidationConfig;
  
  constructor(config: Partial<ValidationConfig> = {}) {
    super();
    
    this.validationConfig = {
      targets: ['lint', 'build'],
      affectedOnly: true,
      bail: true,
      triggerTools: ['Write', 'Edit', 'MultiEdit'],
      triggerExtensions: ['.ts', '.tsx', '.js', '.jsx', '.json'],
      batchThreshold: 1,
      ...config
    };
  }
  
  async handle(input: PostToolUseInput): Promise<PostToolUseResponse> {
    this.debug(`Processing tool: ${input.tool_name}`);
    
    // Only validate file modification tools
    if (!this.validationConfig.triggerTools.includes(input.tool_name)) {
      this.debug(`Skipping non-file tool: ${input.tool_name}`, true);
      return this.success();
    }
    
    // Track changed files
    const filePath = this.getFilePath(input);
    if (filePath && this.shouldValidateFile(filePath)) {
      this.changedFiles.add(filePath);
      this.debug(`Added file to validation queue: ${filePath}`, true);
    }
    
    // Run validation if we have enough changes
    if (this.changedFiles.size >= this.validationConfig.batchThreshold) {
      return await this.runValidation();
    }
    
    return this.success();
  }
  
  /**
   * Extract file path from tool input
   */
  private getFilePath(input: PostToolUseInput): string | null {
    const toolInput = input.tool_input as any;
    return toolInput?.file_path || null;
  }
  
  /**
   * Check if file should trigger validation
   */
  private shouldValidateFile(filePath: string): boolean {
    // Skip node_modules and generated files
    if (filePath.includes('node_modules') || 
        filePath.includes('.generated.') ||
        filePath.includes('dist/')) {
      return false;
    }
    
    // Check extension
    return this.validationConfig.triggerExtensions.some(ext => 
      filePath.endsWith(ext)
    );
  }
  
  /**
   * Run validation on changed files
   */
  private async runValidation(): Promise<PostToolUseResponse> {
    if (this.changedFiles.size === 0) {
      return this.success();
    }
    
    const files = Array.from(this.changedFiles);
    this.debug(`Running validation on ${files.length} files`);
    
    try {
      const results: ValidationResult[] = [];
      
      for (const target of this.validationConfig.targets) {
        const result = await this.runTarget(target, files);
        results.push(result);
        
        if (!result.success && this.validationConfig.bail) {
          break;
        }
      }
      
      // Check for failures
      const failed = results.find(r => !r.success);
      if (failed) {
        this.debug(`Validation failed: ${failed.error}`);
        return {
          decision: 'block',
          reason: `${failed.target} failed: ${failed.error}`,
          hookSpecificOutput: {
            hookEventName: 'PostToolUse',
            additionalContext: `Validation failure in ${failed.target}:\n${failed.error}`
          }
        };
      }
      
      // Success - clear the queue
      this.changedFiles.clear();
      const successMsg = `✅ Validation passed (${this.validationConfig.targets.join(', ')})`;
      this.debug(successMsg);
      
      return {
        continue: true,
        systemMessage: successMsg
      };
      
    } catch (error: any) {
      const errorMsg = `Validation error: ${error.message}`;
      this.debug(errorMsg);
      
      return {
        decision: 'block',
        reason: errorMsg
      };
    }
  }
  
  /**
   * Run a specific target (lint, build, etc.)
   */
  private async runTarget(target: string, files: string[]): Promise<ValidationResult> {
    try {
      let command: string;
      
      if (this.validationConfig.affectedOnly) {
        const fileList = files.join(',');
        command = `nx affected -t ${target} --files="${fileList}"`;
        
        if (this.validationConfig.bail) {
          command += ' --nxBail';
        }
      } else {
        command = `nx run-many -t ${target}`;
      }
      
      this.debug(`Executing: ${command}`, true);
      
      const output = execSync(command, {
        encoding: 'utf-8',
        stdio: 'pipe',
        timeout: 120000 // 2 minutes max
      });
      
      return {
        success: true,
        target,
        output
      };
      
    } catch (error: any) {
      return {
        success: false,
        target,
        error: error.message,
        output: error.stdout || error.stderr || error.message
      };
    }
  }
}

/**
 * Result of running a validation target
 */
interface ValidationResult {
  success: boolean;
  target: string;
  error?: string;
  output?: string;
}

/**
 * Utility to create a validation handler with common configurations
 */
export class ValidationHandlerBuilder {
  private config: Partial<ValidationConfig> = {};
  
  /**
   * Set targets to run
   */
  targets(targets: string[]): this {
    this.config.targets = targets;
    return this;
  }
  
  /**
   * Enable/disable affected-only mode
   */
  affectedOnly(enabled = true): this {
    this.config.affectedOnly = enabled;
    return this;
  }
  
  /**
   * Set tools that trigger validation
   */
  onTools(tools: ToolName[]): this {
    this.config.triggerTools = tools;
    return this;
  }
  
  /**
   * Set file extensions that trigger validation
   */
  onExtensions(extensions: string[]): this {
    this.config.triggerExtensions = extensions;
    return this;
  }
  
  /**
   * Set batch threshold
   */
  batchSize(size: number): this {
    this.config.batchThreshold = size;
    return this;
  }
  
  /**
   * Build the handler
   */
  build(): ValidationHandler {
    return new ValidationHandler(this.config);
  }
}

/**
 * Quick factory for common validation setups
 */
export const Validation = {
  /**
   * Basic lint + build validation
   */
  basic(): ValidationHandler {
    return new ValidationHandlerBuilder()
      .targets(['lint', 'build'])
      .affectedOnly(true)
      .build();
  },
  
  /**
   * Full validation including tests
   */
  full(): ValidationHandler {
    return new ValidationHandlerBuilder()
      .targets(['lint', 'build', 'test'])
      .affectedOnly(true)
      .build();
  },
  
  /**
   * Lint only (fast)
   */
  lintOnly(): ValidationHandler {
    return new ValidationHandlerBuilder()
      .targets(['lint'])
      .affectedOnly(true)
      .build();
  },
  
  /**
   * Custom builder
   */
  custom(): ValidationHandlerBuilder {
    return new ValidationHandlerBuilder();
  }
};