/**
 * Hook Response Types - How to Control Claude's Chaos
 * 
 * Exit codes matter. JSON output matters more. 
 * Get this wrong and Claude does whatever it wants.
 */

/**
 * Exit codes and their magical meanings
 * 
 * @remarks
 * Exit code 2 is special. It blocks things and sends stderr to Claude.
 * Every other exit code just complains to the user.
 */
export enum ExitCode {
  /** Everything's fine, move along */
  Success = 0,
  
  /** Warning - shown to user, execution continues */
  Warning = 1,
  
  /** BLOCK - prevents tool execution (PreToolUse) or sends error to Claude */
  Block = 2,
  
  /** Any other error - shown to user, execution continues */
  Error = 3
}

/**
 * Base JSON response - common fields for all hooks
 * 
 * @remarks
 * Return this as JSON to stdout for fine-grained control.
 * Or just exit with a code like a caveman. Your choice.
 */
export interface BaseHookResponse {
  /** Whether Claude should continue after this hook. False = full stop */
  continue?: boolean;
  
  /** Reason for stopping (shown to user, not Claude) */
  stopReason?: string;
  
  /** Hide stdout from transcript mode (Ctrl-R) */
  suppressOutput?: boolean;
  
  /** Warning message shown to user */
  systemMessage?: string;
}

/**
 * PreToolUse response - control whether tool runs
 * 
 * @remarks
 * 'allow' bypasses permission system entirely.
 * 'deny' blocks and tells Claude why.
 * 'ask' makes the user decide (coward's way out).
 */
export interface PreToolUseResponse extends BaseHookResponse {
  /** Hook-specific output for PreToolUse */
  hookSpecificOutput?: {
    hookEventName: 'PreToolUse';
    
    /** What to do with this tool call */
    permissionDecision: 'allow' | 'deny' | 'ask';
    
    /** Why (shown to Claude if deny, user if allow/ask) */
    permissionDecisionReason?: string;
  };
  
  /** @deprecated Use hookSpecificOutput.permissionDecision */
  decision?: 'approve' | 'block';
  
  /** @deprecated Use hookSpecificOutput.permissionDecisionReason */
  reason?: string;
}

/**
 * PostToolUse response - complain after the fact
 * 
 * @remarks
 * Tool already ran. You can only whine about it now.
 * 'block' makes Claude reconsider its life choices.
 */
export interface PostToolUseResponse extends BaseHookResponse {
  /** Block = tell Claude it messed up */
  decision?: 'block';
  
  /** Why it messed up */
  reason?: string;
  
  /** Additional context for Claude to consider */
  hookSpecificOutput?: {
    hookEventName: 'PostToolUse';
    additionalContext?: string;
  };
}

/**
 * UserPromptSubmit response - modify or block prompts
 * 
 * @remarks
 * You can block bad prompts or inject context.
 * This is how you add "btw the user is an idiot" to every prompt.
 */
export interface UserPromptSubmitResponse extends BaseHookResponse {
  /** Block = don't process this prompt */
  decision?: 'block';
  
  /** Why we're blocking (shown to user) */
  reason?: string;
  
  /** Context to add if not blocked */
  hookSpecificOutput?: {
    hookEventName: 'UserPromptSubmit';
    additionalContext?: string;
  };
}

/**
 * Stop response - force Claude to continue
 * 
 * @remarks
 * decision: 'block' prevents Claude from stopping.
 * Use this to create infinite loops. Or don't. Please don't.
 */
export interface StopResponse extends BaseHookResponse {
  /** Block = Claude must continue */
  decision?: 'block';
  
  /** What Claude should do instead of stopping */
  reason?: string;
}

/**
 * SessionStart response - inject initial context
 * 
 * @remarks
 * Your chance to load "here's everything you forgot" context.
 * Multiple hooks' contexts are concatenated. Order matters.
 */
export interface SessionStartResponse extends BaseHookResponse {
  hookSpecificOutput?: {
    hookEventName: 'SessionStart';
    
    /** Context to add at session start */
    additionalContext?: string;
  };
}

/**
 * Response type based on event
 * 
 * @remarks
 * TypeScript will narrow this based on hookEventName.
 * Use it correctly or Claude will ignore you.
 */
export type HookResponse<T extends import('./claude-code').HookEvent> = 
  T extends 'PreToolUse' ? PreToolUseResponse :
  T extends 'PostToolUse' ? PostToolUseResponse :
  T extends 'UserPromptSubmit' ? UserPromptSubmitResponse :
  T extends 'Stop' | 'SubagentStop' ? StopResponse :
  T extends 'SessionStart' ? SessionStartResponse :
  BaseHookResponse;

/**
 * Type guard to check if response should block
 */
export function isBlockingResponse(response: any): boolean {
  return response?.continue === false || 
         response?.decision === 'block' ||
         response?.hookSpecificOutput?.permissionDecision === 'deny';
}

/**
 * Type guard for exit code blocking
 */
export function isBlockingExitCode(code: number): boolean {
  return code === ExitCode.Block;
}