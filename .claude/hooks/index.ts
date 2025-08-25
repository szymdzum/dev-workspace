/**
 * Claude Hooks Configuration
 * 
 * Using the new fluent API from @claude-dev/hooks library
 */

import { ClaudeHooks, isToolUse, ResultsValidator, ChangeTrackerHandler } from '@claude-dev/hooks';
import { CustomTypeScriptHandler } from '../handlers/typescript.handler';

export default ClaudeHooks.create()
  // Use default security and validation
  .useDefaults()
  
  // Add comprehensive validation for our Nx workspace
  .useValidation({
    targets: ['lint', 'build'],
    affectedOnly: true,
    bail: true,
    triggerTools: ['Write', 'Edit', 'MultiEdit'],
    triggerExtensions: ['.ts', '.tsx', '.js', '.jsx', '.json', '.md'],
    batchThreshold: 1
  })
  
  // Add session-wide change tracking
  .addHandler(new ChangeTrackerHandler())
  
  // Add custom TypeScript handler for organize-imports and schema detection
  .addHandler(new CustomTypeScriptHandler())
  
  // Add pre-results validation (final quality gate)
  .addHandler(ResultsValidator.standard())
  
  // Custom handler for session context
  .on('SessionStart', async (input) => {
    const projectInfo = `
🎯 Unified Workspace Context:
- Location: ${input.cwd}
- Structure: apps/, libs/, knowledge/, .claude/
- Hook System: TypeScript-based with full type safety
- Commands: nx run claude:build, nx affected:test, nx show projects
- Session ID: ${input.session_id}
    `.trim();
    
    return {
      hookSpecificOutput: {
        hookEventName: 'SessionStart',
        additionalContext: projectInfo
      }
    };
  })
  
  // Enhanced bash command validation
  .on('PreToolUse', async (input) => {
    if (isToolUse(input, 'Bash')) {
      const command = input.tool_input.command;
      
      // Log all bash commands
      console.log(`🔧 Executing: ${command}`);
      
      // Block dangerous patterns
      const dangerousPatterns = [
        /rm\s+-rf\s+\//,
        /sudo\s+rm/,
        />\s*\/dev\/null\s*2>&1.*rm/,
        /find.*-delete/
      ];
      
      for (const pattern of dangerousPatterns) {
        if (pattern.test(command)) {
          return {
            hookSpecificOutput: {
              hookEventName: 'PreToolUse',
              permissionDecision: 'deny',
              permissionDecisionReason: `Dangerous command blocked: ${command}`
            }
          };
        }
      }
    }
    
    return { continue: true };
  })
  
  // User prompt enhancement
  .on('UserPromptSubmit', async (input) => {
    const prompt = input.prompt.toLowerCase();
    let additionalContext = '';
    
    // Add context based on prompt content
    if (prompt.includes('test') && !prompt.includes('nx')) {
      additionalContext += '\n💡 Tip: Use "nx affected -t test" to run only affected tests';
    }
    
    if (prompt.includes('build') && !prompt.includes('nx')) {
      additionalContext += '\n💡 Tip: Use "nx affected -t build" to build only affected projects';
    }
    
    if (prompt.includes('lint') && !prompt.includes('nx')) {
      additionalContext += '\n💡 Tip: Use "nx affected -t lint" to lint only affected code';
    }
    
    if (prompt.includes('hook') || prompt.includes('claude')) {
      additionalContext += '\n📚 Hook system: TypeScript handlers in libs/claude-hooks/ with fluent API';
    }
    
    if (additionalContext) {
      return {
        hookSpecificOutput: {
          hookEventName: 'UserPromptSubmit',
          additionalContext: additionalContext.trim()
        }
      };
    }
    
    return { continue: true };
  })
  
  // Configuration
  .configure({
    debug: process.env.HOOK_DEBUG === '1',
    verbose: process.env.HOOK_VERBOSE === '1',
    stopOnError: true,
    timing: true
  });