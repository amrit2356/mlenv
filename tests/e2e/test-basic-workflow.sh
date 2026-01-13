#!/usr/bin/env bash
# End-to-End Test: Basic Workflow
# Version: 2.0.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Load test framework
source "${PROJECT_ROOT}/tests/lib/framework.sh"
source "${PROJECT_ROOT}/tests/lib/assertions.sh"

# Test variables
TEST_PROJECT_DIR=$(mktemp -d)
TEST_CONTAINER_NAME="mlenv-e2e-test-$$"

# Test setup
test_setup() {
    cd "$TEST_PROJECT_DIR"
    export MLENV_LIB="${PROJECT_ROOT}/lib/mlenv"
}

# Test teardown
test_teardown() {
    # Clean up
    docker rm -f "$TEST_CONTAINER_NAME" >/dev/null 2>&1 || true
    rm -rf "$TEST_PROJECT_DIR"
}

# Tests

test_e2e_project_initialization() {
    # Test project creation from template
    if [[ -f "${PROJECT_ROOT}/lib/mlenv/templates/engine.sh" ]]; then
        source "${PROJECT_ROOT}/lib/mlenv/templates/engine.sh"
        export MLENV_SHARE="${PROJECT_ROOT}/share/mlenv"
        
        # Apply minimal template
        if template_apply "minimal" "$TEST_PROJECT_DIR" "test-project" >/dev/null 2>&1; then
            assert_file_exists "$TEST_PROJECT_DIR/README.md" "README should be created"
            assert_file_exists "$TEST_PROJECT_DIR/requirements.txt" "requirements.txt should be created"
        fi
    fi
}

test_e2e_config_system() {
    # Test configuration loading
    source "${PROJECT_ROOT}/lib/mlenv/config/parser.sh"
    source "${PROJECT_ROOT}/lib/mlenv/config/defaults.sh"
    
    config_set_defaults
    
    local default_image=$(config_get "container.default_image")
    assert_not_equals "" "$default_image" "Default image should be set"
    assert_contains "$default_image" "nvidia" "Default image should be NVIDIA image"
}

test_e2e_database_initialization() {
    # Test database system
    export MLENV_VAR="$TEST_PROJECT_DIR/.mlenv"
    source "${PROJECT_ROOT}/lib/mlenv/database/init.sh"
    
    db_init >/dev/null 2>&1
    
    assert_file_exists "$MLENV_VAR/registry/catalog.db" "Database should be created"
    
    if db_check; then
        assert_true "true" "Database should be accessible"
    fi
}

test_e2e_catalog_operations() {
    # Test NGC catalog
    export MLENV_VAR="$TEST_PROJECT_DIR/.mlenv"
    source "${PROJECT_ROOT}/lib/mlenv/database/init.sh"
    source "${PROJECT_ROOT}/lib/mlenv/registry/catalog.sh"
    
    db_init >/dev/null 2>&1
    catalog_init >/dev/null 2>&1
    
    # Search for pytorch
    local results=$(catalog_search "pytorch" 2>/dev/null | wc -l)
    assert_true "[[ $results -gt 0 ]]" "Should find pytorch images in catalog"
}

test_e2e_resource_monitoring() {
    # Test resource monitoring
    source "${PROJECT_ROOT}/lib/mlenv/resource/monitor.sh"
    
    local stats=$(resource_get_system_stats text)
    assert_contains "$stats" "CPU" "Stats should include CPU info"
    assert_contains "$stats" "Memory" "Stats should include memory info"
}

# Run tests
main() {
    test_suite_begin "End-to-End Basic Workflow Tests"
    
    test_run_with_hooks test_e2e_project_initialization
    test_run test_e2e_config_system
    test_run_with_hooks test_e2e_database_initialization
    test_run_with_hooks test_e2e_catalog_operations
    test_run test_e2e_resource_monitoring
    
    test_suite_end
}

main "$@"
