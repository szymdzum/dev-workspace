// New type-safe API
export * from './types';
export * from './handlers/base';
export * from './handlers/security';
export * from './handlers/validation';
export * from './handlers/results-validator';
export * from './handlers/change-tracker';
export * from './builder/ClaudeHooks';

// Secure CLI system (with renamed exports to avoid conflicts)
export { 
  SecureHookBase, 
  HookResult,
  SecurityViolation,
  runSecureHook
} from './secure/base';
export { 
  HookLogger,
  Analytics,
  SessionStats,
  PerformanceEvent
} from './secure/logger';

// Re-export types with aliases to avoid conflicts
export { 
  HookInput as SecureHookInput
} from './secure/base';
export {
  HookEvent as LoggerHookEvent,
  SecurityEvent,
  Analytics as HookAnalytics
} from './secure/logger';

// Legacy exports for backward compatibility
export * from './lib/hook-system';
export { 
  BashHandler as LegacyBashHandler,
  SecurityHandler as LegacySecurityHandler 
} from './lib/example-handlers';
export { 
  HookEvent as LegacyHookEvent,
  HookInput as LegacyHookInput,
  ToolName as LegacyToolName,
  BaseHandler as LegacyBaseHandler,
  HandlerResult as LegacyHandlerResult,
  HookConfig as LegacyHookConfig
} from './lib/types';


