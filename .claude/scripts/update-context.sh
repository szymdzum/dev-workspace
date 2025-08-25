#!/bin/bash
# .ai/.claude/scripts/update-context.sh
# Runs on session start to prep the context

cd "$CLAUDE_PROJECT_DIR" || exit

# Clear old problems
> .ai/.problems.md

# Log current state
echo "Session started: $(date)" > .ai/.session.log
echo "Branch: $(git branch --show-current 2>/dev/null || echo 'no-git')" >> .ai/.session.log
echo "Location: $(pwd)" >> .ai/.session.log

# Check for obvious problems
if [ -f "package-lock.json" ] && [ -f "yarn.lock" ]; then
    echo "⚠️ Both package-lock.json and yarn.lock exist" >> .ai/.problems.md
fi

if git diff --check 2>/dev/null | grep -q "trailing whitespace"; then
    echo "⚠️ Trailing whitespace in staged files" >> .ai/.problems.md
fi

# Check Claude Code docs optimization status
if [ -d "Knowledge/Docs/claude-code" ]; then
    echo "📚 Claude Code docs available (optimized extractor ready)" >> .ai/.session.log
    
    # Verify key files exist and are optimized
    doc_files=(
        "Knowledge/Docs/claude-code/README.md"
        "Knowledge/Docs/claude-code/getting-started.md"
        "Knowledge/Docs/claude-code/hooks.md"
        "Knowledge/Docs/claude-code/mcp.md"
        "Knowledge/Docs/claude-code/memory.md"
        "Knowledge/Docs/claude-code/settings.md"
        "Knowledge/Docs/claude-code/slash-commands.md"
        "Knowledge/Docs/claude-code/subagents.md"
    )
    
    missing_files=0
    for file in "${doc_files[@]}"; do
        if [ ! -f "$file" ]; then
            echo "⚠️ Missing optimized doc: $file" >> .ai/.problems.md
            ((missing_files++))
        fi
    done
    
    # Check if optimized extractor exists
    if [ -f "Knowledge/Scripts/claude-docs-extractor/extract-optimized.js" ]; then
        echo "🚀 Optimized extractor available (produces clean docs automatically)" >> .ai/.session.log
    fi
    
    if [ $missing_files -eq 0 ]; then
        echo "✅ All Claude Code docs present" >> .ai/.session.log
    fi
fi

# Check if we're in a known state
if [[ $(pwd) == *"/Library/apps/"* ]]; then
    echo "Frontend context active" >> .ai/.session.log
elif [[ $(pwd) == *"/Library/libs/"* ]]; then
    echo "Library context active" >> .ai/.session.log
fi

exit 0
