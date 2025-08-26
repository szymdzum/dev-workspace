# Developer Monorepo Architecture

## Quick Reference
- **Type**: nx monorepo with pnpm workspaces
- **Node Issue**: Running v17.0.0, needs v18.12+ (causing pnpm tantrums)
- **Package Manager**: pnpm (when it's not having a version crisis)

## Projects Structure
```
📦 Developer/
├── 📱 apps/
│   ├── homepage      (landing page app)
│   └── playground    (experimental zone)
├── 📚 libs/
│   ├── claude-hooks  (TypeScript library for Claude Code hooks)
│   ├── ui           (shared UI components)
│   ├── knowledge    (documentation/knowledge management)
│   └── claude       (Claude-specific utilities)
└── 🛠️ @library/source (scoped package - needs investigation)
```

## Claude-Hooks Library Highlights
- Full TypeScript implementation of Claude Code hook system
- Includes HookSystem class with:
  - Debug/verbose logging modes
  - Handler chaining and async processing
  - Type-safe BaseHandler abstractions
  - Security handlers (validation, change-tracking)
  - Integration tests

## nx Commands Available
- `npx nx graph` - Dependency graph visualization (currently broken due to daemon issues)
- `npx nx show projects` - List all projects
- `npx nx list` - Show installed plugins
- `npx nx affected` - Show affected projects by changes

## ~~Critical~~ SOLVED Issues (We're Drama Queens)
1. **Node Version**: Running v24.6.0 (so bleeding edge we need bandages)
2. **nx graph**: WORKS PERFECTLY - Past me was having a moment 🎭
   - Renders beautiful dependency arrows
   - Shows all 5 libs without crying
   - Even handles our 47-hour claude-hooks saga with grace

## Tech Stack
- React + Vite (fast builds)
- Jest (testing)
- Storybook (component development)
- ESLint (code quality)
- TypeScript (everywhere)

## ~~Fix Priority~~ Victory Lap
1. ✅ Node.js: We YOLO'd to v24.6.0 (who needs LTS?)
2. ✅ nx graph: Working like it owes us money
3. 🎯 New Priority: Optimize this beast with NX superpowers
