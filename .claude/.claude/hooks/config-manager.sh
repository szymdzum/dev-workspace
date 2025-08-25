#!/bin/bash

# Hook Configuration Manager
# Manages hook presets from manifest.json and updates settings.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_FILE="$HOME/.claude/settings.json"
MANIFEST_FILE="$SCRIPT_DIR/manifest.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  list              List available presets"
    echo "  apply <preset>    Apply a preset configuration"
    echo "  current           Show current active preset"
    echo "  show <preset>     Show preset configuration"
    echo "  validate          Validate current settings"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 apply relaxed"
    echo "  $0 current"
}

list_presets() {
    echo -e "${BLUE}Available presets:${NC}"
    jq -r '.presets | to_entries[] | "\(.key): \(.value.description)"' "$MANIFEST_FILE" | while IFS=: read -r name desc; do
        current=$(jq -r '.active // "custom"' "$MANIFEST_FILE")
        if [[ "$name" == "$current" ]]; then
            echo -e "  ${GREEN}● $name:$desc (active)${NC}"
        else
            echo -e "  ○ $name:$desc"
        fi
    done
}

get_current_preset() {
    jq -r '.active // "custom"' "$MANIFEST_FILE"
}

show_preset() {
    local preset="$1"
    
    if ! jq -e ".presets.$preset" "$MANIFEST_FILE" > /dev/null 2>&1; then
        echo -e "${RED}Error: Preset '$preset' not found${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Preset: $preset${NC}"
    jq ".presets.$preset" "$MANIFEST_FILE"
}

apply_preset() {
    local preset="$1"
    
    # Check if preset exists
    if ! jq -e ".presets.$preset" "$MANIFEST_FILE" > /dev/null 2>&1; then
        echo -e "${RED}Error: Preset '$preset' not found${NC}"
        list_presets
        exit 1
    fi
    
    echo -e "${YELLOW}Applying preset: $preset${NC}"
    
    # Get the preset hooks configuration and expand environment variables
    local hooks_config=$(jq ".presets.$preset.hooks" "$MANIFEST_FILE")
    
    # Replace $HOOK_DIR with actual path
    hooks_config=$(echo "$hooks_config" | sed "s|\$HOOK_DIR|$SCRIPT_DIR|g")
    
    # Replace $CLAUDE_PROJECT_DIR with expanded path (for Claude's use)
    hooks_config=$(echo "$hooks_config" | sed "s|\$CLAUDE_PROJECT_DIR|\$CLAUDE_PROJECT_DIR|g")
    
    # Backup current settings
    cp "$SETTINGS_FILE" "$SETTINGS_FILE.bak"
    echo "Backed up current settings to $SETTINGS_FILE.bak"
    
    # Update settings.json with new hooks configuration
    echo "$hooks_config" | jq '.' > /tmp/hooks_config.json
    jq --slurpfile hooks /tmp/hooks_config.json '.hooks = $hooks[0]' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && \
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    rm -f /tmp/hooks_config.json
    
    # Update the active preset in manifest
    jq --arg preset "$preset" '.active = $preset' "$MANIFEST_FILE" > "$MANIFEST_FILE.tmp" && \
    mv "$MANIFEST_FILE.tmp" "$MANIFEST_FILE"
    
    echo -e "${GREEN}✓ Successfully applied preset: $preset${NC}"
    
    # Show what was applied
    echo -e "\n${BLUE}Applied configuration:${NC}"
    jq '.hooks' "$SETTINGS_FILE"
}

validate_settings() {
    echo -e "${BLUE}Validating settings.json...${NC}"
    
    # Check if settings file exists
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        echo -e "${RED}Error: Settings file not found at $SETTINGS_FILE${NC}"
        exit 1
    fi
    
    # Validate JSON syntax
    if ! jq empty "$SETTINGS_FILE" 2>/dev/null; then
        echo -e "${RED}Error: Invalid JSON in settings.json${NC}"
        exit 1
    fi
    
    # Check hooks structure
    local hooks=$(jq '.hooks' "$SETTINGS_FILE")
    if [[ "$hooks" == "null" ]]; then
        echo -e "${YELLOW}Warning: No hooks configured${NC}"
    else
        # Check for valid event types
        local valid_events=("PreToolUse" "PostToolUse" "Notification" "UserPromptSubmit" "SessionStart" "SessionEnd" "Stop" "SubagentStop" "PreCompact")
        
        for event in $(jq -r '.hooks | keys[]' "$SETTINGS_FILE" 2>/dev/null); do
            if [[ ! " ${valid_events[@]} " =~ " ${event} " ]]; then
                echo -e "${RED}Error: Invalid event type: $event${NC}"
                echo "Valid events: ${valid_events[*]}"
                exit 1
            fi
        done
        
        echo -e "${GREEN}✓ Hooks structure is valid${NC}"
    fi
    
    echo -e "${GREEN}✓ Settings validation passed${NC}"
}

# Main command handling
case "${1:-}" in
    list)
        list_presets
        ;;
    apply)
        if [[ -z "${2:-}" ]]; then
            echo -e "${RED}Error: Preset name required${NC}"
            print_usage
            exit 1
        fi
        apply_preset "$2"
        ;;
    current)
        current=$(get_current_preset)
        echo -e "${BLUE}Current preset: ${GREEN}$current${NC}"
        show_preset "$current" 2>/dev/null || echo "(using custom configuration)"
        ;;
    show)
        if [[ -z "${2:-}" ]]; then
            echo -e "${RED}Error: Preset name required${NC}"
            print_usage
            exit 1
        fi
        show_preset "$2"
        ;;
    validate)
        validate_settings
        ;;
    *)
        print_usage
        exit 0
        ;;
esac