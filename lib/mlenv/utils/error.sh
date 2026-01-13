#!/usr/bin/env bash
# MLEnv Error Handling
# Version: 2.0.0

# Source logging
source "${MLENV_LIB:-/usr/local/lib/mlenv}/utils/logging.sh"

# Exit with error message
die() {
    local message="$1"
    local exit_code="${2:-1}"
    
    error "$message"
    exit "$exit_code"
}

# Assert condition
assert() {
    local condition="$1"
    local message="${2:-Assertion failed}"
    
    if ! eval "$condition"; then
        die "$message" 2
    fi
}

# Require command exists
require_command() {
    local cmd="$1"
    local install_msg="${2:-Install $cmd and try again}"
    
    if ! command -v "$cmd" >/dev/null 2>&1; then
        die "$cmd is not installed. $install_msg"
    fi
}

# Require file exists
require_file() {
    local file="$1"
    local message="${2:-Required file not found: $file}"
    
    if [[ ! -f "$file" ]]; then
        die "$message"
    fi
}

# Require directory exists
require_directory() {
    local dir="$1"
    local message="${2:-Required directory not found: $dir}"
    
    if [[ ! -d "$dir" ]]; then
        die "$message"
    fi
}

# Try command with fallback
try() {
    local cmd="$1"
    local error_msg="${2:-Command failed: $cmd}"
    
    if ! eval "$cmd"; then
        error "$error_msg"
        return 1
    fi
    return 0
}

# Validate non-empty
require_non_empty() {
    local value="$1"
    local name="$2"
    
    if [[ -z "$value" ]]; then
        die "$name cannot be empty"
    fi
}

# Error codes
declare -A MLENV_ERROR_CODES=(
    [SUCCESS]=0
    [GENERAL_ERROR]=1
    [ASSERTION_FAILED]=2
    [COMMAND_NOT_FOUND]=3
    [FILE_NOT_FOUND]=4
    [PERMISSION_DENIED]=5
    [INVALID_ARGUMENT]=6
    [CONTAINER_ERROR]=10
    [IMAGE_ERROR]=11
    [AUTH_ERROR]=12
    [CONFIG_ERROR]=13
    [RESOURCE_ERROR]=14
)

# Exit with named error code
die_with_code() {
    local message="$1"
    local code_name="$2"
    local code="${MLENV_ERROR_CODES[$code_name]:-1}"
    
    die "$message" "$code"
}
