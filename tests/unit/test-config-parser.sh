#!/usr/bin/env bash
# Test: Configuration Parser
# Version: 2.0.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Load test framework
source "${SCRIPT_DIR}/../lib/framework.sh"
source "${SCRIPT_DIR}/../lib/assertions.sh"

# Load MLEnv
export MLENV_LIB="${PROJECT_ROOT}/lib/mlenv"
source "${MLENV_LIB}/utils/logging.sh"
source "${MLENV_LIB}/config/parser.sh"

# Test setup
test_setup() {
    # Create temp config file
    TEST_CONFIG_FILE=$(mktemp)
    cat > "$TEST_CONFIG_FILE" <<'EOF'
# Test configuration
[core]
log_level = debug
version = 2.0.0

[container]
adapter = docker
default_image = test:latest
EOF
}

# Test teardown
test_teardown() {
    rm -f "$TEST_CONFIG_FILE"
    unset MLENV_CONFIG
    declare -gA MLENV_CONFIG
}

# Tests

test_config_parse_file() {
    config_parse_file "$TEST_CONFIG_FILE"
    assert_equals "debug" "$(config_get 'core.log_level')" "Should parse log_level"
    assert_equals "2.0.0" "$(config_get 'core.version')" "Should parse version"
    assert_equals "docker" "$(config_get 'container.adapter')" "Should parse adapter"
}

test_config_get_with_default() {
    config_parse_file "$TEST_CONFIG_FILE"
    assert_equals "debug" "$(config_get 'core.log_level' 'info')" "Should return actual value"
    assert_equals "default" "$(config_get 'nonexistent.key' 'default')" "Should return default"
}

test_config_set() {
    config_set "test.key" "test_value"
    assert_equals "test_value" "$(config_get 'test.key')" "Should set and get value"
}

test_config_has() {
    config_set "test.key" "value"
    assert_true "config_has 'test.key'" "Should find existing key"
    assert_false "config_has 'nonexistent.key'" "Should not find non-existent key"
}

test_config_parse_comments() {
    cat > "$TEST_CONFIG_FILE" <<'EOF'
# This is a comment
[section]
key = value
; This is also a comment
EOF
    config_parse_file "$TEST_CONFIG_FILE"
    assert_equals "value" "$(config_get 'section.key')" "Should skip comments"
}

test_config_parse_empty_lines() {
    cat > "$TEST_CONFIG_FILE" <<'EOF'
[section]

key = value


[another]
key2 = value2
EOF
    config_parse_file "$TEST_CONFIG_FILE"
    assert_equals "value" "$(config_get 'section.key')" "Should handle empty lines"
    assert_equals "value2" "$(config_get 'another.key2')" "Should parse multiple sections"
}

# Run tests
main() {
    test_suite_begin "Config Parser Tests"
    
    test_run_with_hooks test_config_parse_file
    test_run_with_hooks test_config_get_with_default
    test_run_with_hooks test_config_set
    test_run_with_hooks test_config_has
    test_run_with_hooks test_config_parse_comments
    test_run_with_hooks test_config_parse_empty_lines
    
    test_suite_end
}

main "$@"
