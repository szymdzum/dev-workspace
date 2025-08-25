import { HookInput, BaseHandler, HookConfig } from './types';

export class HookSystem {
  private handlers: Record<string, BaseHandler> = {};
  private config: HookConfig;

  constructor(config: HookConfig, handlers: Record<string, BaseHandler> = {}) {
    this.config = config;
    this.handlers = handlers;
  }

  addHandler(name: string, handler: BaseHandler): void {
    this.handlers[name] = handler;
  }

  async process(input: HookInput): Promise<void> {
    try {
      if (this.config.debug) {
        console.log(`🔍 [HookSystem] Processing: ${input.tool_name} ${input.hook_event_name}`);
        if (this.config.verbose) {
          console.log(`🔍 [HookSystem] Input:`, JSON.stringify(input, null, 2));
        }
      }

      if (!this.config.enabled) {
        if (this.config.debug) {
          console.log(`🔍 [HookSystem] Hooks disabled, exiting`);
        }
        return;
      }

      const handlersToRun = this.getApplicableHandlers(input);

      if (this.config.debug) {
        console.log(`🔍 [HookSystem] Running handlers: [${handlersToRun.join(', ')}]`);
      }

      for (const handlerName of handlersToRun) {
        const handler = this.handlers[handlerName];
        if (!handler) {
          console.warn(`⚠️ Handler not found: ${handlerName}`);
          continue;
        }

        if (this.config.debug) {
          console.log(`🔍 [HookSystem] Executing handler: ${handlerName}`);
        }

        const result = await handler.handle(input);

        if (this.config.debug) {
          console.log(`🔍 [HookSystem] Handler ${handlerName} result: ${result.success ? '✅' : '❌'} ${result.message || ''}`);
        }

        if (!result.shouldContinue) {
          if (this.config.debug) {
            console.log(`🔍 [HookSystem] Handler ${handlerName} requested stop, exiting`);
          }
          throw new Error(`Handler ${handlerName} failed: ${result.message}`);
        }
      }

      if (this.config.debug) {
        console.log(`🔍 [HookSystem] All handlers completed successfully`);
      }
    } catch (error) {
      console.error('Hook execution failed:', error);
      if (this.config.debug) {
        console.error('Stack trace:', error);
      }
      throw error;
    }
  }

  private getApplicableHandlers(input: HookInput): string[] {
    const handlerNames: string[] = [];

    // Add handlers based on tool name
    if (input.tool_name && this.config.handlers[input.tool_name]) {
      handlerNames.push(...this.config.handlers[input.tool_name]);
    }

    // Add handlers based on file extension
    const filePath = input.tool_input?.file_path;
    if (filePath) {
      const extension = filePath.split('.').pop();
      if (extension && this.config.fileHandlers[extension]) {
        handlerNames.push(...this.config.fileHandlers[extension]);
      }
    }

    // Remove duplicates
    return [...new Set(handlerNames)];
  }
}