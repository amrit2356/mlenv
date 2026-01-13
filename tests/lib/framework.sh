#!/usr/bin/env bash
# MLEnv Test Framework
# Version: 2.0.0

# Test counters
TEST_PASSED=0
TEST_FAILED=0
TEST_SKIPPED=0
TEST_TOTAL=0

# Test output
TEST_VERBOSE=false
TEST_OUTPUT_FILE=""

# Colors
if [[ -t 1 ]]; then
    COLOR_RED='\033[0;31m'
    COLOR_GREEN='\033[0;32m'
    COLOR_YELLOW='\033[1;33m'
    COLOR_BLUE='\033[0;34m'
    COLOR_RESET='\033[0m'
else
    COLOR_RED=''
    COLOR_GREEN=''
    COLOR_YELLOW=''
    COLOR_BLUE=''
    COLOR_RESET=''
fi

# Test suite info
TEST_SUITE_NAME=""
TEST_SUITE_START_TIME=0

# Start test suite
test_suite_begin() {
    local name="$1"
    TEST_SUITE_NAME="$name"
    TEST_SUITE_START_TIME=$(date +%s)
    
    echo ""
    echo "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo "${COLOR_BLUE}Test Suite: $name${COLOR_RESET}"
    echo "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo ""
}

# End test suite
test_suite_end() {
    local end_time=$(date +%s)
    local duration=$((end_time - TEST_SUITE_START_TIME))
    
    echo ""
    echo "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo "${COLOR_BLUE}Test Suite Complete: $TEST_SUITE_NAME${COLOR_RESET}"
    echo "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo ""
    echo "Tests run: $TEST_TOTAL"
    echo "${COLOR_GREEN}Passed: $TEST_PASSED${COLOR_RESET}"
    echo "${COLOR_RED}Failed: $TEST_FAILED${COLOR_RESET}"
    echo "${COLOR_YELLOW}Skipped: $TEST_SKIPPED${COLOR_RESET}"
    echo "Duration: ${duration}s"
    echo ""
    
    if [[ $TEST_FAILED -gt 0 ]]; then
        return 1
    fi
    return 0
}

# Run a test
test_run() {
    local test_name="$1"
    ((TEST_TOTAL++))
    
    echo -n "  Testing: $test_name ... "
    
    if "$test_name" >/dev/null 2>&1; then
        echo "${COLOR_GREEN}✓ PASS${COLOR_RESET}"
        ((TEST_PASSED++))
        return 0
    else
        echo "${COLOR_RED}✗ FAIL${COLOR_RESET}"
        ((TEST_FAILED++))
        return 1
    fi
}

# Skip a test
test_skip() {
    local test_name="$1"
    local reason="${2:-No reason provided}"
    ((TEST_TOTAL++))
    ((TEST_SKIPPED++))
    
    echo "  Testing: $test_name ... ${COLOR_YELLOW}⊘ SKIPPED${COLOR_RESET} ($reason)"
}

# Setup function (override in test files)
test_setup() {
    true
}

# Teardown function (override in test files)
test_teardown() {
    true
}

# Run test with setup/teardown
test_run_with_hooks() {
    local test_name="$1"
    
    test_setup
    test_run "$test_name"
    local result=$?
    test_teardown
    
    return $result
}
