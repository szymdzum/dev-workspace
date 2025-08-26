# Developer Workspace

A modern development environment built with Nx monorepo, focusing on performance and developer experience.

## Quick Start

```bash
pnpm install
pnpm dev
```

## Stack

- **Nx** - Intelligent build system with caching
- **Vitest** - Fast testing (3-20x faster than Jest)  
- **Biome** - Ultra-fast linting & formatting
- **TypeScript** - Full type safety
- **Astro + React** - Modern web components

## Projects

- `apps/playground` - Demo application
- `libs/ui` - Shared component library
- `knowledge/` - Documentation

## Key Commands

```bash
# Development
pnpm dev                    # Start dev servers
nx serve playground         # Serve specific app

# Build & Test  
nx run-many -t build        # Build all
nx run-many -t test         # Test all
nx affected:build           # Build changed only
nx affected:test            # Test changed only

# Code Quality
pnpm run lint               # Lint everything
```

## Benefits

- **Smart Caching** - Only rebuilds what changed
- **Fast Feedback** - Instant linting and testing
- **Type Safety** - TypeScript throughout
- **Modern Tooling** - Latest generation dev tools

Built for rapid experimentation with solid foundations.