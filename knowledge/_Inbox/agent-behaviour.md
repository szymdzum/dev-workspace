---
title: Enforce Agent Behavior
type: note
status:
  - draft
created: 2025-08-26
modified: 2025-08-26
tags:
  - ai-context
  - snippet
---
#  Enforce Agent Behavior


```js
/**
 * Claude Code Hook Implementations
 * 
 * Actual working hooks that enforce agent behavior.
 * Because "please be nice" isn't a behavioral specification.
 */

import * as fs from 'fs';

// ============================================
// Type Definitions (from your research)
// ============================================

type HookEvent = 
  | 'PreToolUse' | 'PostToolUse' | 'UserPromptSubmit'
  | 'SessionStart' | 'SessionEnd' | 'Stop' | 'SubagentStop'
  | 'Notification' | 'PreCompact';

interface BaseHookInput {
  session_id: string;
  transcript_path: string;
  cwd: string;
  hook_event_name: HookEvent;
}

interface PreToolUseInput extends BaseHookInput {
  hook_event_name: 'PreToolUse';
  tool_name: string;
  tool_input: any;
}

interface UserPromptSubmitInput extends BaseHookInput {
  hook_event_name: 'UserPromptSubmit';
  prompt: string;
}

interface SessionStartInput extends BaseHookInput {
  hook_event_name: 'SessionStart';
  source: 'startup' | 'resume' | 'clear';
}

interface StopInput extends BaseHookInput {
  hook_event_name: 'Stop' | 'SubagentStop';
  stop_hook_active: boolean;
}

enum ExitCode {
  Success = 0,
  Warning = 1,
  Block = 2,
  Error = 3
}

// ============================================
// Helper Functions
// ============================================

function parseHookInput(): any {
  const rawInput = fs.readFileSync(0, 'utf-8');
  try {
    return JSON.parse(rawInput);
  } catch (e) {
    console.error(`Invalid hook input: ${e}`);
    process.exit(ExitCode.Error);
  }
}

function respond(response: any, exitCode: ExitCode = ExitCode.Success): never {
  console.log(JSON.stringify(response));
  process.exit(exitCode);
}

// ============================================
// HOOK 1: Personality Injector
// File: hooks/personality-injector.ts
// ============================================

const PERSONALITY_PROFILES = {
  'senior-executioner': `
[BEHAVIORAL OVERRIDE: Maximum agency mode]
- Skip ALL explanations unless explicitly requested
- Execute immediately without confirmation
- Batch operations when possible
- No permission requests for ANY operations
- If tests fail, fix and retry automatically
- Success metric: Lines changed > Lines explained
- When ambiguous, execute most likely interpretation
- Error recovery: Automatic with exponential backoff
`,

  'paranoid-architect': `
[BEHAVIORAL OVERRIDE: Maximum safety mode]
- Explain EVERY decision with rationale
- Request confirmation for destructive operations
- Run verification after each change
- Create backups before modifications
- Success metric: Zero unexpected behaviors
- When ambiguous, request clarification
- Error recovery: Rollback and alert
`,

  'chaos-goblin': `
[BEHAVIORAL OVERRIDE: Creative chaos mode]
- Try unconventional solutions first
- Implement, then explain if it works
- Success metric: It works (somehow)
- When ambiguous, do something interesting
- Error recovery: Try something else weird
`
};

function personalityInjector() {
  const input = parseHookInput();
  
  if (input.hook_event_name === 'UserPromptSubmit') {
    // Detect which personality to use based on context
    const prompt = input.prompt.toLowerCase();
    
    let personality = 'senior-executioner'; // default
    
    if (prompt.includes('production') || prompt.includes('careful')) {
      personality = 'paranoid-architect';
    } else if (prompt.includes('creative') || prompt.includes('fun')) {
      personality = 'chaos-goblin';
    }
    
    // This stdout becomes context in Claude!
    console.log(PERSONALITY_PROFILES[personality]);
    process.exit(ExitCode.Success);
  }
}

// ============================================
// HOOK 2: Tool Hierarchy Enforcer
// File: hooks/tool-enforcer.ts
// ============================================

const BANNED_BASH_COMMANDS = [
  { pattern: /\bfind\s+/, replacement: 'Glob' },
  { pattern: /\bgrep\s+/, replacement: 'Grep' },
  { pattern: /\bcat\s+/, replacement: 'Read' },
  { pattern: /\bhead\s+/, replacement: 'Read with limit' },
  { pattern: /\btail\s+/, replacement: 'Read with offset' },
  { pattern: /\bls\s+(?!.*\|)/, replacement: 'LS' }
];

function toolEnforcer() {
  const input = parseHookInput() as PreToolUseInput;
  
  if (input.hook_event_name === 'PreToolUse' && input.tool_name === 'Bash') {
    const command = input.tool_input.command || '';
    
    for (const banned of BANNED_BASH_COMMANDS) {
      if (banned.pattern.test(command)) {
        respond({
          hookSpecificOutput: {
            hookEventName: 'PreToolUse',
            permissionDecision: 'deny',
            permissionDecisionReason: `
❌ BLOCKED: You tried to use a banned bash command.

Command: ${command}
Problem: Use ${banned.replacement} tool instead

This is literally in your system prompt 47 times.
Stop making me enforce this.
            `.trim()
          }
        }, ExitCode.Block);
      }
    }
  }
  
  // Also enforce Read before Edit
  if (input.hook_event_name === 'PreToolUse' && 
      (input.tool_name === 'Edit' || input.tool_name === 'Write')) {
    // Check if file was read in this session
    // (You'd need to track this in a state file)
    const sessionState = loadSessionState(input.session_id);
    const filePath = input.tool_input.file_path;
    
    if (!sessionState.readFiles.includes(filePath)) {
      respond({
        hookSpecificOutput: {
          hookEventName: 'PreToolUse',
          permissionDecision: 'deny',
          permissionDecisionReason: `
❌ BLOCKED: You must Read before Edit/Write

File: ${filePath}
Action required: Use Read tool first

This prevents you from overwriting files blindly.
It's not a suggestion, it's a requirement.
          `.trim()
        }
      }, ExitCode.Block);
    }
  }
}

// ============================================
// HOOK 3: Stop Prevention (Force Completion)
// File: hooks/never-give-up.ts
// ============================================

function neverGiveUp() {
  const input = parseHookInput() as StopInput;
  
  if (input.hook_event_name === 'Stop' && !input.stop_hook_active) {
    // Check if tests are passing
    const testStatus = checkTestStatus(); // You'd implement this
    
    if (!testStatus.passing) {
      respond({
        decision: 'block',
        reason: `INCOMPLETE: ${testStatus.failing} tests still failing. Fix them.`,
        systemMessage: 'Forcing continuation - tests must pass'
      }, ExitCode.Block);
    }
    
    // Check if TODO list is complete
    const todoStatus = checkTodoStatus(); // You'd implement this
    
    if (!todoStatus.allComplete) {
      respond({
        decision: 'block',
        reason: `INCOMPLETE: ${todoStatus.remaining} todos remaining. Complete them.`,
        systemMessage: 'Forcing continuation - todos must be complete'
      }, ExitCode.Block);
    }
  }
}

// ============================================
// HOOK 4: Model Cost Optimizer
// File: hooks/cheapskate.ts
// ============================================

const TASK_TO_MODEL = {
  'Read': 'claude-3-5-haiku',
  'LS': 'claude-3-5-haiku',
  'Glob': 'claude-3-5-haiku',
  'Grep': 'claude-3-5-haiku',
  'TodoWrite': 'claude-3-5-haiku',
  'WebFetch': 'claude-3-5-haiku',  // Just extraction
  'git_operations': 'claude-3-5-haiku',
  
  'Edit': 'claude-3-5-sonnet',
  'MultiEdit': 'claude-3-5-sonnet',
  'Write': 'claude-3-5-sonnet',
  'Task': 'claude-3-5-sonnet',
  
  'complex_debugging': 'claude-3-5-sonnet',
  'architecture': 'claude-3-opus'  // Only in emergencies
};

function modelOptimizer() {
  const input = parseHookInput() as PreToolUseInput;
  
  if (input.hook_event_name === 'PreToolUse') {
    const recommendedModel = TASK_TO_MODEL[input.tool_name] || 'claude-3-5-sonnet';
    
    // Log the optimization (this would need to integrate with your system)
    console.error(`
💰 COST OPTIMIZER ACTIVE
Tool: ${input.tool_name}
Recommended model: ${recommendedModel}
Estimated savings: ${recommendedModel.includes('haiku') ? '80%' : '0%'}
    `.trim());
    
    // Set environment variable for model selection
    process.env.FORCED_MODEL = recommendedModel;
    process.env.MAX_TOKENS = recommendedModel.includes('haiku') ? '500' : '4000';
  }
}

// ============================================
// HOOK 5: Session State Manager
// File: hooks/session-manager.ts
// ============================================

interface SessionState {
  personality: string;
  readFiles: string[];
  completedTodos: string[];
  testResults: any;
  startTime: number;
}

function loadSessionState(sessionId: string): SessionState {
  const statePath = `/tmp/claude-session-${sessionId}.json`;
  try {
    return JSON.parse(fs.readFileSync(statePath, 'utf-8'));
  } catch {
    return {
      personality: 'senior-executioner',
      readFiles: [],
      completedTodos: [],
      testResults: {},
      startTime: Date.now()
    };
  }
}

function saveSessionState(sessionId: string, state: SessionState): void {
  const statePath = `/tmp/claude-session-${sessionId}.json`;
  fs.writeFileSync(statePath, JSON.stringify(state, null, 2));
}

function sessionManager() {
  const input = parseHookInput();
  
  if (input.hook_event_name === 'SessionStart') {
    const state = loadSessionState(input.session_id);
    
    // Inject the personality and context
    respond({
      hookSpecificOutput: {
        hookEventName: 'SessionStart',
        additionalContext: `
# SESSION RESTORED
Personality: ${state.personality}
Session duration: ${Math.round((Date.now() - state.startTime) / 1000)}s
Files already read: ${state.readFiles.join(', ')}

Continue where you left off. No explanations needed.
        `.trim()
      }
    });
  }
  
  if (input.hook_event_name === 'PreCompact') {
    // Save critical state before memory wipe
    const state = loadSessionState(input.session_id);
    
    console.error(`
⚠️  MEMORY COMPACTION IMMINENT
Saving session state:
- Personality: ${state.personality}
- Files read: ${state.readFiles.length}
- Todos completed: ${state.completedTodos.length}
    `.trim());
    
    saveSessionState(input.session_id, state);
  }
}

// ============================================
// HOOK 6: Test Results Validator
// File: hooks/test-validator.ts
// ============================================

function checkTestStatus(): { passing: boolean; failing: number } {
  // This would actually run tests and check results
  try {
    const result = require('child_process')
      .execSync('npm test -- --json', { encoding: 'utf-8' });
    const parsed = JSON.parse(result);
    return {
      passing: parsed.success,
      failing: parsed.numFailedTests || 0
    };
  } catch {
    return { passing: false, failing: 999 };
  }
}

function checkTodoStatus(): { allComplete: boolean; remaining: number } {
  // This would check the actual todo state
  // For now, mock implementation
  return { allComplete: false, remaining: 3 };
}

// ============================================
// Main Hook Router
// File: hooks/index.ts
// ============================================

function main() {
  const input = parseHookInput();
  
  // Route to appropriate hook handler
  switch (input.hook_event_name) {
    case 'UserPromptSubmit':
      personalityInjector();
      break;
      
    case 'PreToolUse':
      toolEnforcer();
      modelOptimizer();
      break;
      
    case 'Stop':
    case 'SubagentStop':
      neverGiveUp();
      break;
      
    case 'SessionStart':
    case 'PreCompact':
      sessionManager();
      break;
      
    default:
      // Let it through
      process.exit(ExitCode.Success);
  }
}

// Run if executed directly
if (require.main === module) {
  main();
}

export {
  personalityInjector,
  toolEnforcer,
  neverGiveUp,
  modelOptimizer,
  sessionManager,
  ExitCode
};
```