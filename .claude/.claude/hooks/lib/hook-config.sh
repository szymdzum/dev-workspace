#!/bin/bash
# .claude/hooks/lib/hook-config.sh
# Preconfigured Hook Utilities - Keep settings.json tidy!

# ============================================================================
# VALIDATION CONFIGURATION
# ============================================================================

# Feature toggles (0 = disabled, 1 = enabled)
export ENABLE_SECRET_CHECK=1
export ENABLE_COMPLEXITY_CHECK=1
export ENABLE_AUTO_FORMAT=0
export ENABLE_TODO_TRACKING=1
export ENABLE_TYPE_CHECK=1
export ENABLE_LINT_CHECK=1

# Complexity thresholds
export MAX_COMPLEXITY=15
export MAX_LINE_LENGTH=120
export MAX_TODO_COUNT=50

# File patterns to always ignore
export IGNORE_PATTERNS="node_modules|\.git|dist|build|\.cache|\.tmp|\.log"

# ============================================================================
# MARKDOWN VALIDATION
# ============================================================================

export MARKDOWN_REQUIRED_FIELDS="title date"

# ============================================================================
# FORMATTING COMMANDS
# ============================================================================

export CMD_FORMAT_JS="npx prettier --write"
export CMD_FORMAT_PY="black"
export CMD_FORMAT_MD="npx prettier --write --prose-wrap=preserve"

# Lint commands
export CMD_LINT_JS="npx eslint"
export CMD_LINT_PY="flake8"

# Type check commands
export CMD_TYPE_CHECK_JS="npx tsc --noEmit"
export CMD_TYPE_CHECK_PY="mypy"

# ============================================================================
# PROJECT-SPECIFIC PRESETS
# ============================================================================

# Detect project type and apply appropriate settings
detect_project_type() {
    if [[ -f "$HOOK_PROJECT_DIR/package.json" ]]; then
        echo "nodejs"
    elif [[ -f "$HOOK_PROJECT_DIR/requirements.txt" || -f "$HOOK_PROJECT_DIR/pyproject.toml" ]]; then
        echo "python"
    elif [[ -f "$HOOK_PROJECT_DIR/Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "$HOOK_PROJECT_DIR/go.mod" ]]; then
        echo "go"
    else
        echo "generic"
    fi
}

# Apply project-specific configurations
PROJECT_TYPE=$(detect_project_type)

case "$PROJECT_TYPE" in
    nodejs)
        # Node.js specific settings
        export ENABLE_AUTO_FORMAT=1
        export ENABLE_TYPE_CHECK=1
        export CMD_FORMAT_JS="npx prettier --write"
        export CMD_LINT_JS="npx eslint --fix"
        
        # Check if using TypeScript
        if [[ -f "$HOOK_PROJECT_DIR/tsconfig.json" ]]; then
            export TYPESCRIPT_PROJECT=1
        fi
        ;;
        
    python)
        # Python specific settings
        export ENABLE_AUTO_FORMAT=1
        export CMD_FORMAT_PY="black --line-length $MAX_LINE_LENGTH"
        export CMD_LINT_PY="flake8 --max-line-length=$MAX_LINE_LENGTH"
        ;;
        
    rust)
        # Rust specific settings
        export CMD_FORMAT_RUST="cargo fmt"
        export CMD_LINT_RUST="cargo clippy"
        ;;
        
    go)
        # Go specific settings
        export CMD_FORMAT_GO="gofmt -w"
        export CMD_LINT_GO="golangci-lint run"
        ;;
esac

# ============================================================================
# HOOK PRESET GENERATORS
# ============================================================================

# Generate common hook configurations to keep settings.json clean
generate_presets() {
    local preset_type="$1"
    
    case "$preset_type" in
        "strict")
            cat <<'JSON'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/validate-code.sh",
            "timeout": 10,
            "continueOnFailure": false
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command", 
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/post-process.sh",
            "timeout": 15
          }
        ]
      }
    ]
  }
}
JSON
            ;;
            
        "relaxed")
            cat <<'JSON'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/validate-code.sh",
            "timeout": 5,
            "continueOnFailure": true
          }
        ]
      }
    ]
  }
}
JSON
            ;;
            
        "format-only")
            cat <<'JSON'
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/format-only.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
JSON
            ;;
    esac
}

# Quick preset application
apply_preset() {
    local preset="$1"
    local settings_file="${2:-$CLAUDE_PROJECT_DIR/.claude/settings.json}"
    
    log_info "Applying $preset preset to $settings_file"
    
    # Backup existing settings
    if [[ -f "$settings_file" ]]; then
        cp "$settings_file" "$settings_file.backup.$(date +%s)"
    fi
    
    # Generate new settings
    generate_presets "$preset" > "$settings_file"
    log_info " Applied $preset preset"
}

# ============================================================================
# SMART DEFAULTS BASED ON ENVIRONMENT
# ============================================================================

# Adjust settings based on CI environment
if [[ -n "$CI" || -n "$GITHUB_ACTIONS" ]]; then
    export ENABLE_AUTO_FORMAT=0  # Don't format in CI
    export MAX_COMPLEXITY=20     # More lenient in CI
fi

# Development vs Production
if [[ "$NODE_ENV" == "development" ]]; then
    export ENABLE_TODO_TRACKING=1
    export MAX_TODO_COUNT=100
else
    export ENABLE_TODO_TRACKING=0
fi

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Show current configuration
show_config() {
    echo "=' Hook Configuration Summary"
    echo "============================="
    echo "Project Type: $PROJECT_TYPE"
    echo "Secret Check: $([ $ENABLE_SECRET_CHECK -eq 1 ] && echo "" || echo "L")"
    echo "Complexity Check: $([ $ENABLE_COMPLEXITY_CHECK -eq 1 ] && echo "" || echo "L")"
    echo "Auto Format: $([ $ENABLE_AUTO_FORMAT -eq 1 ] && echo "" || echo "L")"
    echo "TODO Tracking: $([ $ENABLE_TODO_TRACKING -eq 1 ] && echo "" || echo "L")"
    echo "Max Complexity: $MAX_COMPLEXITY"
    echo "Max TODOs: $MAX_TODO_COUNT"
}

# Test configuration
test_config() {
    echo ">ê Testing Hook Configuration"
    echo "=============================="
    
    # Test each enabled feature
    [[ $ENABLE_SECRET_CHECK -eq 1 ]] && echo " Secret detection ready"
    [[ $ENABLE_COMPLEXITY_CHECK -eq 1 ]] && echo " Complexity checking ready" 
    [[ $ENABLE_AUTO_FORMAT -eq 1 ]] && echo " Auto-formatting ready"
    [[ $ENABLE_TODO_TRACKING -eq 1 ]] && echo " TODO tracking ready"
    
    # Test commands availability
    case "$PROJECT_TYPE" in
        nodejs)
            command -v npx >/dev/null && echo " npx available" || echo "L npx missing"
            ;;
        python)
            command -v python >/dev/null && echo " python available" || echo "L python missing"
            ;;
    esac
}

# Generate sample settings.json with current config
generate_settings() {
    local output_file="${1:-./settings.json.sample}"
    
    cat > "$output_file" <<JSON
{
  "projectConfig": {
    "project": {
      "name": "$(basename "$HOOK_PROJECT_DIR")",
      "type": "$PROJECT_TYPE",
      "mainBranch": "main"
    },
    "ignore": {
      "paths": ["node_modules", ".git", "dist", "build", ".cache"],
      "patterns": ["*.log", "*.tmp", ".DS_Store"]
    }
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "\$CLAUDE_PROJECT_DIR/.claude/hooks/validate-code.sh",
            "timeout": 10,
            "continueOnFailure": false
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "\$CLAUDE_PROJECT_DIR/.claude/hooks/post-process.sh", 
            "timeout": 15
          }
        ]
      }
    ]
  }
}
JSON

    log_info "Generated sample settings at $output_file"
}

# ============================================================================
# INITIALIZATION
# ============================================================================

# Auto-configure based on project if running directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-show}" in
        show)
            show_config
            ;;
        test)
            test_config
            ;;
        preset)
            apply_preset "${2:-strict}"
            ;;
        generate)
            generate_settings "${2}"
            ;;
        *)
            echo "Usage: $0 {show|test|preset <strict|relaxed|format-only>|generate [file]}"
            exit 1
            ;;
    esac
fi