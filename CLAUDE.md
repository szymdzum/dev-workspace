## Unified Workspace Structure

```
~/Developer/                # Single  workspace
├── .claude/                # Claude configuration
│   ├── runtime/            # Session data & analytics
│   └── contexts/           # Context files
├── apps/                   # All applications
├── libs/                   # Shared libraries
├── knowledge/              # Obsidian vault & documentation
└── .git/                   # Single repository
```

always use `pnpm nx <command>`

pnpm test          # Run tests
pnpm test:watch    # Watch mode
pnpm test:ui       # Visual UI
pnpm lint          # Check code quality
pnpm format        # Auto-format code
pnpm check         # Full check (lint + typecheck)


  Biome Commands

  # Core commands
  pnpm lint              # Check all issues
  pnpm lint:fix          # Auto-fix safe issues
  pnpm format            # Format all files
  pnpm check             # Lint + typecheck together

  # Biome direct commands
  pnpm biome check .                    # Check everything
  pnpm biome check --write .           # Fix safe issues
  pnpm biome check --write --unsafe .  # Fix all issues (be
  careful!)
  pnpm biome format --write .          # Format only

  Vitest Commands

  # Basic test commands
  pnpm test              # Run all tests once
  pnpm test:watch        # Watch mode (reruns on changes)
  pnpm test:ui           # Visual test interface (browser)
  pnpm test:coverage     # Generate coverage reports

  # Vitest direct commands
  pnpm vitest run                      # Run once
  pnpm vitest --run libs/ui            # Test specific project
  pnpm vitest --reporter=verbose       # Detailed output

  // What your AI can now do (without you copy-pasting)
const aiSuperpowers = {
  nx_workspace: "Sees your entire project graph",
  nx_project_details: "Knows every project's config",
  nx_generators: "Can scaffold code properly",
  nx_current_running_tasks: "Reads your terminal output",
  nx_visualize_graph: "Shows dependency diagrams",
  nx_docs: "Actually reads documentation (wild)"
};



 Biome Configuration

  ✅ Performance Rules: noAccumulatingSpread, noDelete✅ Code
  Quality: Node.js import protocol enforcement, template
  literals✅ Modern JavaScript: Arrow functions, const usage✅
  React Best Practices: No array index keys, button types✅ File
  Size Limits: 1MB max for performance✅ Smart Formatting: Single
   quotes, minimal semicolons

  Enhanced Vitest Configuration Features:

  ✅ Full React Testing Library: Component testing ready✅
  Coverage Thresholds: 70% minimum across all metrics✅ Global
  Test Helpers: describe, it, expect without imports✅ Browser
  Mocking: matchMedia, IntersectionObserver, ResizeObserver✅
  Path Aliases: @ui, @playground for clean imports✅ Performance
  Optimized: Parallel execution, proper timeouts

  ☁️ Cloudflare Deployment: Perfect Choice!

  Why Cloudflare is excellent for your stack:

  ✅ Astro + React Support

  - Native Astro support with SSR/SSG flexibility
  - React components work perfectly in Astro
  - Zero configuration for static assets

  ✅ Performance Benefits

  - Global Edge Network: Sub-100ms response times
  - Automatic Scaling: Handle traffic spikes effortlessly
  - Built-in CDN: Static assets cached globally

  ✅ Modern Developer Experience

  - Wrangler CLI: Local development matches production
  - Hot Reloading: Vite dev server in Workers runtime
  - Type Safety: Full TypeScript support

  ✅ 2025 Recommendations

  - Use Cloudflare Workers (not Pages) for new projects
  - All future features/optimizations focused on Workers
  - Full-stack capabilities in single deployment

  🔧 New Commands Available:

  # Enhanced testing
  pnpm test:coverage      # Generate coverage reports (70%
  threshold)
  pnpm test:ui           # Visual test interface
  pnpm test:affected     # Only test changed projects

  # Advanced linting
  pnpm biome check --write --unsafe  # Fix all issues (be
  careful!)
  pnpm lint:affected                 # Only lint changed projects

  # Cloudflare deployment (when ready)
  cd apps/playground && wrangler deploy

  Your setup is now production-ready with modern tooling,
  comprehensive testing, and optimized for Cloudflare deployment!
   🚀