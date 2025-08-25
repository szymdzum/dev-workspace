# Developer Hub
Branch: !`git branch --show-current 2>/dev/null || echo "main"`
Changes: !`git diff --stat 2>/dev/null | tail -1 || echo "clean"`

## Problems
!`cat .ai/.problems.md 2>/dev/null || echo "None"`

## Context
@.ai/.claude/base-config.md

<!-- Dynamic imports based on location -->
@.ai/.claude/contexts/current.md

## Commands
- `/comp [name]` - New component
- `/fix-imports` - Fix imports
- `nx affected:test` - Test changes
