#!/bin/bash
# .claude/lib/paths.sh
# Central directory management for consistent paths across all scripts

set -euo pipefail

# ============================================================================
# CENTRAL PATH CONFIGURATION
# ============================================================================

# Claude Code expects these standard paths
export CLAUDE_CODE_ROOT="/Users/szymondzumak/Developer/.ai"
export CLAUDE_CONFIG_DIR="$CLAUDE_CODE_ROOT/.claude"

# Core directories
export CLAUDE_HOOKS_DIR="$CLAUDE_CONFIG_DIR/hooks"
export CLAUDE_CONFIG_JSON_DIR="$CLAUDE_CONFIG_DIR/config"
export CLAUDE_SCHEMAS_DIR="$CLAUDE_CONFIG_DIR/schemas"
export CLAUDE_CONTEXTS_DIR="$CLAUDE_CONFIG_DIR/contexts"

# Working directories (created by hooks)
export CLAUDE_LOGS_DIR="$CLAUDE_HOOKS_DIR/logs"
export CLAUDE_CACHE_DIR="$CLAUDE_HOOKS_DIR/.cache"

# Project root (where Claude Code operates)
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$CLAUDE_CODE_ROOT}"

# ============================================================================
# HOOK COMPATIBILITY ALIASES
# ============================================================================

# Map to hook library expected names for backward compatibility
export HOOK_PROJECT_DIR="$CLAUDE_PROJECT_DIR"
export HOOK_CONFIG_DIR="$CLAUDE_HOOKS_DIR"
export HOOK_LOG_DIR="$CLAUDE_LOGS_DIR"
export HOOK_CACHE_DIR="$CLAUDE_CACHE_DIR"

# ============================================================================
# DIRECTORY CREATION
# ============================================================================

create_directories() {
    local dirs=(
        "$CLAUDE_LOGS_DIR"
        "$CLAUDE_CACHE_DIR"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            echo "Created: $dir"
        fi
    done
}

# ============================================================================
# PATH VALIDATION
# ============================================================================

validate_paths() {
    local errors=0
    
    echo "🔍 Validating Paths"
    echo "=================="
    
    # Check required directories exist
    local required_dirs=(
        "$CLAUDE_CONFIG_DIR"
        "$CLAUDE_HOOKS_DIR"
        "$CLAUDE_CONFIG_JSON_DIR"
        "$CLAUDE_SCHEMAS_DIR"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            echo "✅ $dir"
        else
            echo "❌ $dir (missing)"
            ((errors++))
        fi
    done
    
    # Check working directories (should be created)
    echo -e "\nWorking directories:"
    echo "📁 Logs: $CLAUDE_LOGS_DIR"
    echo "📁 Cache: $CLAUDE_CACHE_DIR"
    
    if [[ $errors -gt 0 ]]; then
        echo -e "\n💥 Found $errors missing directories"
        return 1
    else
        echo -e "\n✅ All paths validated"
        return 0
    fi
}

# ============================================================================
# DEBUGGING
# ============================================================================

show_paths() {
    echo "🗂️  Claude Code Directory Structure"
    echo "=================================="
    echo "Root:       $CLAUDE_CODE_ROOT"
    echo "Config:     $CLAUDE_CONFIG_DIR"
    echo "Hooks:      $CLAUDE_HOOKS_DIR"
    echo "JSON Config: $CLAUDE_CONFIG_JSON_DIR"
    echo "Schemas:    $CLAUDE_SCHEMAS_DIR"
    echo "Contexts:   $CLAUDE_CONTEXTS_DIR"
    echo ""
    echo "Working:"
    echo "Logs:       $CLAUDE_LOGS_DIR"
    echo "Cache:      $CLAUDE_CACHE_DIR"
    echo ""
    echo "Project:    $CLAUDE_PROJECT_DIR"
    echo ""
    echo "Legacy Hook Aliases:"
    echo "HOOK_PROJECT_DIR:  $HOOK_PROJECT_DIR"
    echo "HOOK_CONFIG_DIR:   $HOOK_CONFIG_DIR"  
    echo "HOOK_LOG_DIR:      $HOOK_LOG_DIR"
    echo "HOOK_CACHE_DIR:    $HOOK_CACHE_DIR"
}

# ============================================================================
# INITIALIZATION
# ============================================================================

# Auto-create directories when sourced
create_directories

# If run directly, show debug info
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
    case "${1:-show}" in
        show)
            show_paths
            ;;
        validate)
            validate_paths
            ;;
        create)
            create_directories
            ;;
        *)
            echo "Usage: $0 {show|validate|create}"
            exit 1
            ;;
    esac
fi