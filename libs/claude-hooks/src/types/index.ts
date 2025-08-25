/**
 * Claude Code Hook Types
 * 
 * Complete type definitions for Claude Code's hook system.
 * Because flying blind with `any` is for people who enjoy debugging at 3 AM.
 * 
 * @packageDocumentation
 */

export * from './claude-code';
export * from './responses';
export * from './helpers';

// Re-export commonly used combinations
export type { PreToolUseHook, PostToolUseHook, UserPromptHook } from './claude-code';