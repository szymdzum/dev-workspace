## Unified Workspace Structure

```
~/Developer/                 # Single unified workspace
├── .claude/                # Claude configuration & TypeScript hooks
│   ├── hooks/              # Intelligent automation system
│   ├── runtime/            # Session data & analytics  
│   └── contexts/           # Context files
├── apps/                   # All applications
├── libs/                   # Shared libraries & components
├── knowledge/              # Obsidian vault & documentation
└── .git/                   # Single repository for everything
```

## Workspace Features

✅ **Unified Development** - Everything in one place, one git repo  
✅ **TypeScript Hooks** - Intelligent automation with full type safety  
✅ **Nx Integration** - `nx run claude:build`, `nx affected:test`  
✅ **Session Analytics** - Track productivity with `.claude/scripts/`  
✅ **Clean Organization** - Runtime data separated from core config  

## Key Commands

```bash
nx run claude:build        # Compile TypeScript hooks
.claude/scripts/analyze-sessions.sh  # Check session insights
nx show projects            # See all projects (apps, libs, claude, knowledge)
```

## Hook System

The TypeScript-based hook system provides:
- **Security validation** - Prevents hardcoded secrets
- **Auto-organization** - Manages imports, triggers type generation  
- **Safety checks** - Blocks dangerous bash commands
- **Full type safety** - IntelliSense support for hook development

## Context Loading
- All contexts now loaded from `.claude/contexts/`
- Session data preserved in `.claude/runtime/` for analysis
- Clean separation of config vs runtime data
