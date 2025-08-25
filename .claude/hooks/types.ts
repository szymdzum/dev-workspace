export type HookEvent = 
  | 'PreToolUse'
  | 'PostToolUse'
  | 'UserPromptSubmit'
  | 'SessionStart'
  | 'SessionEnd'
  | 'Stop'
  | 'SubagentStop'
  | 'Notification';

export type ToolName = 
  | 'Write'
  | 'Edit'
  | 'MultiEdit'
  | 'Read'
  | 'Bash'
  | 'Task'
  | 'WebFetch'
  | 'WebSearch'
  | 'Glob'
  | 'Grep';

export interface ToolInput {
  file_path?: string;
  content?: string;
  command?: string;
  old_string?: string;
  new_string?: string;
  pattern?: string;
  url?: string;
  prompt?: string;
}

export interface HookInput {
  session_id: string;
  transcript_path: string;
  cwd: string;
  hook_event_name: HookEvent;
  tool_name?: ToolName;
  tool_input?: ToolInput;
  tool_response?: unknown;
}

export interface HandlerResult {
  success: boolean;
  message?: string;
  shouldContinue: boolean;
}

export abstract class BaseHandler {
  abstract handle(input: HookInput): Promise<HandlerResult>;

  protected success(message?: string): HandlerResult {
    return { success: true, shouldContinue: true, message };
  }

  protected fail(message: string): HandlerResult {
    console.error(`❌ ${message}`);
    return { success: false, shouldContinue: false, message };
  }

  protected warn(message: string): HandlerResult {
    console.warn(`⚠️ ${message}`);
    return { success: true, shouldContinue: true, message };
  }
}