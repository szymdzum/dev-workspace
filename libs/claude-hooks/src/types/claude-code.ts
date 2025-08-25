/**
 * Claude Code Hook Types
 * 
 * Complete type definitions for Claude Code's hook system.
 * Because flying blind with `any` is for people who enjoy debugging at 3 AM.
 * 
 * @packageDocumentation
 */

/**
 * Hook event types - when stuff happens and Claude needs to know
 * 
 * @remarks
 * Each event has different input/output contracts. Using the wrong one
 * is like bringing a knife to a gunfight, except the knife is bash
 * and the gunfight is your production environment.
 */
export type HookEvent = 
  | 'PreToolUse'      // "Hey, I'm about to do something stupid"
  | 'PostToolUse'     // "I did the stupid thing"
  | 'UserPromptSubmit'// "User typed words, make them better"
  | 'SessionStart'    // "Good morning, time to load 47MB of context"
  | 'SessionEnd'      // "Goodbye, don't forget to clean up"
  | 'Stop'            // "Claude is done talking (maybe)"
  | 'SubagentStop'    // "The minion finished its task"
  | 'Notification'    // "Something happened, probably important"
  | 'PreCompact';     // "About to forget everything, save what matters"

/**
 * Tool names Claude can use to destroy your filesystem
 * 
 * @remarks
 * Each tool has its own input schema. Claude Code doesn't tell you this.
 * You're welcome.
 */
export type ToolName = 
  | 'Bash'            // Executes anything. ANYTHING.
  | 'Write'           // Creates/overwrites files
  | 'Edit'            // Modifies specific parts
  | 'MultiEdit'       // Edit on steroids
  | 'Read'            // At least this one's safe
  | 'Task'            // Spawns a subagent (recursive chaos)
  | 'TodoWrite'       // Creates task lists
  | 'WebFetch'        // Downloads the internet
  | 'WebSearch'       // Googles things badly
  | 'Glob'            // Finds files
  | 'Grep'            // Searches content
  | 'LS'              // Lists directories
  | 'NotebookEdit'    // Jupyter chaos
  | 'NotebookRead';   // Jupyter voyeurism

/**
 * Base hook input - what every hook gets from stdin
 * 
 * @remarks
 * This comes as JSON via stdin. If you're reading this from argv,
 * you're doing it wrong and deserve whatever happens next.
 */
export interface BaseHookInput {
  /** Unique session identifier - use this to track multi-hook workflows */
  session_id: string;
  
  /** Path to the conversation transcript - JSONL format, good luck parsing it */
  transcript_path: string;
  
  /** Current working directory when hook was invoked */
  cwd: string;
  
  /** The event that triggered this hook - determines what other fields exist */
  hook_event_name: HookEvent;
}

/**
 * Tool-specific inputs - because each tool is a special snowflake
 * 
 * @remarks
 * Some tools use camelCase, others use snake_case. 
 * This is what happens when you let different teams write code.
 */
export interface ToolInputs {
  Write: {
    file_path: string;
    content: string;
  };
  
  Edit: {
    file_path: string;
    old_text: string;
    new_text: string;
  };
  
  MultiEdit: {
    file_path: string;
    edits: Array<{
      old_text: string;
      new_text: string;
    }>;
  };
  
  Read: {
    file_path: string;
  };
  
  Bash: {
    command: string;
    timeout?: number;
  };
  
  Task: {
    task: string;
    agent?: string;
  };
  
  WebFetch: {
    url: string;
  };
  
  WebSearch: {
    query: string;
    domains?: string[];
  };
  
  Glob: {
    pattern: string;
  };
  
  Grep: {
    pattern: string;
    paths?: string[];
  };
}

/**
 * PreToolUse hook input - Claude's about to do something
 * 
 * @remarks
 * This is your chance to stop Claude from rm -rf /
 * Exit code 2 blocks execution. You've been warned.
 */
export interface PreToolUseInput<T extends ToolName = ToolName> extends BaseHookInput {
  hook_event_name: 'PreToolUse';
  
  /** Which tool Claude wants to use */
  tool_name: T;
  
  /** Parameters for the tool - type depends on tool_name */
  tool_input: T extends keyof ToolInputs ? ToolInputs[T] : Record<string, any>;
}

/**
 * PostToolUse hook input - Claude did the thing
 * 
 * @remarks
 * The damage is done. You can only complain about it now.
 */
export interface PostToolUseInput<T extends ToolName = ToolName> extends BaseHookInput {
  hook_event_name: 'PostToolUse';
  tool_name: T;
  tool_input: T extends keyof ToolInputs ? ToolInputs[T] : Record<string, any>;
  
  /** What the tool returned - structure varies wildly */
  tool_response: {
    success?: boolean;
    error?: string;
    [key: string]: any;  // Because who needs consistency?
  };
}

/**
 * UserPromptSubmit input - user said words
 * 
 * @remarks
 * You can inject context here. Exit code 0 with stdout adds to context.
 * This is the ONLY hook where stdout goes to Claude when exit code is 0.
 * Yes, it's inconsistent. No, they won't fix it.
 */
export interface UserPromptSubmitInput extends BaseHookInput {
  hook_event_name: 'UserPromptSubmit';
  
  /** What the user actually typed */
  prompt: string;
}

/**
 * Stop hook input - Claude thinks it's done
 * 
 * @remarks
 * stop_hook_active prevents infinite loops. If true, you're already
 * in a stop hook. Don't create another one unless you enjoy recursion.
 */
export interface StopInput extends BaseHookInput {
  hook_event_name: 'Stop' | 'SubagentStop';
  
  /** True if we're already in a stop hook - check this or suffer */
  stop_hook_active: boolean;
}

/**
 * SessionStart input - new conversation or resume
 * 
 * @remarks
 * Load your context here. This is where you inject "oh by the way,
 * the production database password is definitely not 'admin123'"
 */
export interface SessionStartInput extends BaseHookInput {
  hook_event_name: 'SessionStart';
  
  /** How this session started */
  source: 'startup' | 'resume' | 'clear';
}

/**
 * SessionEnd input - conversation over
 * 
 * @remarks
 * Clean up your mess. Delete temp files. Clear caches.
 * This is your last chance to not leave garbage everywhere.
 */
export interface SessionEndInput extends BaseHookInput {
  hook_event_name: 'SessionEnd';
  
  /** Why the session ended */
  reason: 'clear' | 'logout' | 'prompt_input_exit' | 'exit' | 'other';
}

/**
 * PreCompact input - about to summarize and forget
 * 
 * @remarks
 * Claude's context is full. It's about to summarize everything
 * and forget the details. Save what matters NOW.
 */
export interface PreCompactInput extends BaseHookInput {
  hook_event_name: 'PreCompact';
  
  /** What triggered compaction */
  trigger: 'manual' | 'auto';
  
  /** User's instructions for compaction (if manual) */
  custom_instructions?: string;
}

/**
 * Notification input - something happened
 * 
 * @remarks
 * Usually "Claude needs permission" or "Claude is waiting".
 * You can't block these, only log them and cry.
 */
export interface NotificationInput extends BaseHookInput {
  hook_event_name: 'Notification';
  
  /** The message Claude is showing the user */
  message: string;
}

/**
 * Union type for all possible hook inputs
 * 
 * @remarks
 * Use this with a discriminated union check on hook_event_name.
 * TypeScript will narrow the type for you. Magic!
 */
export type HookInput = 
  | PreToolUseInput
  | PostToolUseInput
  | UserPromptSubmitInput
  | StopInput
  | SessionStartInput
  | SessionEndInput
  | PreCompactInput
  | NotificationInput;

// Re-export commonly used combinations - forward declarations
export type PreToolUseHook = {
  input: PreToolUseInput;
  response: any; // Will be properly typed in responses.ts
  exitCodes: {
    allow: 0;
    block: 2;
  };
};

export type PostToolUseHook = {
  input: PostToolUseInput;
  response: any; // Will be properly typed in responses.ts
  exitCodes: {
    success: 0;
    warning: 1;
    error: 2;
  };
};

export type UserPromptHook = {
  input: UserPromptSubmitInput;
  response: any; // Will be properly typed in responses.ts
  exitCodes: {
    /** Stdout becomes context */
    addContext: 0;
    /** Block prompt */
    block: 2;
  };
};

/**
 * Version of the type definitions
 * 
 * @remarks
 * Update this when Claude Code inevitably changes everything
 * without telling anyone.
 */
export const TYPES_VERSION = '1.0.0';

/**
 * Claude Code version these types are built for
 * 
 * @remarks
 * When this doesn't match reality, expect pain.
 */
export const CLAUDE_CODE_VERSION = '1.0.52';