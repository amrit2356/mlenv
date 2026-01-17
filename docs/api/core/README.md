# Core API Reference

## Overview

Core modules implement MLEnv's business logic: container lifecycle, GPU detection, authentication, configuration, and context management.

**Location**: `lib/mlenv/core/`

## Core Modules

| Module | Description | File |
|--------|-------------|------|
| [**Engine**](engine.md) | System initialization & orchestration | `engine.sh` |
| [**Context**](context.md) | Context object management | `context.sh` |
| [**Container**](container.md) | Container lifecycle operations | `container.sh` |
| [**Image**](image.md) | Image management | `image.sh` |
| [**GPU**](gpu.md) | GPU detection & allocation | `gpu.sh` |
| [**Auth**](auth.md) | Authentication & credentials | `auth.sh` |
| [**Devcontainer**](devcontainer.md) | VS Code integration | `devcontainer.sh` |

## Module Responsibilities

### engine.sh - System Initialization

```bash
# Initialize MLEnv engine
engine_init()

# Apply configuration to environment
engine_apply_config()

# Initialize adapters
engine_init_adapters()

# Load specific adapter
engine_load_container_adapter "docker"
engine_load_registry_adapter "ngc"
```

**Responsibilities**:
- Load all dependencies
- Initialize configuration system
- Load and validate adapters
- Export environment variables

---

### context.sh - State Management

```bash
# Create context object
declare -A ctx
mlenv_context_create ctx

# Validate context
mlenv_context_validate ctx

# Export to environment (backward compat)
mlenv_context_export ctx
```

**Responsibilities**:
- Create structured context
- Validate required fields
- Export for legacy code

---

### container.sh - Container Operations

```bash
# High-level operations
container_create_from_context ctx
container_start_from_context ctx
container_stop_from_context ctx

# Low-level operations (via ports)
container_create <args>
container_start <name>
container_stop <name>
container_remove <name>
container_exec <name> <cmd>

# Status checks
container_exists <name>
container_is_running <name>
container_get_status <name>
```

**Responsibilities**:
- Container lifecycle management
- Status queries
- Port forwarding setup
- Requirements installation

---

### image.sh - Image Management

```bash
# Pull image if not exists
image_ensure_available <image>

# Check if image exists locally
image_exists_locally <image>

# Pull image
image_pull <image>

# Get image metadata
image_get_tag <image>
image_get_digest <image>
```

**Responsibilities**:
- Image availability checks
- Image pulling
- Image metadata

---

### gpu.sh - GPU Operations

```bash
# Check if GPU available
gpu_available

# List all GPUs
gpu_list_all

# List free GPUs
gpu_list_available

# Auto-detect free GPUs
gpu_auto_detect_free <count>

# Get GPU utilization
gpu_get_utilization <gpu_id>

# Allocate GPU to container
gpu_allocate <gpu_id> <container_name>

# Release GPU
gpu_release <gpu_id> <container_name>
```

**Responsibilities**:
- GPU detection
- GPU allocation
- Utilization monitoring

---

### auth.sh - Authentication

```bash
# NGC authentication
ngc_login <api_key>
ngc_logout
ngc_is_authenticated
ngc_get_api_key

# Credential storage
auth_save_credential <service> <credential>
auth_load_credential <service>
auth_clear_credential <service>
```

**Responsibilities**:
- NGC authentication
- Credential storage (secure)
- Authentication status

---

### devcontainer.sh - VS Code Integration

```bash
# Generate devcontainer.json
devcontainer_generate <project_dir> <image> <extensions...>

# Check if devcontainer exists
devcontainer_exists <project_dir>

# Update devcontainer
devcontainer_update <project_dir> <settings>
```

**Responsibilities**:
- Generate `.devcontainer/devcontainer.json`
- Configure VS Code settings
- Manage extensions

---

## Common Patterns

### Using Core Modules

```bash
# In commands
cmd_up() {
    # 1. Create context
    declare -A ctx
    mlenv_context_create ctx
    
    # 2. Use core modules
    if ! container_exists "${ctx[container_name]}"; then
        container_create_from_context ctx
    fi
    
    container_start "${ctx[container_name]}"
}
```

### Error Handling

```bash
# All core functions return exit codes
if ! container_create "$name" "$image"; then
    error "Failed to create container"
    return 1
fi
```

### Logging

```bash
# Core modules use structured logging
vlog "Creating container: $name"  # Verbose only
log_info "Container created: $name"  # Always
log_error "Failed to create container"  # Errors
```

## Dependency Graph

```
engine.sh
  ├─→ config/*
  ├─→ utils/*
  ├─→ context.sh
  ├─→ container.sh
  ├─→ image.sh
  ├─→ gpu.sh
  ├─→ auth.sh
  └─→ devcontainer.sh

container.sh → adapters/interfaces/container-port.sh
image.sh → adapters/interfaces/image-port.sh
auth.sh → adapters/interfaces/auth-port.sh
```

## Core vs Commands

| Layer | Responsibility | Example |
|-------|----------------|---------|
| **Commands** | Orchestration, validation, user interaction | `cmd_up()` - validate inputs, create context, call core |
| **Core** | Business logic, no user interaction | `container_create()` - create container, no validation |

## Testing

### Unit Tests

```bash
# Mock adapters
export MLENV_ACTIVE_CONTAINER_ADAPTER="mock"

# Test core logic
test_container_create() {
    result=$(container_create "--name" "test" "nginx")
    assert_equals "mock-container-id" "$result"
}
```

### Integration Tests

```bash
# Real adapters
export MLENV_ACTIVE_CONTAINER_ADAPTER="docker"

# Test with Docker
test_container_lifecycle() {
    container_create "--name" "test" "nginx"
    container_start "test"
    container_stop "test"
    container_remove "test"
}
```

## Examples

### Complete Container Creation

```bash
#!/usr/bin/env bash

# Initialize engine
source lib/mlenv/core/engine.sh
engine_init

# Create context
declare -A ctx
ctx[container_name]="my-container"
ctx[workdir]="/home/user/project"
ctx[image]="nvcr.io/nvidia/pytorch:25.12-py3"
ctx[gpu_devices]="0,1"

# Create container
container_create_from_context ctx

# Start container
container_start "${ctx[container_name]}"

# Check status
if container_is_running "${ctx[container_name]}"; then
    echo "Container is running!"
fi
```

### Auto GPU Detection

```bash
# Detect 2 free GPUs
gpus=$(gpu_auto_detect_free 2)

if [[ -n "$gpus" ]]; then
    echo "Allocated GPUs: $gpus"
    container_create "--gpus" "$gpus" "pytorch"
else
    echo "No GPUs available, using CPU"
    container_create "pytorch"
fi
```

## Further Reading

- [Architecture Overview](../../architecture/overview.md)
- [Hexagonal Design](../../architecture/hexagonal-design.md)
- [Commands API](../commands/README.md)
- [Adapters API](../adapters/README.md)

---

**Last Updated**: 2026-01-18  
**Version**: 2.0.0
