#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Save Snippet from Clipboard
# @raycast.mode compact
# @raycast.packageName Knowledge Vault

# Optional parameters:
# @raycast.icon 💾
# @raycast.argument1 { "type": "text", "placeholder": "Snippet name" }
# @raycast.argument2 { "type": "text", "placeholder": "File extension (js, py, etc.)", "optional": true }

# Documentation:
# @raycast.description Save clipboard content as a snippet in Knowledge vault
# @raycast.author Szymon Dzumak
# @raycast.authorURL https://github.com/szymondzumak

KNOWLEDGE_BASE="$HOME/Developer/Knowledge"
INBOX_DIR="$KNOWLEDGE_BASE/Inbox"

# Get arguments
TITLE="$1"
EXT="${2:-md}"

if [ -z "$TITLE" ]; then
    echo "❌ Please provide a snippet name"
    exit 1
fi

# Create inbox directory if it doesn't exist
mkdir -p "$INBOX_DIR"

# Slugify the title
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')

# Create filename with timestamp to avoid conflicts
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
FILENAME="${SLUG}-${TIMESTAMP}.${EXT}"
FILEPATH="$INBOX_DIR/$FILENAME"

# Get clipboard content
CONTENT=$(pbpaste)

if [ -z "$CONTENT" ]; then
    echo "❌ Clipboard is empty"
    exit 1
fi

# Add frontmatter for markdown files
if [ "$EXT" = "md" ]; then
    cat > "$FILEPATH" << EOF
---
type: resource
category: snippet
created: $(date +%Y-%m-%d)
tags: [snippet, inbox]
title: $TITLE
---

# $TITLE

$CONTENT
EOF
else
    # For code files, just save the content
    echo "$CONTENT" > "$FILEPATH"
fi

echo "✅ Saved to Inbox: $FILENAME"
echo "📝 Remember to process and move from Inbox!"
