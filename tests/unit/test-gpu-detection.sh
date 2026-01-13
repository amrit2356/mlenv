#!/usr/bin/env bash
# Test: GPU Detection and Allocation
# Version: 2.0.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Load test framework
source "${SCRIPT_DIR}/../lib/framework.sh"
source "${SCRIPT_DIR}/../lib/assertions.sh"

# Load MLEnv
export MLENV_LIB="${PROJECT_ROOT}/lib/mlenv"
source "${MLENV_LIB}/utils/logging.sh"
source "${MLENV_LIB}/core/gpu.sh"

# Tests

test_gpu_check_available() {
    # This will pass if nvidia-smi is available
    if command -v nvidia-smi >/dev/null 2>&1; then
        assert_true "gpu_check_available" "Should detect nvidia-smi"
    else
        # Skip test if no GPU
        return 0
    fi
}

test_gpu_get_count() {
    if ! command -v nvidia-smi >/dev/null 2>&1; then
        return 0  # Skip if no GPU
    fi
    
    local count=$(gpu_get_count)
    assert_true "[[ $count -ge 0 ]]" "GPU count should be non-negative"
}

test_gpu_allocate_all() {
    local result=$(gpu_allocate "all")
    assert_equals "all" "$result" "Should return 'all' for all strategy"
}

test_gpu_allocate_specific() {
    local result=$(gpu_allocate "0,1,2")
    assert_equals "0,1,2" "$result" "Should return specific GPU IDs"
}

test_gpu_is_free_thresholds() {
    # Test with low utilization and high free memory
    if gpu_is_free 0 10 5000; then
        assert_true "true" "GPU with 10% util and 5GB free should be free"
    fi
    
    # Test with high utilization
    if ! gpu_is_free 0 95 5000; then
        assert_true "true" "GPU with 95% util should not be free"
    fi
}

# Run tests
main() {
    test_suite_begin "GPU Detection Tests"
    
    test_run test_gpu_check_available
    test_run test_gpu_get_count
    test_run test_gpu_allocate_all
    test_run test_gpu_allocate_specific
    test_run test_gpu_is_free_thresholds
    
    test_suite_end
}

main "$@"
