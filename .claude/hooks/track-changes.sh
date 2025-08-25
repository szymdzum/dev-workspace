#!/bin/bash
# Change tracking hook - logs file modifications
set -euo pipefail

# Set up environment - get the workspace root, not the .claude directory
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(dirname $(pwd))}"

# For now, use node to run our TypeScript directly (we'll compile later)
exec node -r ts-node/register "$CLAUDE_PROJECT_DIR/.claude/hooks/cli/track-changes.ts"