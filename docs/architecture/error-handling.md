# Error Handling

## Overview

MLEnv implements comprehensive error handling at every layer with clear error messages, proper exit codes, and graceful degradation.

## Error Handling Strategy

### 1. Error Categories

**Fatal Errors** - Stop execution immediately
```bash
die() {
    error "$@"
    exit 1
}

# Usage
[[ ! -x "$(command -v docker)" ]] && die "Docker not found"
```

**Non-Fatal Errors** - Log and continue
```bash
error() {
    echo "✖ Error: $*" >&2
}

# Usage
if ! container_stop "$name"; then
    error "Failed to stop container: $name"
    # Continue with cleanup
fi
```

**Warnings** - Informational, no action required
```bash
warn() {
    echo "⚠ Warning: $*" >&2
}

# Usage
warn "GPU not detected, running in CPU mode"
```

### 2. Exit Codes

| Code | Meaning | Usage |
|------|---------|-------|
| 0 | Success | Normal completion |
| 1 | General error | Default error |
| 2 | Invalid arguments | Bad CLI usage |
| 3 | Prerequisites not met | Docker not installed, etc. |
| 4 | Resource error | Admission control failure |
| 5 | Configuration error | Invalid config |
| 125 | Docker error | Docker daemon issue |
| 126 | Permission denied | Need sudo |
| 127 | Command not found | Missing binary |

**Usage**:
```bash
cmd_up() {
    # Check prerequisites
    if ! docker ps >/dev/null 2>&1; then
        error "Docker is not running"
        return 3  # Prerequisites not met
    fi
    
    # Check resources
    if ! admission_check; then
        error "Insufficient resources"
        return 4  # Resource error
    fi
    
    # Create container
    if ! container_create "$name" "$image"; then
        error "Failed to create container"
        return 1  # General error
    fi
    
    return 0  # Success
}
```

### 3. Error Context

Always provide context in error messages:

```bash
# ❌ BAD
error "Failed"

# ✅ GOOD
error "Failed to create container '$container_name': Image '$image' not found"
```

### 4. Stack Traces

For debugging, enable stack traces:

```bash
set_error_trace() {
    set -eEuo pipefail
    trap 'error_trace $? $LINENO "$BASH_COMMAND"' ERR
}

error_trace() {
    local exit_code=$1
    local line=$2
    local command=$3
    
    error "Command failed (exit $exit_code) at line $line: $command"
    error "Call stack:"
    
    local frame=0
    while caller $frame; do
        ((frame++))
    done
}
```

### 5. Cleanup on Error

Use trap for cleanup:

```bash
cmd_up() {
    cleanup_init
    
    # Register cleanup
    cleanup_register "container_remove '$container_name'"
    
    # Create resources
    if ! container_create "$container_name"; then
        # Cleanup automatically runs
        return 1
    fi
    
    # Success - disable cleanup
    cleanup_disable
    return 0
}
```

## Error Sources

### 1. CLI Errors

```bash
# Unknown command
if ! valid_command "$command"; then
    error "Unknown command: $command"
    error "Run 'mlenv help' for usage"
    exit 2
fi

# Missing required argument
if [[ -z "$image" ]]; then
    error "Missing required argument: --image"
    error "Usage: mlenv up --image <image>"
    exit 2
fi
```

### 2. Validation Errors

```bash
# Invalid container name
if ! validate_container_name "$name"; then
    error "Invalid container name: $name"
    error "Name must be alphanumeric with dashes/underscores"
    exit 2
fi

# Invalid memory format
if ! validate_memory_format "$memory"; then
    error "Invalid memory format: $memory"
    error "Use format like: 32g, 16384m"
    exit 2
fi
```

### 3. Docker Errors

```bash
# Docker daemon not running
if ! docker ps >/dev/null 2>&1; then
    error "Docker is not running"
    error "Start Docker: sudo systemctl start docker"
    exit 125
fi

# Permission denied
if docker ps 2>&1 | grep -q "permission denied"; then
    error "Permission denied"
    error "Add user to docker group: sudo usermod -aG docker $USER"
    exit 126
fi
```

### 4. Resource Errors

```bash
# Admission control failure
if ! admission_check_memory; then
    error "Insufficient memory"
    error "System memory usage: 92% (threshold: 85%)"
    error "Free up memory or adjust threshold"
    exit 4
fi

# GPU not available
if ! gpu_available "$gpu_id"; then
    error "GPU $gpu_id not available"
    error "Available GPUs: $(gpu_list_available)"
    exit 4
fi
```

### 5. Configuration Errors

```bash
# Invalid config file
if ! config_parse "$config_file"; then
    error "Failed to parse config: $config_file"
    error "Check syntax at line: $(config_get_error_line)"
    exit 5
fi
```

## Error Recovery

### Retry Logic

```bash
retry() {
    local max_attempts=3
    local delay=2
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if "$@"; then
            return 0
        fi
        
        warn "Attempt $attempt/$max_attempts failed, retrying in ${delay}s..."
        sleep $delay
        ((attempt++))
        ((delay *= 2))
    done
    
    error "Failed after $max_attempts attempts"
    return 1
}

# Usage
retry container_start "$container_name"
```

### Graceful Degradation

```bash
# Try GPU, fall back to CPU
if gpu_available; then
    gpu_args="--gpus all"
else
    warn "GPU not available, using CPU mode"
    gpu_args=""
fi

container_create $gpu_args "$image"
```

### Partial Success

```bash
# Continue on non-critical errors
cleanup_containers() {
    local failed=0
    
    for container in $containers; do
        if ! container_remove "$container"; then
            error "Failed to remove: $container"
            ((failed++))
        fi
    done
    
    if [[ $failed -gt 0 ]]; then
        warn "$failed containers failed to remove"
        return 1
    fi
    
    return 0
}
```

## User-Friendly Messages

### Before (v1.x)
```
Error: failed
```

### After (v2.0)
```
✖ Error: Failed to create container 'mlenv-project-abc123'
  Cause: Image 'nvcr.io/nvidia/pytorch:invalid' not found
  
  Suggestions:
  - Check image name spelling
  - Login to NGC: mlenv login
  - Search available images: mlenv catalog search pytorch
  
  Run 'mlenv help up' for more information
```

## Further Reading

- [Utilities API - Error Handling](../api/utils/error.md)
- [Testing Error Cases](../../docs.backup/development/phase5-testing.md)

---

**Last Updated**: 2026-01-18  
**Version**: 2.0.0
