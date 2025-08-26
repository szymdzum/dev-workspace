
# My Dev Hub

A self-maintaining knowledge system with interesting side effects

Overview
Local-first knowledge repository that syncs, processes, and distributes context automatically. Built with Markdown, Git, and some unconventional automation patterns.

Think of it as:

Local-first: Everything in Markdown files you control
Agent-ready: MCP servers expose your entire codebase structure to AI
Self-updating: Changes trigger automatic cloud syncs
Context-rich: Every agent gets exactly the context it needs, nothing more

```
Your Brain → Markdown → Git → Cloud → Agent Swarm → (profit?)
```

```
dev-hub/
├── knowledge/                # The Markdown Hive Mind
│   ├── architecture/         # System design docs
│   ├── context/              # Agent-specific contexts
│   ├── decisions/            # ADRs that agents actually read
│   └── runbooks/             # Procedures agents can execute
├── apps/
│   ├── web/                  # Remix (because web standards)
│   └── knowledge-syncer/     # Watches Markdown, updates cloud
├── packages/
│   ├── agent-context/        # Context builder for different agent types
│   └── markdown-processor/   # Transforms knowledge for consumption
├── workers/                  # Cloudflare Workers (The Agent Brigade)
│   ├── context-server/       # Serves contextual knowledge
│   ├── agent-router/         # Routes requests to specialized agents
│   └── knowledge-api/        # REST API for knowledge base
└── tools/
    └── mcp-servers/          # MCP servers for AI integration
        ├── nx-mcp/           # Exposes monorepo structure
        └── knowledge-mcp/    # Exposes knowledge base
```

## The Philosophy: Markdown Supremacy
### Why Markdown?

Version controlled (Git tracks every thought)
Human readable (no proprietary formats)
AI parseable (agents love structured text)
Tool agnostic (grep still works in 2025)
Offline first (internet is optional)

## The Cast of Characters

```
📦 @library/source          # The mysterious scoped package nobody talks about
├── 📱 apps/
│   ├── homepage           # Landing page (exists)
│   └── playground         # Where good ideas go to become 47-hour sagas
├── 🧩 libs/
│   ├── claude-hooks       # TypeScript pretending to be shell scripts (Oscar-worthy)
│   ├── claude             # Claude-specific utilities (optimistic naming)
│   ├── knowledge          # Documentation about documentation
│   └── ui                 # Shared components (all 3 of them)
└── 💀 .serena/memories/   # Where past trauma lives in markdown
```

## Quick Start (For the Brave)

```bash
# Install dependencies (and pray Node 24 doesn't break them)
pnpm install

# Run the playground (where dreams become nightmares)
pnpm playground

# Build everything (coffee break recommended)
pnpm build:all

# Run tests (spoiler: they pass)
pnpm test

# Check the dependency graph (it works now, stop asking)
nx graph
```

## The Stack (A Love Story)

- **Node.js v24.6.0** - Living so far in the future, we need flux capacitors
- **Nx 21.4.1** - The monorepo tool we're actually paying for but not fully using
- **pnpm** - Because npm was too mainstream
- **TypeScript 5.8.2** - Type safety everywhere except in our shell scripts
- **React 19.1.1** - Yes, 19. We don't do "stable" here
- **Vite 6.0.0** - Fast enough to make webpack cry
- **Jest 30.0.2** - Testing our patience since 2024

### 🏎️ Performance Optimizations (TODO)

We have NX Cloud (`ID: 68a9ddc018c0c0003e9f5636`) but haven't configured:
- ❌ Local caching (it's FREE, what are we doing?)
- ❌ Affected commands (running ALL tests like animals)
- ❌ DTE (Distributed Task Execution)
- ❌ TypeScript batch mode (5x faster compilation sitting there, menacingly)

*It's like owning a Ferrari and pushing it to work.*

## Development Workflows

### The "It Actually Works" Commands

```bash
# Format code (the ONLY way)
uv run poe format

# Type check (find problems before runtime)
uv run poe type-check

# Test (with markers for the sophisticated)
uv run poe test -m "python or go"  # Pick your poison
```

### The "I Live Dangerously" Commands

```bash
# Update all dependencies on Node 24
pnpm update --latest  # YOLO

# Clean everything and pray
rm -rf node_modules .nx tmp
pnpm install
nx reset

# Run with performance profiling
NX_PERF_LOGGING=true nx build playground
```

## Documentation (Yes, We Have THREE Systems)

1. **`.serena/memories/`** - Where Serena remembers our sins
   - `claude_hooks_epic_saga.md` - The 47-hour journey
   - `sane_hooks_architecture.md` - What we should've built (47 minutes)
   - `monorepo_architecture.md` - Claims about broken things that work fine

2. **`CLAUDE.md`** - What Claude Code actually reads
   - The ACTUAL memory system
   - We spent hours not knowing this

3. **This README** - You are here (unfortunately)

## Known Issues (Features)

- **Node 24** breaks random packages (character building)
- **nx daemon** occasionally has trust issues (therapy pending)
- **@library/source** nobody knows what this is (including me)
- **Two hook architectures** exist simultaneously (Schrödinger's code)
- **Cache not configured** while paying for NX Cloud (financial masochism)

## The Uncomfortable Truth Section

You're sitting on a goldmine of unimplemented optimizations:

# TypeScript batch mode for 5x compilation speed
echo "enableBatchMode=true" >> .nx/config

```sh
# Step 1: The 30-Second Cache Fix (DO THIS NOW)
cat >> nx.json << 'EOF'
  "tasksRunnerOptions": {
    "default": {
      "runner": "@nx/cloud",
      "options": {
        "cacheableOperations": ["build", "test", "lint"],
        "accessToken": "YOUR_TOKEN_HERE"
      }
    }
  }
EOF

# Step 2: Test if you're actually caching (spoiler: you're not)
nx run-many --target=build --all --skip-nx-cache
time nx run-many --target=build --all  # Should be INSTANT

# Step 3: The "Why is @library/source mysterious?" investigation
nx graph --focus @library/source
```

```javascript
// What we have
const setup = {
  nodeVersion: "24.6.0",     // Bleeding edge
  nxCloud: "connected",       // Paying for it
  caching: "not configured",  // FREE performance ignored
  hooks: "two architectures", // Peak overengineering
  roi: "negative"            // Time is money, friend
};

// What we could have
const optimized = {
  cacheHitRate: "80%",       // Build once, use everywhere
  ciTime: "50% reduction",   // Half the time, twice the smugness
  buildSpeed: "5x faster",   // TypeScript batch mode
  developerJoy: "420.69%"    // Scientifically measured
};
```

## Contributing

1. **Pick a Node version** (hint: maybe not 24?)
2. **Choose ONE hook architecture** (delete the other, nobody will know)
3. **Configure caching** (it's literally free performance)
4. **Document your journey** (add to our trauma collection)

### Acceptance Criteria for PRs

- [ ] Works on Node 24 (somehow)
- [ ] Has more documentation than code
- [ ] Includes at least one existential crisis
- [ ] ROI calculation must be "Priceless™"

## Success Metrics

- **Cache hit rate**: Currently 0%, target: not 0%
- **Build time**: Yes
- **Test coverage**: Exists
- **Documentation-to-code ratio**: 3:1 (industry-leading)
- **Developer sanity**: 404 Not Found

## Quick Wins (Stop Reading, Start Doing)

```bash
# 1. Enable caching (30 seconds, massive impact)
echo 'cache: true' >> nx.json

# 2. Use affected commands (stop testing everything)
nx affected:test --base=main

# 3. Fix Node version in package.json (be honest)
echo '"engines": { "node": ">=24.0.0" }' >> package.json

# 4. Delete one hook architecture (you know which one)
rm -rf the-47-hour-one  # (just kidding, frame it)
```

## License

MIT (Massively Inefficient Time-management)

## Support

- **Issues**: Open one, we have time (apparently)
- **Questions**: Check `.serena/memories/`, it's all there
- **Therapy**: Not included but recommended

---

*Built with 💀 and Node 24 by someone who thinks LTS stands for "Lacking The Spirit"*

*P.S. - If you're reading this and thinking "this could be optimized," you're right. The queue starts behind the 47-hour hook saga.*

*P.P.S. - Yes, we know about the caching. Yes, we're paying for NX Cloud. No, we haven't configured it. It's called "technical debt" and it's a lifestyle choice.*