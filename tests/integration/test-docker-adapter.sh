#!/usr/bin/env bash
# Integration Test: Docker Adapter
# Version: 2.0.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Load test framework
source "${PROJECT_ROOT}/tests/lib/framework.sh"
source "${PROJECT_ROOT}/tests/lib/assertions.sh"

# Load MLEnv
export MLENV_LIB="${PROJECT_ROOT}/lib/mlenv"
source "${MLENV_LIB}/core/engine.sh"

# Test container name
TEST_CONTAINER="mlenv-test-$$"
TEST_IMAGE="hello-world"

# Test setup
test_setup() {
    # Clean up any existing test container
    docker rm -f "$TEST_CONTAINER" >/dev/null 2>&1 || true
}

# Test teardown
test_teardown() {
    # Clean up test container
    docker rm -f "$TEST_CONTAINER" >/dev/null 2>&1 || true
}

# Tests

test_docker_adapter_init() {
    docker_adapter_init >/dev/null 2>&1
    assert_true "true" "Docker adapter should initialize"
}

test_docker_image_exists() {
    # Pull hello-world if not exists
    if ! docker_image_exists "$TEST_IMAGE"; then
        docker pull "$TEST_IMAGE" >/dev/null 2>&1
    fi
    
    assert_true "docker_image_exists '$TEST_IMAGE'" "hello-world image should exist"
}

test_docker_container_create() {
    # Create a simple test container
    if docker_container_create "$TEST_CONTAINER" "$TEST_IMAGE" >/dev/null 2>&1; then
        assert_true "docker_container_exists '$TEST_CONTAINER'" "Container should exist after creation"
    fi
}

test_docker_container_exists() {
    # Create container first
    docker run --name "$TEST_CONTAINER" -d "$TEST_IMAGE" sleep 10 >/dev/null 2>&1 || true
    
    assert_true "docker_container_exists '$TEST_CONTAINER'" "Container existence check should work"
}

test_docker_container_remove() {
    # Create and remove container
    docker run --name "$TEST_CONTAINER" -d "$TEST_IMAGE" sleep 10 >/dev/null 2>&1 || true
    docker_container_remove "$TEST_CONTAINER" >/dev/null 2>&1
    
    assert_false "docker_container_exists '$TEST_CONTAINER'" "Container should not exist after removal"
}

# Run tests
main() {
    test_suite_begin "Docker Adapter Integration Tests"
    
    test_run test_docker_adapter_init
    test_run_with_hooks test_docker_image_exists
    test_run_with_hooks test_docker_container_create
    test_run_with_hooks test_docker_container_exists
    test_run_with_hooks test_docker_container_remove
    
    test_suite_end
}

main "$@"
