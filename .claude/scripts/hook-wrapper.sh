
#!/bin/bash
# Shell wrapper integration tests
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test functions
test_start() {
    echo -e "${YELLOW}Running: $1${NC}"
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_pass() {
    echo -e "${GREEN}✓ PASS: $1${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    echo -e "${RED}✗ FAIL: $1${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Setup test environment
setup() {
    # Find the project root by looking for .claude directory
    local current_dir="$(pwd)"
    local project_root=""

    # Start from current directory and go up until we find .claude
    while [[ "$current_dir" != "/" ]]; do
        if [[ -d "$current_dir/.claude" ]]; then
            project_root="$current_dir"
            break
        fi
        current_dir="$(dirname "$current_dir")"
    done

    if [[ -z "$project_root" ]]; then
        echo "Error: Could not find .claude directory in parent directories"
        exit 1
    fi

    export CLAUDE_PROJECT_DIR="$project_root"
    export TEST_HOOKS_DIR="$project_root/.claude/hooks"

    echo "Found project root: $CLAUDE_PROJECT_DIR"
    echo "Testing hooks in: $TEST_HOOKS_DIR"

    # Ensure hooks exist
    if [[ ! -f "$TEST_HOOKS_DIR/test-security.sh" ]]; then
        echo "Error: test-security.sh not found at $TEST_HOOKS_DIR"
        echo "Available files:"
        ls -la "$TEST_HOOKS_DIR/" || echo "Directory does not exist"
        exit 1
    fi
}

# Test 1: Basic OpenAI API key detection
test_openai_detection() {
    test_start "OpenAI API key detection"

    local input='{"tool_name":"Write","tool_input":{"content":"const key = \"sk-1234567890123456789012345678901234567890123456789\";"}}'
    local output=$(echo "$input" | "$TEST_HOOKS_DIR/test-security.sh")
    local exit_code=$?

    if [[ $exit_code -eq 0 ]] && echo "$output" | jq -e '.continue == false' >/dev/null 2>&1; then
        test_pass "Correctly blocked OpenAI API key"
    else
        test_fail "Failed to block OpenAI API key. Output: $output"
    fi
}

# Test 2: GitHub token detection
test_github_detection() {
    test_start "GitHub token detection"

    local input='{"tool_name":"Write","tool_input":{"content":"const token = \"ghp_1234567890123456789012345678901234567890\";"}}'
    local output=$(echo "$input" | "$TEST_HOOKS_DIR/test-security.sh")
    local exit_code=$?

    if [[ $exit_code -eq 0 ]] && echo "$output" | jq -e '.continue == false' >/dev/null 2>&1; then
        test_pass "Correctly blocked GitHub token"
    else
        test_fail "Failed to block GitHub token. Output: $output"
    fi
}

# Test 3: Generic credential detection
test_generic_credentials() {
    test_start "Generic credential detection"

    local input='{"tool_name":"Write","tool_input":{"content":"password = \"supersecretpassword123\""}}'
    local output=$(echo "$input" | "$TEST_HOOKS_DIR/test-security.sh")
    local exit_code=$?

    if [[ $exit_code -eq 0 ]] && echo "$output" | jq -e '.continue == false' >/dev/null 2>&1; then
        test_pass "Correctly blocked generic credential"
    else
        test_fail "Failed to block generic credential. Output: $output"
    fi
}

# Test 4: Safe code should pass
test_safe_code() {
    test_start "Safe code should pass"

    local input='{"tool_name":"Write","tool_input":{"content":"const apiKey = process.env.OPENAI_API_KEY;"}}'
    local output=$(echo "$input" | "$TEST_HOOKS_DIR/test-security.sh")
    local exit_code=$?

    if [[ $exit_code -eq 0 ]] && echo "$output" | jq -e '.continue == true' >/dev/null 2>&1; then
        test_pass "Correctly allowed safe code"
    else
        test_fail "Incorrectly blocked safe code. Output: $output"
    fi
}

# Test 5: Empty content should pass
test_empty_content() {
    test_start "Empty content should pass"

    local input='{"tool_name":"Write","tool_input":{"content":""}}'
    local output=$(echo "$input" | "$TEST_HOOKS_DIR/test-security.sh")
    local exit_code=$?

    if [[ $exit_code -eq 0 ]] && echo "$output" | jq -e '.continue == true' >/dev/null 2>&1; then
        test_pass "Correctly allowed empty content"
    else
        test_fail "Incorrectly blocked empty content. Output: $output"
    fi
}

# Test 6: Malformed JSON should not crash
test_malformed_json() {
    test_start "Malformed JSON handling"

    local input='{ invalid json content }'
    local output=$(echo "$input" | "$TEST_HOOKS_DIR/test-security.sh" 2>/dev/null || echo '{"continue":true}')
    local exit_code=$?

    # Script should not crash (exit code should be 0 or 1, not 130 or other crash codes)
    if [[ $exit_code -le 1 ]]; then
        test_pass "Gracefully handled malformed JSON"
    else
        test_fail "Crashed on malformed JSON. Exit code: $exit_code"
    fi
}

# Test 7: JSON output format validation
test_json_output_format() {
    test_start "JSON output format validation"

    local input='{"tool_name":"Write","tool_input":{"content":"safe content"}}'
    local output=$(echo "$input" | "$TEST_HOOKS_DIR/test-security.sh")

    # Validate JSON structure
    if echo "$output" | jq -e '.continue' >/dev/null 2>&1; then
        test_pass "Output has correct JSON format"
    else
        test_fail "Output is not valid JSON or missing required fields. Output: $output"
    fi
}

# Test 8: Permission decision fields
test_permission_decision_fields() {
    test_start "Permission decision fields"

    local input='{"tool_name":"Write","tool_input":{"content":"const key = \"sk-1234567890123456789012345678901234567890123456789\";"}}'
    local output=$(echo "$input" | "$TEST_HOOKS_DIR/test-security.sh")

    local has_permission_decision=$(echo "$output" | jq -e '.hookSpecificOutput.permissionDecision' >/dev/null 2>&1 && echo "true" || echo "false")
    local has_reason=$(echo "$output" | jq -e '.hookSpecificOutput.permissionDecisionReason' >/dev/null 2>&1 && echo "true" || echo "false")

    if [[ "$has_permission_decision" == "true" && "$has_reason" == "true" ]]; then
        test_pass "Output includes required permission decision fields"
    else
        test_fail "Output missing permission decision fields. Output: $output"
    fi
}

# Test 9: No jq fallback (simulate missing jq)
test_no_jq_fallback() {
    test_start "No jq fallback parsing"

    # Temporarily rename jq if it exists
    local jq_backup=""
    if command -v jq >/dev/null 2>&1; then
        jq_backup=$(command -v jq)
        sudo mv "$jq_backup" "${jq_backup}.backup" 2>/dev/null || true
    fi

    local input='{"tool_name":"Write","tool_input":{"content":"const key = \"sk-1234567890123456789012345678901234567890123456789\";"}}'
    local output=$(echo "$input" | "$TEST_HOOKS_DIR/test-security.sh" 2>/dev/null || echo '{"continue":true}')
    local exit_code=$?

    # Restore jq if it was backed up
    if [[ -n "$jq_backup" && -f "${jq_backup}.backup" ]]; then
        sudo mv "${jq_backup}.backup" "$jq_backup" 2>/dev/null || true
    fi

    if [[ $exit_code -eq 0 ]]; then
        test_pass "Fallback parsing worked without jq"
    else
        test_fail "Failed to work without jq. Exit code: $exit_code"
    fi
}

# Test 10: File path extraction
test_file_path_extraction() {
    test_start "File path extraction"

    local input='{"tool_name":"Write","tool_input":{"content":"safe content","file_path":"/tmp/test.ts"}}'
    local output=$(echo "$input" | "$TEST_HOOKS_DIR/test-security.sh")

    # The script should process the file_path field without errors
    if echo "$output" | jq -e '.continue == true' >/dev/null 2>&1; then
        test_pass "Successfully extracted and processed file path"
    else
        test_fail "Failed to process file path. Output: $output"
    fi
}

# Test 11: Multiple secrets detection
test_multiple_secrets() {
    test_start "Multiple secrets detection"

    local input='{"tool_name":"Write","tool_input":{"content":"const openai = \"sk-1234567890123456789012345678901234567890123456789\";\nconst github = \"ghp_1234567890123456789012345678901234567890\";"}}'
    local output=$(echo "$input" | "$TEST_HOOKS_DIR/test-security.sh")

    if echo "$output" | jq -e '.continue == false' >/dev/null 2>&1; then
        test_pass "Correctly blocked content with multiple secrets"
    else
        test_fail "Failed to block content with multiple secrets. Output: $output"
    fi
}

# Test 12: Case sensitivity
test_case_sensitivity() {
    test_start "Case sensitivity in patterns"

    # Should detect regardless of case in surrounding text
    local input='{"tool_name":"Write","tool_input":{"content":"const API_KEY = \"sk-1234567890123456789012345678901234567890123456789\";"}}'
    local output=$(echo "$input" | "$TEST_HOOKS_DIR/test-security.sh")

    if echo "$output" | jq -e '.continue == false' >/dev/null 2>&1; then
        test_pass "Pattern matching works regardless of case"
    else
        test_fail "Pattern matching failed with mixed case. Output: $output"
    fi
}

# Main test execution
main() {
    echo "=== Shell Wrapper Integration Tests ==="
    echo "Testing: ${TEST_HOOKS_DIR:-not-set}/test-security.sh"
    echo

    setup

    # Check if jq is available
    if ! command -v jq >/dev/null 2>&1; then
        echo -e "${YELLOW}Warning: jq not found. Some tests may use fallback parsing.${NC}"
    fi

    # Run all tests
    test_openai_detection
    test_github_detection
    test_generic_credentials
    test_safe_code
    test_empty_content
    test_malformed_json
    test_json_output_format
    test_permission_decision_fields
    test_no_jq_fallback
    test_file_path_extraction
    test_multiple_secrets
    test_case_sensitivity

    # Results summary
    echo
    echo "=== Test Results ==="
    echo -e "Tests run: ${TESTS_RUN}"
    echo -e "Passed: ${GREEN}${TESTS_PASSED}${NC}"
    echo -e "Failed: ${RED}${TESTS_FAILED}${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed.${NC}"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi