# Developer Hub Context Router


🚀 Quick Commands
Most Used (because let's be honest):

nx serve - Start whatever you're in
nx affected:test - Test what you broke
git diff HEAD~ - WTF did I just do?

Smart Shortcuts:

/comp [name] - Generate component where you are
/fix-imports - Because imports are always fucked
/find [thing] - Find that thing you swear exists

## 🏗️ Workspace Architecture

```
~/Developer/
├── .ai/             # `cd ~/Developer/.ai` AI configurations
│   ├── .claude/     # Claude settings
├── Library/         # `cd ~/Developer/Library/` Nx monorepo
│   ├── apps/        # Applications
│   └── libs/        # Shared libraries
├── Knowledge/       # `cd ~/Developer/Knowledge`
│   ├── Projects/    # Project documentation
│   └── Scripts/     # Automation scripts
└── README.md        # Workspace documentation
```

## 🎯 Quick Navigation

```bash
cd ~/Developer/.ai
cd ~/Developer/Library/apps    # Applications
cd ~/Developer/Library/libs    # Libraries
cd ~/Developer/Knowledge       # Documentation
```

### DevOps
- **Monorepo**: Nx
- **Package Manager**: pnpm
- **Version Control**: Git
- **CI/CD**: GitHub Actions

## 📋 Nx Commands Reference

```bash
# Development
nx serve [app]          # Start dev server
nx build [app]          # Build for production
nx test [project]       # Run tests
nx lint [project]       # Run linting
nx affected:test        # Test affected projects
nx affected:build       # Build affected projects

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

## 💡 Tips

1. Always run Claude from `~/Developer` for consistent context
2. Update this file with project-specific information
3. Use context modules for detailed documentation
4. Commit changes to git regularly

Contexts loaded: !find .ai/.claude/contexts -name "*.md" 2>/dev/null | wc -l || echo "0"
Approximate tokens: !find .ai/.claude -name "*.md" -exec cat {} \; 2>/dev/null | wc -w || echo "unknown"

---

*Pro tip: Edit this file with `claude-edit` alias*
