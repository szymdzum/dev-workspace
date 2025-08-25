#!/bin/bash

# Session Analysis Script for Claude Data
# Analyzes session transcripts and todo lists to generate insights

RUNTIME_DIR="$(dirname "$0")/../runtime"
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Claude Session Analysis${NC}"
echo "================================"

# Check if runtime directory exists
if [[ ! -d "$RUNTIME_DIR" ]]; then
    echo -e "${RED}Error: Runtime directory not found at $RUNTIME_DIR${NC}"
    exit 1
fi

# Count sessions
SESSIONS=$(find "$RUNTIME_DIR/projects" -name "*.jsonl" 2>/dev/null | wc -l)
echo -e "${GREEN}📊 Found $SESSIONS session files${NC}"

# Analyze session transcripts
echo -e "\n${BLUE}📈 Session Statistics:${NC}"

# Count total messages
TOTAL_MESSAGES=0
if [[ -d "$RUNTIME_DIR/projects" ]]; then
    while IFS= read -r -d '' file; do
        COUNT=$(wc -l < "$file" 2>/dev/null || echo 0)
        TOTAL_MESSAGES=$((TOTAL_MESSAGES + COUNT))
    done < <(find "$RUNTIME_DIR/projects" -name "*.jsonl" -print0 2>/dev/null)
fi

echo "  💬 Total Messages: $TOTAL_MESSAGES"

# Analyze todos
if [[ -d "$RUNTIME_DIR/todos" ]]; then
    TODO_FILES=$(find "$RUNTIME_DIR/todos" -name "*.json" 2>/dev/null | wc -l)
    echo "  📋 Todo Lists: $TODO_FILES"
    
    # Count completed tasks
    COMPLETED_TASKS=0
    if ls "$RUNTIME_DIR/todos"/*.json >/dev/null 2>&1; then
        for file in "$RUNTIME_DIR/todos"/*.json; do
            [[ -f "$file" ]] || continue
            COUNT=$(grep -c '"status".*"completed"' "$file" 2>/dev/null || echo "0")
            COMPLETED_TASKS=$((COMPLETED_TASKS + COUNT))
        done
    fi
    
    echo "  ✅ Completed Tasks: $COMPLETED_TASKS"
    
    if [[ $TODO_FILES -gt 0 ]]; then
        AVG_TASKS=$((COMPLETED_TASKS / TODO_FILES))
        echo "  📊 Avg Tasks/Session: $AVG_TASKS"
    fi
fi

# Check disk usage
echo -e "\n${YELLOW}💾 Storage Usage:${NC}"
if command -v du >/dev/null 2>&1; then
    du -sh "$RUNTIME_DIR"/* 2>/dev/null | while read size dir; do
        dirname=$(basename "$dir")
        echo "  $dirname: $size"
    done
fi

# Quick topic analysis from recent sessions
echo -e "\n${BLUE}🔍 Recent Activity Topics:${NC}"
if [[ -d "$RUNTIME_DIR/projects" ]]; then
    # Get the most recent session file
    RECENT_SESSION=$(find "$RUNTIME_DIR/projects" -name "*.jsonl" -exec ls -t {} + | head -1 2>/dev/null)
    
    if [[ -n "$RECENT_SESSION" ]]; then
        echo "  📝 Analyzing: $(basename "$RECENT_SESSION")"
        
        # Extract common development keywords
        KEYWORDS=("typescript" "javascript" "react" "build" "test" "fix" "component" "api" "config")
        
        for keyword in "${KEYWORDS[@]}"; do
            COUNT=$(grep -i "$keyword" "$RECENT_SESSION" 2>/dev/null | wc -l)
            if [[ $COUNT -gt 0 ]]; then
                echo "    - $keyword: mentioned $COUNT times"
            fi
        done
    fi
fi

echo -e "\n${GREEN}✨ Analysis complete!${NC}"
echo -e "Runtime data stored in: ${RUNTIME_DIR}"
echo -e "Use ${BLUE}npx tsx .claude/scripts/analyze-sessions.ts${NC} for detailed analysis"