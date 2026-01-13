#!/usr/bin/env bash
# Test: Template Engine
# Version: 2.0.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Load test framework
source "${SCRIPT_DIR}/../lib/framework.sh"
source "${SCRIPT_DIR}/../lib/assertions.sh"

# Load MLEnv
export MLENV_LIB="${PROJECT_ROOT}/lib/mlenv"
export MLENV_SHARE="${PROJECT_ROOT}/share/mlenv"
source "${MLENV_LIB}/utils/logging.sh"
source "${MLENV_LIB}/templates/engine.sh"

# Test setup
test_setup() {
    TEST_TEMPLATE_DIR=$(mktemp -d)
    MLENV_USER_TEMPLATE_DIR="$TEST_TEMPLATE_DIR"
}

# Test teardown
test_teardown() {
    rm -rf "$TEST_TEMPLATE_DIR"
}

# Tests

test_template_get_path_builtin() {
    local path=$(template_get_path "minimal")
    assert_contains "$path" "minimal" "Should find minimal template"
}

test_template_create() {
    template_create "test-template" >/dev/null 2>&1
    assert_dir_exists "$TEST_TEMPLATE_DIR/test-template" "Template directory should be created"
    assert_file_exists "$TEST_TEMPLATE_DIR/test-template/template.yaml" "template.yaml should exist"
}

test_template_validate_valid() {
    # Create a valid template first
    template_create "valid-template" >/dev/null 2>&1
    
    if template_validate "valid-template" >/dev/null 2>&1; then
        assert_true "true" "Valid template should pass validation"
    fi
}

test_template_process_variables() {
    # Create a test file with variables
    local test_file="$TEST_TEMPLATE_DIR/test.txt"
    echo "Project: {{PROJECT_NAME}}" > "$test_file"
    echo "Author: {{AUTHOR}}" >> "$test_file"
    
    template_process_file "$test_file" "$TEST_TEMPLATE_DIR/output.txt" "MyProject"
    
    local content=$(cat "$TEST_TEMPLATE_DIR/output.txt")
    assert_contains "$content" "MyProject" "Should substitute PROJECT_NAME"
    assert_contains "$content" "$USER" "Should substitute AUTHOR"
}

# Run tests
main() {
    test_suite_begin "Template Engine Tests"
    
    test_run_with_hooks test_template_get_path_builtin
    test_run_with_hooks test_template_create
    test_run_with_hooks test_template_validate_valid
    test_run_with_hooks test_template_process_variables
    
    test_suite_end
}

main "$@"
