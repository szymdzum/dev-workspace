/**
 * Secure base class for Claude Code hooks
 * Implements security best practices and input sanitization
 */

import { spawn } from 'child_process';
import { readFileSync } from 'fs';
import { resolve, normalize, relative } from 'path';
import { stdin } from 'process';

export interface HookInput {
  session_id?: string;
  cwd?: string;
  tool_name?: string;
  tool_input?: Record<string, any>;
  hook_event_name?: string;
  [key: string]: any;
}

export interface HookResult {
  continue?: boolean;
  hookSpecificOutput?: {
    permissionDecision?: 'allow' | 'deny';
    permissionDecisionReason?: string;
    [key: string]: any;
  };
}

export interface SecurityViolation {
  type: string;
  message: string;
  details: string[];
  severity: 'low' | 'medium' | 'high' | 'critical';
}

/**
 * Secure base class for all hook implementations
 * Provides input validation, sanitization, and safe command execution
 */
export abstract class SecureHookBase {
  protected readonly PROJECT_DIR: string;
  protected readonly SENSITIVE_PATTERNS = [
    /\.env$/i,
    /\.git\//i,
    /\.(key|pem|p12|jks)$/i,
    /secret/i,
    /password/i,
    /token/i,
    /credential/i,
    /node_modules\//i,
    /\.ssh\//i,
    /id_rsa/i,
    /\.aws\//i
  ];

  protected readonly SECRET_PATTERNS = [
    // API Keys
    /(?:api[_-]?key|secret[_-]?key|access[_-]?key)\s*[:=]\s*["'][\w\-\.]{20,}/gi,
    
    // OpenAI
    /sk-[a-zA-Z0-9]{48}/g,
    
    // GitHub tokens
    /ghp_[a-zA-Z0-9]{36}/g,
    /gho_[a-zA-Z0-9]{36}/g,
    /ghu_[a-zA-Z0-9]{36}/g,
    /ghs_[a-zA-Z0-9]{36}/g,
    /ghr_[a-zA-Z0-9]{36}/g,
    
    // AWS
    /AKIA[0-9A-Z]{16}/g,
    /(?:aws_access_key_id|aws_secret_access_key)\s*[:=]\s*["'][\w\/\+]{20,}/gi,
    
    // JWT tokens (basic pattern)
    /eyJ[A-Za-z0-9_-]*\.eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*/g,
    
    // Generic passwords
    /(?:password|passwd|pwd)\s*[:=]\s*["'][^"']{8,}/gi,
    
    // Database connection strings
    /(?:mongodb|mysql|postgres|redis):\/\/[^\/\s"']+:[^\/\s"']+@/gi,
    
    // Private keys
    /-----BEGIN[A-Z ]+PRIVATE KEY-----/gi,
    
    // Credit card numbers (basic pattern)
    /\b(?:\d[ -]*?){13,19}\b/g,
    
    // Social security numbers
    /\b\d{3}-?\d{2}-?\d{4}\b/g
  ];

  constructor() {
    this.PROJECT_DIR = process.env['CLAUDE_PROJECT_DIR'] || process.cwd();
  }

  /**
   * Read and sanitize input from stdin
   */
  protected async readAndSanitizeStdin(): Promise<HookInput> {
    const input = await this.readStdin();
    
    try {
      const parsed = JSON.parse(input);
      return this.sanitizeInput(parsed);
    } catch (error) {
      throw new Error(`Invalid JSON input: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Read from stdin with timeout
   */
  private async readStdin(timeoutMs = 5000): Promise<string> {
    return new Promise((resolve, reject) => {
      let data = '';
      const timeout = setTimeout(() => {
        reject(new Error('Stdin read timeout'));
      }, timeoutMs);

      stdin.setEncoding('utf8');
      stdin.on('data', (chunk) => {
        data += chunk;
      });

      stdin.on('end', () => {
        clearTimeout(timeout);
        resolve(data.trim());
      });

      stdin.on('error', (error) => {
        clearTimeout(timeout);
        reject(error);
      });
    });
  }

  /**
   * Sanitize and validate input object
   */
  protected sanitizeInput<T = HookInput>(input: unknown): T {
    if (!input || typeof input !== 'object') {
      throw new Error('Input must be an object');
    }

    const sanitized = { ...input } as Record<string, any>;

    // Sanitize string fields
    for (const [key, value] of Object.entries(sanitized)) {
      if (typeof value === 'string') {
        sanitized[key] = this.sanitizeString(value);
      } else if (typeof value === 'object' && value !== null) {
        sanitized[key] = this.sanitizeInput(value);
      }
    }

    return sanitized as T;
  }

  /**
   * Sanitize individual string values
   */
  private sanitizeString(str: string): string {
    // Remove null bytes and control characters (except newlines and tabs)
    return str.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '');
  }

  /**
   * Validate and sanitize file paths
   */
  protected sanitizePath(filePath: string): string {
    if (!filePath || typeof filePath !== 'string') {
      throw new Error('File path must be a non-empty string');
    }

    // Remove null bytes and control characters
    const cleanPath = this.sanitizeString(filePath);

    // Check for path traversal attempts
    if (cleanPath.includes('..')) {
      throw new Error('Path traversal detected in file path');
    }

    // Normalize the path
    const normalizedPath = normalize(cleanPath);

    // Ensure path is within project directory
    if (!normalizedPath.startsWith(this.PROJECT_DIR) && !normalizedPath.startsWith('./') && !normalizedPath.startsWith('/')) {
      // Make relative to project directory
      return resolve(this.PROJECT_DIR, normalizedPath);
    }

    return normalizedPath;
  }

  /**
   * Check if path is sensitive and should be skipped
   */
  protected isSensitivePath(filePath: string): boolean {
    const relativePath = relative(this.PROJECT_DIR, filePath);
    return this.SENSITIVE_PATTERNS.some(pattern => pattern.test(relativePath));
  }

  /**
   * Scan content for hardcoded secrets
   */
  protected scanForSecrets(content: string): SecurityViolation[] {
    const violations: SecurityViolation[] = [];

    for (const pattern of this.SECRET_PATTERNS) {
      const matches = content.match(pattern);
      if (matches) {
        violations.push({
          type: 'hardcoded_secret',
          message: 'Hardcoded secret detected',
          details: matches.map(match => `Pattern matched: ${match.substring(0, 20)}...`),
          severity: 'critical'
        });
      }
    }

    return violations;
  }

  /**
   * Execute command securely with proper quoting and validation
   */
  protected async executeSecurely(
    command: string,
    args: string[],
    options: {
      cwd?: string;
      timeout?: number;
      maxBuffer?: number;
    } = {}
  ): Promise<{ success: boolean; stdout: string; stderr: string; errors?: string[] }> {
    
    // Validate command
    if (!command || typeof command !== 'string') {
      throw new Error('Command must be a non-empty string');
    }

    // Sanitize arguments
    const sanitizedArgs = args.map(arg => this.sanitizeString(arg));

    const {
      cwd = this.PROJECT_DIR,
      timeout = 60000,
      maxBuffer = 1024 * 1024 // 1MB
    } = options;

    return new Promise((resolve) => {
      let stdout = '';
      let stderr = '';
      let timedOut = false;

      const child = spawn(command, sanitizedArgs, {
        cwd,
        stdio: ['pipe', 'pipe', 'pipe'],
        env: { ...process.env, CLAUDE_PROJECT_DIR: this.PROJECT_DIR }
      });

      const timer = setTimeout(() => {
        timedOut = true;
        child.kill('SIGTERM');
        setTimeout(() => child.kill('SIGKILL'), 5000);
      }, timeout);

      child.stdout?.on('data', (data) => {
        stdout += data.toString();
        if (stdout.length > maxBuffer) {
          child.kill('SIGTERM');
        }
      });

      child.stderr?.on('data', (data) => {
        stderr += data.toString();
        if (stderr.length > maxBuffer) {
          child.kill('SIGTERM');
        }
      });

      child.on('close', (code) => {
        clearTimeout(timer);
        
        if (timedOut) {
          resolve({
            success: false,
            stdout: '',
            stderr: 'Command timed out',
            errors: ['Command execution timed out']
          });
          return;
        }

        resolve({
          success: code === 0,
          stdout: stdout.trim(),
          stderr: stderr.trim(),
          errors: code === 0 ? undefined : [stderr.trim() || `Command exited with code ${code}`]
        });
      });

      child.on('error', (error) => {
        clearTimeout(timer);
        resolve({
          success: false,
          stdout: '',
          stderr: error.message,
          errors: [error.message]
        });
      });
    });
  }

  /**
   * Create allow result
   */
  protected allow(reason?: string): HookResult {
    return {
      continue: true,
      hookSpecificOutput: reason ? { 
        permissionDecision: 'allow',
        permissionDecisionReason: reason 
      } : undefined
    };
  }

  /**
   * Create deny result
   */
  protected deny(reason: string, details?: string[]): HookResult {
    return {
      continue: false,
      hookSpecificOutput: {
        permissionDecision: 'deny',
        permissionDecisionReason: reason,
        ...(details && { details })
      }
    };
  }

  /**
   * Abstract method that child classes must implement
   */
  abstract main(): Promise<HookResult>;
}

/**
 * CLI runner utility
 */
export async function runSecureHook(hookClass: new () => SecureHookBase): Promise<void> {
  try {
    const hook = new hookClass();
    const result = await hook.main();
    
    console.log(JSON.stringify(result, null, 2));
    process.exit(0);
  } catch (error) {
    const errorResult = {
      continue: false,
      hookSpecificOutput: {
        permissionDecision: 'deny',
        permissionDecisionReason: error instanceof Error ? error.message : 'Unknown error occurred',
        error: true
      }
    };
    
    console.log(JSON.stringify(errorResult, null, 2));
    process.exit(1);
  }
}