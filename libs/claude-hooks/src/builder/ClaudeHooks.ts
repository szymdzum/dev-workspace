/**
 * ClaudeHooks - Fluent API for hook configuration
 * 
 * Provides a clean, type-safe way to configure Claude Code hooks
 * with a builder pattern that's actually pleasant to use.
 */

import { HookEvent, HookInput } from '../types/claude-code';
import { HookResponse, ExitCode } from '../types/responses';
import { parseHookInput, respond, exit } from '../types/helpers';
import { TypedHandler, UniversalHandler, HandlerConfig } from '../handlers/base';
import { ValidationHandler, ValidationConfig, Validation } from '../handlers/validation';
import { SecurityHandler, SecurityConfig, Security } from '../handlers/security';

/**
 * Handler function type for inline handlers
 */
export type HandlerFunction<T extends HookEvent> = (
  input: Extract<HookInput, { hook_event_name: T }>
) => Promise<HookResponse<T>>;

/**
 * Universal handler function for any event
 */
export type UniversalHandlerFunction = (input: HookInput) => Promise<HookResponse<any>>;

/**
 * Configuration for the ClaudeHooks system
 */
export interface ClaudeHooksConfig {
  /** Global debug setting */
  debug: boolean;
  
  /** Verbose logging */
  verbose: boolean;
  
  /** Stop processing on first error */
  stopOnError: boolean;
  
  /** Log execution time */
  timing: boolean;
}

/**
 * Main builder class for Claude hooks
 */
export class ClaudeHooks {
  private handlers: Array<TypedHandler<any> | UniversalHandler> = [];
  private config: ClaudeHooksConfig;
  
  private constructor(config: Partial<ClaudeHooksConfig> = {}) {
    this.config = {
      debug: process.env['HOOK_DEBUG'] === '1',
      verbose: process.env['HOOK_VERBOSE'] === '1',
      stopOnError: true,
      timing: false,
      ...config
    };
  }
  
  /**
   * Create a new ClaudeHooks builder
   */
  static create(config: Partial<ClaudeHooksConfig> = {}): ClaudeHooks {
    return new ClaudeHooks(config);
  }
  
  /**
   * Add a typed event handler
   * 
   * @example
   * hooks.on('PreToolUse', async (input) => {
   *   // input is PreToolUseInput, fully typed!
   *   return { continue: true };
   * });
   */
  on<T extends HookEvent>(
    event: T,
    handler: HandlerFunction<T>
  ): this {
    const typedHandler = new InlineHandler(event, handler, this.getHandlerConfig());
    this.handlers.push(typedHandler);
    this.debugLog(`Added inline handler for ${event}`);
    return this;
  }
  
  /**
   * Add a handler instance
   */
  addHandler(handler: TypedHandler<any> | UniversalHandler): this {
    this.handlers.push(handler);
    const name = handler.constructor.name;
    this.debugLog(`Added handler: ${name}`);
    return this;
  }
  
  /**
   * Add security validation
   */
  useSecurity(config: Partial<SecurityConfig> = {}): this {
    this.addHandler(new SecurityHandler(config));
    return this;
  }
  
  /**
   * Add validation with Nx
   */
  useValidation(config: Partial<ValidationConfig> = {}): this {
    this.addHandler(new ValidationHandler(config));
    return this;
  }
  
  /**
   * Use common defaults (security + basic validation)
   */
  useDefaults(): this {
    return this
      .useSecurity()
      .useValidation({ targets: ['lint', 'build'] });
  }
  
  /**
   * Configure global settings
   */
  configure(config: Partial<ClaudeHooksConfig>): this {
    this.config = { ...this.config, ...config };
    return this;
  }
  
  /**
   * Enable debug logging
   */
  debug(enabled = true): this {
    this.config.debug = enabled;
    return this;
  }
  
  /**
   * Enable verbose logging
   */
  verbose(enabled = true): this {
    this.config.verbose = enabled;
    return this;
  }
  
  /**
   * Process a single hook input
   */
  async process(input: HookInput): Promise<void> {
    const startTime = this.config.timing ? Date.now() : 0;
    
    try {
      this.debugLog(`Processing ${input.hook_event_name} event`);
      
      // Find applicable handlers
      const applicableHandlers = this.handlers.filter(handler => {
        if (handler instanceof TypedHandler) {
          return handler.shouldHandle(input);
        } else {
          return handler.shouldHandle(input);
        }
      });
      
      this.debugLog(`Found ${applicableHandlers.length} applicable handlers`);
      
      // Execute handlers in sequence
      for (const handler of applicableHandlers) {
        const handlerName = handler.constructor.name;
        this.debugLog(`Executing ${handlerName}...`);
        
        try {
          const response = await handler.handle(input);
          
          // Check if we should stop
          if (response.continue === false) {
            this.debugLog(`Handler ${handlerName} requested stop`);
            
            if (response.stopReason) {
              exit(response.stopReason, ExitCode.Block);
            }
            
            respond(response, ExitCode.Block);
          }
          
          // Log system messages
          if (response.systemMessage) {
            console.log(response.systemMessage);
          }
          
        } catch (error: any) {
          const errorMsg = `Handler ${handlerName} failed: ${error.message}`;
          this.debugLog(errorMsg);
          
          if (this.config.stopOnError) {
            exit(errorMsg, ExitCode.Error);
          } else {
            console.error(`⚠️ ${errorMsg}`);
          }
        }
      }
      
      if (this.config.timing) {
        const duration = Date.now() - startTime;
        this.debugLog(`Processing completed in ${duration}ms`);
      }
      
    } catch (error: any) {
      exit(`Hook processing failed: ${error.message}`, ExitCode.Error);
    }
  }
  
  /**
   * Run the CLI - parse stdin and process
   */
  async run(): Promise<never> {
    try {
      const input = parseHookInput();
      await this.process(input);
      process.exit(0);
    } catch (error: any) {
      exit(`Failed to process hook: ${error.message}`, ExitCode.Error);
    }
  }
  
  /**
   * Get handler configuration
   */
  private getHandlerConfig(): Partial<HandlerConfig> {
    return {
      debug: this.config.debug,
      verbose: this.config.verbose,
      enabled: true
    };
  }
  
  /**
   * Debug logging
   */
  private debugLog(message: string): void {
    if (this.config.debug) {
      console.log(`🔍 [ClaudeHooks] ${message}`);
    }
  }
  
  /**
   * Debug shorthand (for internal use)
   */
  private debugLog2(message: string): void {
    this.debugLog(message);
  }
}

/**
 * Inline handler wrapper for function-based handlers
 */
class InlineHandler<T extends HookEvent> extends TypedHandler<T> {
  readonly event: T;
  private handlerFn: HandlerFunction<T>;
  
  constructor(event: T, handler: HandlerFunction<T>, config: Partial<HandlerConfig>) {
    super(config);
    this.event = event;
    this.handlerFn = handler;
  }
  
  async handle(input: Extract<HookInput, { hook_event_name: T }>): Promise<HookResponse<T>> {
    return await this.handlerFn(input);
  }
}

/**
 * Quick factory functions
 */
export const createHooks = ClaudeHooks.create;

/**
 * Pre-configured hook setups
 */
export const HookPresets = {
  /**
   * Basic setup with security and validation
   */
  basic(): ClaudeHooks {
    return ClaudeHooks.create()
      .useDefaults();
  },
  
  /**
   * Development setup with comprehensive validation
   */
  development(): ClaudeHooks {
    return ClaudeHooks.create()
      .useSecurity()
      .useValidation({
        targets: ['lint', 'build', 'test'],
        affectedOnly: true
      })
      .debug(true);
  },
  
  /**
   * Production setup with strict security
   */
  production(): ClaudeHooks {
    return ClaudeHooks.create()
      .useSecurity({ blockOnSecrets: true })
      .useValidation({
        targets: ['lint', 'build'],
        affectedOnly: true
      });
  },
  
  /**
   * Minimal setup - security only
   */
  minimal(): ClaudeHooks {
    return ClaudeHooks.create()
      .useSecurity();
  }
};