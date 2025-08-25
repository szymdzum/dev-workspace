#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Search Snippets
# @raycast.mode fullOutput
# @raycast.packageName Knowledge Vault

# Optional parameters:
# @raycast.icon 📋
# @raycast.argument1 { "type": "text", "placeholder": "Search query (optional)" }
# @raycast.needsConfirmation false

# Documentation:
# @raycast.description Search and copy snippets from your Knowledge vault
# @raycast.author Szymon Dzumak
# @raycast.authorURL https://github.com/szymondzumak

# Configuration
KNOWLEDGE_BASE="$HOME/Developer/Knowledge"
SNIPPETS_DIR="$KNOWLEDGE_BASE/Resources/Snippets"
PATTERNS_DIR="$KNOWLEDGE_BASE/Resources/Patterns"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get search query from argument
SEARCH_QUERY="$1"

# Function to display a snippet with syntax highlighting
display_snippet() {
    local file="$1"
    local filename=$(basename "$file")
    local dir=$(dirname "$file")
    local relative_dir=${dir#$KNOWLEDGE_BASE/}
    
    echo -e "${BLUE}📁 ${relative_dir}/${filename}${NC}"
    echo "----------------------------------------"
    
    # Check if file has frontmatter and skip it
    if head -n 1 "$file" | grep -q "^---$"; then
        # Find the closing frontmatter delimiter
        local content_start=$(awk '/^---$/ { if (++n == 2) { print NR + 1; exit } }' "$file")
        tail -n +$content_start "$file" | head -20
    else
        head -20 "$file"
    fi
    
    echo "----------------------------------------"
    echo ""
}

# Function to select and copy a snippet
select_and_copy() {
    local files=("$@")
    
    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${RED}No snippets found!${NC}"
        exit 1
    fi
    
    if [ ${#files[@]} -eq 1 ]; then
        # Only one result, copy it directly
        local file="${files[0]}"
        display_snippet "$file"
        
        # Copy content without frontmatter
        if head -n 1 "$file" | grep -q "^---$"; then
            local content_start=$(awk '/^---$/ { if (++n == 2) { print NR + 1; exit } }' "$file")
            tail -n +$content_start "$file" | pbcopy
        else
            cat "$file" | pbcopy
        fi
        
        echo -e "${GREEN}✅ Copied to clipboard!${NC}"
        echo -e "${YELLOW}File: $(basename "$file")${NC}"
    else
        # Multiple results, show list
        echo -e "${GREEN}Found ${#files[@]} snippets:${NC}\n"
        
        local index=1
        for file in "${files[@]}"; do
            local filename=$(basename "$file")
            local dir=$(dirname "$file")
            local relative_dir=${dir#$KNOWLEDGE_BASE/}
            
            # Try to extract title from frontmatter or first line
            local title=""
            if head -n 10 "$file" | grep -q "^title:"; then
                title=$(head -n 10 "$file" | grep "^title:" | sed 's/title: *//')
            elif head -n 10 "$file" | grep -q "^# "; then
                title=$(head -n 10 "$file" | grep "^# " | head -1 | sed 's/# *//')
            fi
            
            printf "${BLUE}[%2d]${NC} %-30s ${YELLOW}%s${NC}\n" "$index" "$filename" "$relative_dir"
            if [ -n "$title" ]; then
                echo "     📝 $title"
            fi
            ((index++))
        done
        
        echo -e "\n${GREEN}💡 Tip: Use 'search-snippets.sh <query>' to filter results${NC}"
        echo -e "${GREEN}💡 Rerun with a number to copy that snippet${NC}"
    fi
}

# Main logic
if [ -n "$SEARCH_QUERY" ]; then
    echo -e "${YELLOW}Searching for: $SEARCH_QUERY${NC}\n"
    
    # Create temporary file for results
    temp_file=$(mktemp)
    
    # Search for files containing the query
    find "$SNIPPETS_DIR" "$PATTERNS_DIR" -type f \( -name "*.md" -o -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.sh" \) -exec grep -l -i "$SEARCH_QUERY" {} \; 2>/dev/null > "$temp_file"
    
    # Also search by filename
    find "$SNIPPETS_DIR" "$PATTERNS_DIR" -type f -name "*${SEARCH_QUERY}*" 2>/dev/null >> "$temp_file"
    
    # Deduplicate results
    sort -u "$temp_file" -o "$temp_file"
    
    # Read results into array
    files=()
    while IFS= read -r line; do
        files+=("$line")
    done < "$temp_file"
    
    rm "$temp_file"
    
    select_and_copy "${files[@]}"
else
    # No search query, show all recent snippets
    echo -e "${BLUE}📋 Recent Snippets${NC}\n"
    
    # Find all snippet files
    files=()
    while IFS= read -r line; do
        files+=("$line")
    done < <(find "$SNIPPETS_DIR" "$PATTERNS_DIR" -type f \( -name "*.md" -o -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.sh" \) 2>/dev/null | head -20)
    
    select_and_copy "${files[@]}"
fi
