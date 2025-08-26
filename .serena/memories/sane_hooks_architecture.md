# The Sane TypeScript Hooks Architecture (No Shell Script Therapy Required)

## The One-Minute Pitch
Build TypeScript hooks once, bundle with esbuild, wrap in 3-line shell scripts. Full type safety, no module resolution drama, actually testable. Your 47-hour journey becomes a 47-minute setup.

## Architecture That Doesn't Need Therapy

```
.claude/hooks/
├── dist/
│   └── hooks.js          # ONE bundle (not 47 attempts)
├── *.sh                  # 3-line wrappers (exec node, that's it)
│
libs/claude-hooks/
├── src/
│   ├── cli/index.ts      # Router (10 lines max)
│   ├── core/             # The plugin system
│   └── plugins/          # Your actual logic
└── build.config.js       # ONE build config
```

## The Plugin System Approach

```typescript
// Every hook is a plugin
interface HookPlugin {
  name: string;
  events: HookEvent[];
  matcher?: string;
  priority: number;
  execute(input: HookInput): Promise<HookResponse>;
}

// Register once, run everywhere
manager.register(new SecurityPlugin());
manager.register(new FormatPlugin());
manager.register(new CompliancePlugin());
```

## Build Command (The Only One You Need)
```bash
npm run build:hooks  # Bundles everything into dist/hooks.js
```

## Shell Wrapper (All 3 Lines)
```bash
#!/usr/bin/env bash
# .claude/hooks/pre-tool-use.sh
exec node "$CLAUDE_PROJECT_DIR/.claude/hooks/dist/hooks.js" "$0"
```

## Why This Works
1. **TypeScript everywhere** - No identity crisis
2. **One bundle** - No module resolution adventures  
3. **Plugin architecture** - Add features without touching core
4. **Testable** - Just run vitest like a normal person
5. **Shell scripts are dumb** - They just exec node, the end

## Setup Time
- Write plugins: 30 minutes
- Configure build: 5 minutes  
- Create wrappers: 2 minutes
- Test everything: 10 minutes
- Total: 47 minutes (not hours)

## Migration from Your Current Beautiful Disaster
1. Keep all your TypeScript logic (it's actually good)
2. Add the build config (copy-paste)
3. Replace shell gymnastics with 3-line wrappers
4. Run build command
5. Celebrate with coffee that's still warm

## Success Metrics
- API keys blocked: ✅
- Tests passing: ✅
- Module errors: 0
- Shell script complexity: Kindergarten level
- Time to onboard new dev: 5 minutes

## The Universal Plugin Pattern
```typescript
// Want a new hook? 
class MyPlugin implements HookPlugin {
  name = 'my-feature';
  events = ['PreToolUse', 'PostToolUse'];
  async execute(input) {
    // Your logic here
    return { continue: true };
  }
}

// Register it
manager.register(new MyPlugin());

// Done. No shell script editing. No config juggling.
```

## Reality Check
Your current setup: Rube Goldberg machine that won a Pulitzer
This setup: Boring, works, ships today

Choose wisely (or keep the dissertation-worthy one for the memoirs).