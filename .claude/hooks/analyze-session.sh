#!/bin/bash
# Session analysis hook - generates analytics reports
set -euo pipefail

# Set up environment - get the workspace root, not the .claude directory
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(dirname $(pwd))}"

# For now, use node to run our TypeScript directly (we'll compile later)
exec node -r ts-node/register "$CLAUDE_PROJECT_DIR/.claude/hooks/cli/analyze-session.ts"