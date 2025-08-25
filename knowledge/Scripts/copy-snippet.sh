#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Copy Snippet
# @raycast.mode inline
# @raycast.packageName Knowledge Vault

# Optional parameters:
# @raycast.icon 🚀
# @raycast.argument1 { "type": "text", "placeholder": "Snippet name or keyword" }

# Documentation:
# @raycast.description Quickly copy a snippet to clipboard
# @raycast.author Szymon Dzumak
# @raycast.authorURL https://github.com/szymondzumak

# Configuration
KNOWLEDGE_BASE="$HOME/Developer/Knowledge"
SNIPPETS_DIR="$KNOWLEDGE_BASE/Resources/Snippets"
PATTERNS_DIR="$KNOWLEDGE_BASE/Resources/Patterns"

SEARCH_QUERY="$1"

if [ -z "$SEARCH_QUERY" ]; then
    echo "Please provide a search term"
    exit 1
fi

# Search for the first matching file
found_file=$(find "$SNIPPETS_DIR" "$PATTERNS_DIR" -type f \( -name "*${SEARCH_QUERY}*" -o -exec grep -l -i "$SEARCH_QUERY" {} \; \) 2>/dev/null | head -1)

if [ -n "$found_file" ]; then
    # Copy content without frontmatter
    if head -n 1 "$found_file" | grep -q "^---$"; then
        content_start=$(awk '/^---$/ { if (++n == 2) { print NR + 1; exit } }' "$found_file")
        tail -n +$content_start "$found_file" | pbcopy
    else
        cat "$found_file" | pbcopy
    fi
    
    echo "✅ Copied: $(basename "$found_file")"
else
    echo "❌ No snippet found for: $SEARCH_QUERY"
fi
