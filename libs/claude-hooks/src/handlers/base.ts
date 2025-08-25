/**
 * Type-safe handler base classes
 * 
 * These provide the foundation for creating handlers with full type safety
 * based on the official Claude Code hook system.
 */

import { HookEvent, HookInput } from '../types/claude-code';
import { HookResponse, ExitCode } from '../types/responses';

/**
 * Configuration for a handler
 */
export interface HandlerConfig {
  /** Whether this handler is enabled */
  enabled: boolean;
  
  /** Debug logging level */
  debug: boolean;
  
  /** Verbose logging (more detailed) */
  verbose: boolean;
}

/**
 * Type-safe handler for specific hook events
 * 
 * @example
 * class MyPreToolHandler extends TypedHandler<'PreToolUse'> {
 *   async handle(input: PreToolUseInput): Promise<PreToolUseResponse> {
 *     // Full type safety!
 *     return { continue: true };
 *   }
 * }
 */
export abstract class TypedHandler<T extends HookEvent> {
  protected config: HandlerConfig;
  
  /** The event this handler processes */
  abstract readonly event: T;
  
  constructor(config: Partial<HandlerConfig> = {}) {
    this.config = {
      enabled: true,
      debug: process.env['HOOK_DEBUG'] === '1',
      verbose: process.env['HOOK_VERBOSE'] === '1',
      ...config
    };
  }
  
  /**
   * Handle the hook input with full type safety
   */
  abstract handle(input: Extract<HookInput, { hook_event_name: T }>): Promise<HookResponse<T>>;
  
  /**
   * Check if this handler should process the given input
   */
  shouldHandle(input: HookInput): input is Extract<HookInput, { hook_event_name: T }> {
    return this.config.enabled && input.hook_event_name === this.event;
  }
  
  /**
   * Debug logging
   */
  protected debug(message: string, isVerbose = false): void {
    if (this.config.debug || (isVerbose && this.config.verbose)) {
      console.log(`🔍 [${this.constructor.name}] ${message}`);
    }
  }
  
  /**
   * Create a success response
   */
  protected success(message?: string): HookResponse<T> {
    return { 
      continue: true, 
      systemMessage: message 
    } as HookResponse<T>;
  }
  
  /**
   * Create a failure response
   */
  protected fail(message: string): HookResponse<T> {
    console.error(`❌ ${message}`);
    return { 
      continue: false, 
      stopReason: message 
    } as HookResponse<T>;
  }
  
  /**
   * Create a warning response
   */
  protected warn(message: string): HookResponse<T> {
    console.warn(`⚠️ ${message}`);
    return { 
      continue: true, 
      systemMessage: message 
    } as HookResponse<T>;
  }
}

/**
 * Generic handler that can process any hook event
 * 
 * Use this when you need to handle multiple event types
 * in a single handler class.
 */
export abstract class UniversalHandler {
  protected config: HandlerConfig;
  
  constructor(config: Partial<HandlerConfig> = {}) {
    this.config = {
      enabled: true,
      debug: process.env['HOOK_DEBUG'] === '1',
      verbose: process.env['HOOK_VERBOSE'] === '1',
      ...config
    };
  }
  
  /**
   * Handle any hook input
   */
  abstract handle(input: HookInput): Promise<HookResponse<any>>;
  
  /**
   * Check if this handler should process the given input
   */
  shouldHandle(input: HookInput): boolean {
    return this.config.enabled;
  }
  
  /**
   * Debug logging
   */
  protected debug(message: string, isVerbose = false): void {
    if (this.config.debug || (isVerbose && this.config.verbose)) {
      console.log(`🔍 [${this.constructor.name}] ${message}`);
    }
  }
  
  /**
   * Create a success response
   */
  protected success(message?: string): HookResponse<any> {
    return { continue: true, systemMessage: message };
  }
  
  /**
   * Create a failure response
   */
  protected fail(message: string): HookResponse<any> {
    console.error(`❌ ${message}`);
    return { continue: false, stopReason: message };
  }
  
  /**
   * Create a warning response
   */
  protected warn(message: string): HookResponse<any> {
    console.warn(`⚠️ ${message}`);
    return { continue: true, systemMessage: message };
  }
}

/**
 * Handler result for legacy compatibility
 * 
 * @deprecated Use the new TypedHandler with proper response types
 */
export interface HandlerResult {
  success: boolean;
  message?: string;
  shouldContinue: boolean;
}

/**
 * Legacy base handler for backwards compatibility
 * 
 * @deprecated Use TypedHandler<T> or UniversalHandler instead
 */
export abstract class LegacyBaseHandler {
  protected config: HandlerConfig;
  
  constructor(config: Partial<HandlerConfig> = {}) {
    this.config = {
      enabled: true,
      debug: process.env['HOOK_DEBUG'] === '1',
      verbose: process.env['HOOK_VERBOSE'] === '1',
      ...config
    };
  }
  
  abstract handle(input: HookInput): Promise<HandlerResult>;
  
  /**
   * Debug logging
   */
  protected debug(message: string, isVerbose = false): void {
    if (this.config.debug || (isVerbose && this.config.verbose)) {
      console.log(`🔍 [${this.constructor.name}] ${message}`);
    }
  }
  
  /**
   * Create a success response
   */
  protected success(message?: string): HandlerResult {
    return { success: true, shouldContinue: true, message };
  }
  
  /**
   * Create a failure response
   */
  protected fail(message: string): HandlerResult {
    console.error(`❌ ${message}`);
    return { success: false, shouldContinue: false, message };
  }
  
  /**
   * Create a warning response
   */
  protected warn(message: string): HandlerResult {
    console.warn(`⚠️ ${message}`);
    return { success: true, shouldContinue: true, message };
  }
  
  /**
   * Check if this handler should process the given input
   */
  shouldHandle(input: HookInput): boolean {
    return this.config.enabled;
  }
}

// Re-export for backwards compatibility
export const BaseHandler = LegacyBaseHandler;