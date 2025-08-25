#!/bin/bash
# .claude/hooks/lib/hook-lib.sh
# The Swiss Army Knife of Hook Development

set -euo pipefail  # Because we're professionals

# ============================================================================
# ENVIRONMENT & CONFIGURATION
# ============================================================================

# Load centralized path management
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
CLAUDE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$CLAUDE_DIR/lib/paths.sh"

# Hook-specific environment
export HOOK_DEBUG="${HOOK_DEBUG:-0}"
export HOOK_DRY_RUN="${HOOK_DRY_RUN:-0}"

# Note: Directories are created by paths.sh

# ============================================================================
# LOGGING & DEBUGGING
# ============================================================================

# Color codes for the fancy people
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly RESET='\033[0m'

# Log levels
readonly LOG_ERROR=1
readonly LOG_WARN=2
readonly LOG_INFO=3
readonly LOG_DEBUG=4

HOOK_LOG_LEVEL="${HOOK_LOG_LEVEL:-$LOG_INFO}"

# Logging functions that actually help
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Log to file always
    echo "[$timestamp] [$level] $message" >> "$HOOK_LOG_DIR/hook.log"

    # Log to stderr based on level
    case $level in
        ERROR)
            [[ $HOOK_LOG_LEVEL -ge $LOG_ERROR ]] && echo -e "${RED}❌ $message${RESET}" >&2
            ;;
        WARN)
            [[ $HOOK_LOG_LEVEL -ge $LOG_WARN ]] && echo -e "${YELLOW}⚠️  $message${RESET}" >&2
            ;;
        INFO)
            [[ $HOOK_LOG_LEVEL -ge $LOG_INFO ]] && echo -e "${GREEN}✅ $message${RESET}" >&2
            ;;
        DEBUG)
            [[ $HOOK_LOG_LEVEL -ge $LOG_DEBUG ]] && echo -e "${CYAN}🔍 $message${RESET}" >&2
            ;;
    esac
}

log_error() { log ERROR "$@"; }
log_warn() { log WARN "$@"; }
log_info() { log INFO "$@"; }
log_debug() { log DEBUG "$@"; }

# Debug helper - shows all variables when HOOK_DEBUG=1
debug_vars() {
    [[ $HOOK_DEBUG -eq 1 ]] || return 0
    echo "=== Hook Environment ===" >&2
    env | grep -E '^(HOOK_|CLAUDE_)' | sort >&2
    echo "=== Hook Input ===" >&2
    echo "$HOOK_INPUT" | jq '.' >&2 2>/dev/null || echo "$HOOK_INPUT" >&2
    echo "==================" >&2
}

# ============================================================================
# INPUT PARSING
# ============================================================================

# Read and parse hook input
read_hook_input() {
    export HOOK_INPUT=$(cat)
    export HOOK_EVENT=$(echo "$HOOK_INPUT" | jq -r '.hook_event_name // ""')
    export HOOK_TOOL=$(echo "$HOOK_INPUT" | jq -r '.tool_name // ""')
    export HOOK_SESSION=$(echo "$HOOK_INPUT" | jq -r '.session_id // ""')
    export HOOK_CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd // ""')

    # Tool-specific parsing
    if [[ -n "$HOOK_TOOL" ]]; then
        export HOOK_FILE_PATH=$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // ""')
        export HOOK_FILE_CONTENT=$(echo "$HOOK_INPUT" | jq -r '.tool_input.content // ""')
        export HOOK_COMMAND=$(echo "$HOOK_INPUT" | jq -r '.tool_input.command // ""')
    fi

    debug_vars
}

# Extract specific field from input
get_input_field() {
    local field="$1"
    echo "$HOOK_INPUT" | jq -r "$field // \"\""
}

# ============================================================================
# FILE OPERATIONS
# ============================================================================

# Check if file matches pattern
file_matches() {
    local file="$1"
    local pattern="$2"
    [[ "$file" =~ $pattern ]]
}

# Get file extension
get_extension() {
    local file="$1"
    echo "${file##*.}"
}

# Check if file is in project
is_project_file() {
    local file="$1"
    local abs_file=$(realpath "$file" 2>/dev/null || echo "$file")
    [[ "$abs_file" == "$HOOK_PROJECT_DIR"* ]]
}

# Check if file should be ignored
should_ignore() {
    local file="$1"
    local ignore_patterns=(
        "node_modules"
        ".git"
        "dist"
        "build"
        ".cache"
        "*.log"
    )

    for pattern in "${ignore_patterns[@]}"; do
        [[ "$file" == *"$pattern"* ]] && return 0
    done
    return 1
}

# ============================================================================
# VALIDATION HELPERS
# ============================================================================

# Validate required fields exist
require_fields() {
    local fields=("$@")
    for field in "${fields[@]}"; do
        local value=$(get_input_field "$field")
        if [[ -z "$value" ]]; then
            fail "Required field missing: $field"
        fi
    done
}

# Check file type
require_file_type() {
    local file="$1"
    shift
    local types=("$@")
    local ext=$(get_extension "$file")

    for type in "${types[@]}"; do
        [[ "$ext" == "$type" ]] && return 0
    done

    fail "File type .$ext not in allowed types: ${types[*]}"
}

# ============================================================================
# RESPONSE HELPERS
# ============================================================================

# Success response
success() {
    local message="${1:-Operation successful}"
    log_info "$message"
    exit 0
}

# Warning (non-blocking)
warn() {
    local message="$1"
    log_warn "$message"
    echo "$message" >&2
    exit 1
}

# Failure (blocking for exit code 2)
fail() {
    local message="$1"
    log_error "$message"
    echo "$message" >&2
    exit 2
}

# JSON response for advanced control
json_response() {
    local decision="${1:-}"
    local reason="${2:-}"
    local continue="${3:-true}"

    cat <<JSON
{
    "decision": "$decision",
    "reason": "$reason",
    "continue": $continue,
    "hookSpecificOutput": {
        "hookEventName": "$HOOK_EVENT"
    }
}
JSON
    exit 0
}

# ============================================================================
# CACHE OPERATIONS
# ============================================================================

# Cache a value
cache_set() {
    local key="$1"
    local value="$2"
    echo "$value" > "$HOOK_CACHE_DIR/$key"
}

# Get cached value
cache_get() {
    local key="$1"
    local default="${2:-}"
    local cache_file="$HOOK_CACHE_DIR/$key"

    if [[ -f "$cache_file" ]]; then
        cat "$cache_file"
    else
        echo "$default"
    fi
}

# Check if cache exists and is fresh
cache_fresh() {
    local key="$1"
    local max_age="${2:-3600}"  # Default 1 hour
    local cache_file="$HOOK_CACHE_DIR/$key"

    [[ -f "$cache_file" ]] || return 1

    local file_age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file")))
    [[ $file_age -lt $max_age ]]
}

# ============================================================================
# COMMON VALIDATIONS
# ============================================================================

# Check for secrets/credentials
check_no_secrets() {
    local content="$1"
    local patterns=(
        "api[_-]?key"
        "secret"
        "password"
        "token"
        "private[_-]?key"
        "AWS_[A-Z_]+"
        "GITHUB_TOKEN"
    )

    for pattern in "${patterns[@]}"; do
        if echo "$content" | grep -iE "$pattern" > /dev/null; then
            return 1
        fi
    done
    return 0
}

# Validate markdown frontmatter
check_frontmatter() {
    local file="$1"
    local required_fields=("${@:2}")

    if ! head -n 1 "$file" | grep -q "^---$"; then
        return 1
    fi

    local frontmatter=$(sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d')

    for field in "${required_fields[@]}"; do
        if ! echo "$frontmatter" | grep -q "^$field:"; then
            return 1
        fi
    done
    return 0
}

# ============================================================================
# DRY RUN MODE
# ============================================================================

# Execute or simulate based on DRY_RUN
execute_or_simulate() {
    local command="$1"
    if [[ $HOOK_DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would execute: $command"
        return 0
    else
        log_debug "Executing: $command"
        eval "$command"
    fi
}

# ============================================================================
# INITIALIZATION
# ============================================================================

# Auto-read input if running as hook
if [[ "${BASH_SOURCE[0]:-}" != "${0}" ]]; then
    # Being sourced, don't auto-read
    :
else
    # Being executed directly, auto-initialize
    read_hook_input
fi
