#!/bin/bash
# Simple security test hook without dependencies
set -euo pipefail

# Read JSON from stdin
input=$(cat)

# Extract content using jq (if available) or basic parsing
if command -v jq >/dev/null 2>&1; then
    content=$(echo "$input" | jq -r '.tool_input.content // ""')
    file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')
    tool_name=$(echo "$input" | jq -r '.tool_name // ""')
else
    # Basic extraction without jq
    content=$(echo "$input" | sed -n 's/.*"content":"\([^"]*\)".*/\1/p')
    file_path=$(echo "$input" | sed -n 's/.*"file_path":"\([^"]*\)".*/\1/p')
fi

# Check for common secrets patterns
if [[ "$content" =~ sk-[a-zA-Z0-9]{48} ]]; then
    echo '{"continue":false,"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"OpenAI API key detected in code. Use environment variables instead."}}'
    exit 0
fi

if [[ "$content" =~ ghp_[a-zA-Z0-9]{36} ]]; then
    echo '{"continue":false,"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"GitHub token detected in code. Use environment variables instead."}}'
    exit 0
fi

if [[ "$content" =~ (password|secret|key).*[:=].*[\"\\047][^\"\\047]{8,} ]]; then
    echo '{"continue":false,"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"Hardcoded credential detected. Use secure configuration instead."}}'
    exit 0
fi

# All checks passed
echo '{"continue":true}'
exit 0