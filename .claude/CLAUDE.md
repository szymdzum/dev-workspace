# Unified Developer Workspace 🚀

## Quick Commands
Most Used (because let's be honest):

```bash
nx serve [app]           # Start whatever you're working on
nx affected:test         # Test what you broke
nx run claude:build     # Compile TypeScript hooks
git diff HEAD~          # WTF did I just do?
.claude/scripts/analyze-sessions.sh  # Check your productivity
```

Smart Shortcuts:
- `/comp [name]` - Generate component where you are
- `/fix-imports` - Because imports are always messed up
- `/find [thing]` - Find that thing you swear exists

## 🏗️ Unified Workspace Architecture

```
~/Developer/                 # THE unified workspace
├── .claude/                # Claude configuration
│   ├── hooks/              # TypeScript hook system  
│   ├── runtime/            # Session data (ignored in git)
│   ├── cache/              # Generated files (ignored in git)
│   └── contexts/           # Context files
├── apps/                   # Applications
├── libs/                   # Shared libraries
├── knowledge/              # Obsidian vault + docs
├── nx.json                 # Nx orchestration
└── .git/                   # Single repository
```

## 🎯 Quick Navigation

```bash
cd ~/Developer              # Always start here
ls apps/                    # Your applications
ls libs/                    # Shared libraries  
ls knowledge/               # Your notes & docs
ls .claude/hooks/           # TypeScript hooks
```

### DevOps Stack
- **Monorepo**: Nx (unified workspace management)
- **Package Manager**: pnpm
- **Version Control**: Git (single repository)
- **Hooks**: TypeScript-based Claude automation
- **CI/CD**: GitHub Actions

## 📋 Nx Commands Reference

```bash
# Development
nx serve [app]              # Start dev server
nx build [app]              # Build for production
nx test [project]           # Run tests
nx lint [project]           # Run linting
nx affected:test            # Test affected projects
nx affected:build           # Build affected projects

# Claude Integration
nx run claude:build        # Compile TypeScript hooks
nx run claude:test         # Test hook system
nx show projects            # See all projects (including .claude)

# Generation
nx g @nx/react:lib [name]       # New library
nx g @nx/react:component [name] # New component
```

## 📝 Development Conventions

### Code Style
- TypeScript strict mode enabled
- Functional components preferred
- Composition over inheritance
- Test-first development (TDD)

### Git Workflow
- **Commits**: Conventional commits (feat:, fix:, docs:, chore:)
- **Branches**: feature/*, fix/*, chore/*, hotfix/*
- **PRs**: Required for main branch
- **Reviews**: At least one approval needed

### Naming Conventions
- **Components**: `PascalCase.tsx`
- **Utilities**: `camelCase.ts`
- **Constants**: `UPPER_SNAKE_CASE.ts`
- **Files**: `kebab-case.ts`
- **CSS Classes**: `kebab-case`

## 🔧 Claude Commands

- `/agents` - Manage sub-agents
- `/commands` - List custom commands
- `/mcp` - Configure MCP servers
- `/permissions` - Tool permissions
- `/help` - Show all commands

### Additional contexts available:

Branch: !git branch --show-current 2>/dev/null || echo "not in git"
Modified: !git diff --stat 2>/dev/null | tail -1 || echo "no changes"
Last commit: !git log -1 --oneline 2>/dev/null || echo "no commits"||

- `@contexts/architecture.md` - System architecture
- `@contexts/api.md` - API documentation
- `@contexts/database.md` - Database schema
- `@contexts/serena-ast-powers.md` - TypeScript AST intelligence via Serena
- `@shared/contexts/conventions.md` - Coding standards

## 🔧 Claude Hooks System

TypeScript-based automation that runs on:
- `Write|Edit|MultiEdit|Bash` operations
- **Security Handler**: Blocks hardcoded secrets
- **TypeScript Handler**: Auto-organizes imports, triggers type generation
- **Bash Handler**: Prevents dangerous commands

```bash
# Edit hooks
code .claude/hooks/handlers/

# Rebuild after changes
nx run claude:build

# Debug hooks
echo '{"tool_name":"Write","tool_input":{"file_path":"test.ts"}}' | node .claude/cache/dist/hooks/index.js
```

## 📊 Session Analytics

Track your productivity:

```bash
.claude/scripts/analyze-sessions.sh     # Quick stats
npx tsx .claude/scripts/analyze-sessions.ts  # Detailed analysis
```

## 💡 Tips

1. **Always run Claude from `~/Developer`** - Single workspace context
2. **Use TypeScript hooks** - Type-safe automation with IntelliSense
3. **Analyze your sessions** - Track productivity and common patterns
4. **One git repo** - Everything versioned together
5. **Runtime data preserved** - Rich session history for analysis

Contexts: !find .claude/contexts -name "*.md" 2>/dev/null | wc -l || echo "0"
Sessions: !find .claude/runtime/projects -name "*.jsonl" 2>/dev/null | wc -l || echo "0"

---

🎉 **Unified Workspace Active** - Everything you need in one place!
