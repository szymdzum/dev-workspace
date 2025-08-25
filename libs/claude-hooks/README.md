# @claude-dev/hooks

A TypeScript-based hook system for Claude Code automation. This library provides a framework for creating intelligent hooks that can validate, transform, and enhance your development workflow.

## Features

- 🔒 **Security validation** - Prevent hardcoded secrets and dangerous commands
- 🔧 **TypeScript integration** - Auto-organize imports and run type checks  
- 🎯 **Extensible framework** - Easy to create custom handlers
- 🐛 **Debug support** - Built-in debug and verbose logging
- ⚡ **Performance** - Efficient hook execution with proper error handling

## Installation

```bash
npm install @claude-dev/hooks
# or
pnpm add @claude-dev/hooks
# or  
yarn add @claude-dev/hooks
```

## Quick Start

```typescript
import { HookSystem, SecurityHandler, BashHandler } from '@claude-dev/hooks';

// Configure your hooks
const config = {
  enabled: true,
  debug: false,
  verbose: false,
  handlers: {
    'Write': ['security'],
    'Bash': ['bash', 'security']
  },
  fileHandlers: {
    'ts': ['typescript'],
    'js': ['typescript']
  }
};

// Set up handlers
const hookSystem = new HookSystem(config, {
  'security': new SecurityHandler(),
  'bash': new BashHandler()
});

// Process hook input
await hookSystem.process({
  session_id: 'test',
  transcript_path: '/tmp',
  cwd: '/tmp', 
  hook_event_name: 'PreToolUse',
  tool_name: 'Write',
  tool_input: {
    file_path: 'config.ts',
    content: 'const apiKey = "secret-key"'
  }
});
```

## Creating Custom Handlers

```typescript
import { BaseHandler, HookInput, HandlerResult } from '@claude-dev/hooks';

export class MyCustomHandler extends BaseHandler {
  async handle(input: HookInput): Promise<HandlerResult> {
    this.debug('Processing custom logic...');
    
    // Your validation/transformation logic here
    if (someCondition) {
      return this.fail('Custom validation failed');
    }
    
    return this.success('Custom handler completed');
  }
}
```

## Built-in Handlers

### SecurityHandler
- Detects hardcoded secrets (API keys, passwords, tokens)
- Warns about sensitive file operations
- Configurable secret patterns

### BashHandler  
- Blocks dangerous commands (`rm -rf /`, etc.)
- Warns about potentially destructive operations
- Command audit logging

### TypeScriptHandler (Example)
- Auto-organizes imports
- Triggers type checking for schema files
- File type validation

## Debug Mode

Enable debug logging:

```bash
HOOK_DEBUG=1 node your-app.js
HOOK_VERBOSE=1 HOOK_DEBUG=1 node your-app.js  # More detailed output
```

## Development

This library was built with [Nx](https://nx.dev).

### Building
```bash
nx build claude-hooks
```

### Testing  
```bash
nx test claude-hooks
```

### Linting
```bash
nx lint claude-hooks
```

## License

MIT
