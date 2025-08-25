/**
 * Helper Types and Guards - The Stuff You'll Actually Use
 * 
 * Type guards, validators, and utility types that make
 * hook development slightly less painful.
 */

import { HookEvent, HookInput, PreToolUseInput, ToolName, ToolInputs } from './claude-code';
import { HookResponse, ExitCode } from './responses';
import * as fs from 'fs';

/**
 * Extract tool input type from a PreToolUse input
 * 
 * @example
 * type WriteInput = ExtractToolInput<PreToolUseInput<'Write'>>
 * // { file_path: string; content: string; }
 */
export type ExtractToolInput<T> = T extends PreToolUseInput<infer Tool> 
  ? Tool extends keyof ToolInputs 
    ? ToolInputs[Tool] 
    : never
  : never;

/**
 * Type guard for specific hook events
 * 
 * @remarks
 * Use this to narrow your input type. TypeScript will thank you.
 * 
 * @example
 * if (isHookEvent(input, 'PreToolUse')) {
 *   // input is now PreToolUseInput
 *   console.log(input.tool_name);
 * }
 */
export function isHookEvent<T extends HookEvent>(
  input: HookInput,
  event: T
): input is Extract<HookInput, { hook_event_name: T }> {
  return input.hook_event_name === event;
}

/**
 * Type guard for specific tools in PreToolUse
 * 
 * @example
 * if (isToolUse(input, 'Bash')) {
 *   // input.tool_input is now { command: string; timeout?: number; }
 *   console.log(`Executing: ${input.tool_input.command}`);
 * }
 */
export function isToolUse<T extends ToolName>(
  input: HookInput,
  tool: T
): input is PreToolUseInput<T> {
  return input.hook_event_name === 'PreToolUse' && 
         (input as PreToolUseInput).tool_name === tool;
}

/**
 * Parse hook input from stdin with validation
 * 
 * @remarks
 * Handles the stdin reading and JSON parsing with proper error handling.
 * Because nobody wants to write this boilerplate 47 times.
 * 
 * @throws {HookInputError} When input is invalid
 */
export function parseHookInput(): HookInput {
  const rawInput = fs.readFileSync(0, 'utf-8');
  
  try {
    const parsed = JSON.parse(rawInput);
    
    // Basic validation
    if (!parsed.hook_event_name) {
      throw new Error('Missing hook_event_name');
    }
    
    if (!parsed.session_id) {
      throw new Error('Missing session_id');
    }
    
    return parsed as HookInput;
  } catch (e: any) {
    throw new HookInputError(`Invalid hook input: ${e.message}`, rawInput);
  }
}

/**
 * Custom error for hook input parsing failures
 */
export class HookInputError extends Error {
  constructor(message: string, public rawInput: string) {
    super(message);
    this.name = 'HookInputError';
  }
}

/**
 * Respond with JSON and exit
 * 
 * @remarks
 * Stringify, print to stdout, exit. It's not rocket science.
 * But you'll mess it up without this helper.
 */
export function respond<T extends HookEvent>(
  response: HookResponse<T>,
  exitCode: ExitCode = ExitCode.Success
): never {
  console.log(JSON.stringify(response));
  process.exit(exitCode);
}

/**
 * Exit with just a message
 * 
 * @remarks
 * For when you're too lazy to build a full JSON response.
 * Message goes to stderr for exit codes 1-3, stdout for 0.
 */
export function exit(
  message: string,
  code: ExitCode = ExitCode.Success
): never {
  if (code === ExitCode.Success) {
    console.log(message);
  } else {
    console.error(message);
  }
  process.exit(code);
}

/**
 * Tool matcher for hook configurations
 * 
 * @remarks
 * Handles wildcards and pipe-separated tool lists.
 * Because "Write|Edit|MultiEdit" should just work.
 * 
 * @example
 * const matcher = new ToolMatcher("Write|Edit");
 * if (matcher.matches("Write")) { // ... }
 */
export class ToolMatcher {
  private patterns: Set<string>;
  
  constructor(pattern: string) {
    if (pattern === '*' || pattern === '') {
      this.patterns = new Set(['*']);
    } else {
      this.patterns = new Set(pattern.split('|').map(p => p.trim()));
    }
  }
  
  matches(toolName: string): boolean {
    return this.patterns.has('*') || this.patterns.has(toolName);
  }
}

/**
 * MCP tool name parser
 * 
 * @remarks
 * MCP tools come as "mcp__server__tool". This splits them.
 * 
 * @example
 * const mcp = parseMCPTool("mcp__memory__create_entities");
 * // { server: "memory", tool: "create_entities" }
 */
export function parseMCPTool(toolName: string): {
  server: string;
  tool: string;
} | null {
  const match = toolName.match(/^mcp__(.+?)__(.+)$/);
  if (!match) return null;
  
  return {
    server: match[1],
    tool: match[2]
  };
}