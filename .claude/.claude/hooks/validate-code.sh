#!/bin/bash
# .claude/hooks/validate-code.sh
# Example hook using the helper library

# Load the library
source "$(dirname "$0")/lib/hook-lib.sh"
source "$(dirname "$0")/lib/hook-config.sh"

# Read and parse input
read_hook_input

# Only process code files
[[ "$HOOK_TOOL" == "Write" || "$HOOK_TOOL" == "Edit" ]] || success "Not a code operation"

# Check if it's a file we care about
should_ignore "$HOOK_FILE_PATH" && success "Ignoring file"

# Get file extension and content
ext=$(get_extension "$HOOK_FILE_PATH")
content="$HOOK_FILE_CONTENT"

# Run validations based on file type
case "$ext" in
    js|ts|jsx|tsx)
        log_info "Validating JavaScript/TypeScript file"

        # Check for secrets
        if [[ $ENABLE_SECRET_CHECK -eq 1 ]]; then
            check_no_secrets "$content" || fail "🔐 Secrets detected! Use environment variables."
        fi

        # Check complexity (simplified)
        if [[ $ENABLE_COMPLEXITY_CHECK -eq 1 ]]; then
            nested_depth=$(echo "$content" | grep -c "^[[:space:]]*{" || true)
            if [[ $nested_depth -gt $MAX_COMPLEXITY ]]; then
                warn "Complex code detected (depth: $nested_depth)"
            fi
        fi

        # Auto-format if enabled
        if [[ $ENABLE_AUTO_FORMAT -eq 1 ]]; then
            execute_or_simulate "$CMD_FORMAT_JS $HOOK_FILE_PATH"
        fi
        ;;

    py)
        log_info "Validating Python file"

        # Similar validations for Python
        check_no_secrets "$content" || fail "🔐 Secrets detected!"

        if [[ $ENABLE_AUTO_FORMAT -eq 1 ]]; then
            execute_or_simulate "$CMD_FORMAT_PY $HOOK_FILE_PATH"
        fi
        ;;

    md)
        log_info "Validating Markdown file"

        # Check frontmatter
        if ! check_frontmatter "$HOOK_FILE_PATH" $MARKDOWN_REQUIRED_FIELDS; then
            fail "Missing required frontmatter fields: $MARKDOWN_REQUIRED_FIELDS"
        fi
        ;;

    *)
        log_debug "No validation rules for .$ext files"
        ;;
esac

# Track TODOs if enabled
if [[ $ENABLE_TODO_TRACKING -eq 1 ]]; then
    todo_count=$(echo "$content" | grep -c "TODO\|FIXME\|HACK" || true)
    if [[ $todo_count -gt 0 ]]; then
        cache_set "todos_${HOOK_FILE_PATH//\//_}" "$todo_count"

        total_todos=0
        for cache_file in "$HOOK_CACHE_DIR"/todos_*; do
            [[ -f "$cache_file" ]] || continue
            count=$(cat "$cache_file")
            total_todos=$((total_todos + count))
        done

        if [[ $total_todos -gt $MAX_TODO_COUNT ]]; then
            warn "📝 Total TODOs: $total_todos (max: $MAX_TODO_COUNT)"
        fi
    fi
fi

success "✅ All validations passed"
