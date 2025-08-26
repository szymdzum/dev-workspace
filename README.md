# My Dev Hub

> *A self-maintaining knowledge system with interesting side effects*

## Overview

Local-first knowledge repository that syncs, processes, and distributes context automatically. Built with Markdown, Git, and some unconventional automation patterns.

## Architecture

```
my-dev-hub/
├── knowledge/          # Version-controlled markdown
├── apps/              # Web interfaces
├── workers/           # Edge compute units  
├── tools/             # Orchestration layer
└── .claude/           # Configuration
```

## Core Concepts

### Knowledge Layers
The system operates on three distinct processing tiers:
- **Layer 0**: Information retrieval and aggregation
- **Layer 2**: Analysis and implementation
- **Layer 5**: Architectural decisions

Each layer has different resource allocations and operational constraints.

### Context Distribution
Context flows through specialized pipelines based on task complexity. Simple queries stay lightweight, complex ones get routed appropriately.

### Temporal Constraints
```python
# Certain operations have time-based restrictions
if friday_afternoon():
    max_operations = 'read_only'
```

## Configuration

```json
{
  "processing_tiers": {
    "basic": { "cost": 0.0001, "capabilities": ["read", "fetch"] },
    "standard": { "cost": 0.003, "capabilities": ["write", "analyze"] },
    "premium": { "cost": 0.015, "capabilities": ["architect", "design"] }
  },
  "routing": "cost_optimized"
}
```

## Usage

```bash
# Initialize
pnpm install
pnpm exec nx serve knowledge-sync

# The rest is automatic
```

### Task Routing

Tasks are classified and routed based on complexity signatures:
- Documentation requests → Tier 0
- Implementation tasks → Tier 2  
- System design → Tier 5

The router optimizes for cost while maintaining quality thresholds.

## Implementation Notes

### Profile Management
Different operational profiles for different contexts. Each profile has specific access patterns and resource limits.

### State Persistence
Thread-specific state maintained in `~/.claude/roles-state.json` with automatic expiration and cleanup.

### Audit Trail
All operations logged to Markdown for grep-ability and accountability.

## Experiments

Currently testing:
- Multi-tier task delegation patterns
- Cost-optimized routing algorithms
- Self-updating documentation workflows
- Automated context generation

## Performance Targets

- Context retrieval: <100ms
- Task classification: <50ms
- Documentation sync: Real-time
- Cost per operation: Variable ($0.0001 - $0.50)

## Design Decisions

1. **Markdown only**: Text files survive everything
2. **Git-backed**: Every change tracked
3. **Local-first**: Your data, your rules
4. **Cost-aware**: Resources aren't free
5. **Time-boxed**: Some operations expire

## Known Constraints

- Higher tiers have shorter timeouts (power corrupts)
- Friday afternoon restrictions apply
- Certain commands permanently locked to specific tiers
- Thread isolation prevents cross-contamination

## Future Work

- [ ] Autonomous documentation updates
- [ ] Self-organizing knowledge graphs
- [ ] Predictive context routing
- [ ] Resource usage optimization

---

*Those who need to know, know what this really does.*