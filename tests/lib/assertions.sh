#!/usr/bin/env bash
# MLEnv Test Assertions
# Version: 2.0.0

# Assert equality
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values are not equal}"
    
    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo "  ASSERTION FAILED: $message"
        echo "    Expected: $expected"
        echo "    Actual:   $actual"
        return 1
    fi
}

# Assert not equals
assert_not_equals() {
    local unexpected="$1"
    local actual="$2"
    local message="${3:-Values should not be equal}"
    
    if [[ "$unexpected" != "$actual" ]]; then
        return 0
    else
        echo "  ASSERTION FAILED: $message"
        echo "    Unexpected: $unexpected"
        echo "    Actual:     $actual"
        return 1
    fi
}

# Assert true
assert_true() {
    local condition="$1"
    local message="${2:-Condition is not true}"
    
    if eval "$condition"; then
        return 0
    else
        echo "  ASSERTION FAILED: $message"
        echo "    Condition: $condition"
        return 1
    fi
}

# Assert false
assert_false() {
    local condition="$1"
    local message="${2:-Condition is not false}"
    
    if ! eval "$condition"; then
        return 0
    else
        echo "  ASSERTION FAILED: $message"
        echo "    Condition: $condition"
        return 1
    fi
}

# Assert file exists
assert_file_exists() {
    local file="$1"
    local message="${2:-File does not exist: $file}"
    
    if [[ -f "$file" ]]; then
        return 0
    else
        echo "  ASSERTION FAILED: $message"
        return 1
    fi
}

# Assert file not exists
assert_file_not_exists() {
    local file="$1"
    local message="${2:-File should not exist: $file}"
    
    if [[ ! -f "$file" ]]; then
        return 0
    else
        echo "  ASSERTION FAILED: $message"
        return 1
    fi
}

# Assert directory exists
assert_dir_exists() {
    local dir="$1"
    local message="${2:-Directory does not exist: $dir}"
    
    if [[ -d "$dir" ]]; then
        return 0
    else
        echo "  ASSERTION FAILED: $message"
        return 1
    fi
}

# Assert command succeeds
assert_success() {
    local cmd="$1"
    local message="${2:-Command failed: $cmd}"
    
    if eval "$cmd" >/dev/null 2>&1; then
        return 0
    else
        echo "  ASSERTION FAILED: $message"
        return 1
    fi
}

# Assert command fails
assert_failure() {
    local cmd="$1"
    local message="${2:-Command should have failed: $cmd}"
    
    if ! eval "$cmd" >/dev/null 2>&1; then
        return 0
    else
        echo "  ASSERTION FAILED: $message"
        return 1
    fi
}

# Assert string contains
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String does not contain: $needle}"
    
    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        echo "  ASSERTION FAILED: $message"
        echo "    Haystack: $haystack"
        echo "    Needle:   $needle"
        return 1
    fi
}

# Assert string not contains
assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should not contain: $needle}"
    
    if [[ "$haystack" != *"$needle"* ]]; then
        return 0
    else
        echo "  ASSERTION FAILED: $message"
        echo "    Haystack: $haystack"
        echo "    Needle:   $needle"
        return 1
    fi
}

# Assert container exists
assert_container_exists() {
    local container="$1"
    local message="${2:-Container does not exist: $container}"
    
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        return 0
    else
        echo "  ASSERTION FAILED: $message"
        return 1
    fi
}

# Assert container running
assert_container_running() {
    local container="$1"
    local message="${2:-Container is not running: $container}"
    
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        return 0
    else
        echo "  ASSERTION FAILED: $message"
        return 1
    fi
}

# Assert image exists
assert_image_exists() {
    local image="$1"
    local message="${2:-Image does not exist: $image}"
    
    if docker image inspect "$image" >/dev/null 2>&1; then
        return 0
    else
        echo "  ASSERTION FAILED: $message"
        return 1
    fi
}
