# Hexagonal Architecture (Ports & Adapters)

## Introduction

MLEnv v2.0 implements **Hexagonal Architecture**, also known as the **Ports and Adapters pattern**. This architectural pattern isolates core business logic from external concerns, making the system modular, testable, and extensible.

## What is Hexagonal Architecture?

### The Problem

In traditional layered architecture:
```
[UI] → [Business Logic] → [Database/External Systems]
```

**Issues**:
- Business logic tightly coupled to infrastructure
- Hard to test without external systems
- Difficult to swap implementations
- Changes ripple through layers

### The Solution

Hexagonal architecture inverts dependencies:
```
        ┌──────────────────┐
        │   Core Business  │
        │      Logic       │
        │   (Domain Layer) │
        └────────┬─────────┘
                 │
        ┌────────┴─────────┐
        │                  │
   ┌────▼────┐       ┌────▼────┐
   │  Port   │       │  Port   │
   │(Interface)│     │(Interface)│
   └────┬────┘       └────┬────┘
        │                  │
   ┌────▼────┐       ┌────▼────┐
   │ Adapter │       │ Adapter │
   │ (Docker)│       │  (NGC)  │
   └─────────┘       └─────────┘
        │                  │
   [Docker Daemon]    [NGC API]
```

## MLEnv's Hexagonal Structure

### The Hexagon

```
                    ┌─────────────────┐
                    │       CLI       │
                    │   (bin/mlenv)   │
                    └────────┬────────┘
                             │
         ┌───────────────────┴───────────────────┐
         │                                       │
    ┌────▼──────┐                        ┌──────▼────┐
    │ Commands  │                        │ Commands  │
    │  (up)     │                        │  (exec)   │
    └────┬──────┘                        └──────┬────┘
         │                                       │
         │    ┌──────────────────────────┐      │
         └────►  Core Business Logic     ◄──────┘
              │  - Container Management  │
              │  - GPU Detection         │
              │  - Config Management     │
              │  - Context Management    │
              └─────────┬────────────────┘
                        │
         ┌──────────────┴──────────────┐
         │                              │
    ┌────▼────┐                   ┌────▼────┐
    │  Port   │                   │  Port   │
    │Container│                   │  Image  │
    └────┬────┘                   └────┬────┘
         │                              │
    ┌────▼────┐                   ┌────▼────┐
    │ Adapter │                   │ Adapter │
    │ Docker  │                   │   NGC   │
    └────┬────┘                   └────┬────┘
         │                              │
    [Docker]                       [NGC API]
```

## Core Concepts

### 1. Core (The Hexagon Center)

**Location**: `lib/mlenv/core/`

**Contains**: Pure business logic with no external dependencies

**Modules**:
- `engine.sh` - System initialization
- `container.sh` - Container lifecycle logic
- `image.sh` - Image management logic
- `gpu.sh` - GPU detection logic
- `auth.sh` - Authentication logic
- `context.sh` - Context management
- `devcontainer.sh` - VS Code integration

**Key Principle**: Core logic never directly calls external systems. It only calls **ports** (interfaces).

**Example**:
```bash
# core/container.sh - Business logic
container_create_with_gpu() {
    local container_name="$1"
    local image="$2"
    local gpu_devices="$3"
    
    # Business logic: validate inputs
    validate_container_name "$container_name"
    validate_image_name "$image"
    
    # Business logic: prepare parameters
    local -a docker_args=()
    docker_args+=("--name" "$container_name")
    docker_args+=("--gpus" "$gpu_devices")
    
    # Call PORT, not adapter directly
    container_create "${docker_args[@]}" "$image"
}
```

---

### 2. Ports (Interfaces)

**Location**: `lib/mlenv/adapters/interfaces/`

**Purpose**: Define contracts that adapters must implement

**Types**:
- **Inbound Ports** - Called by core (e.g., container operations)
- **Outbound Ports** - Called to external systems (e.g., Docker, NGC)

#### Container Port Example

```bash
# adapters/interfaces/container-port.sh

# Define interface contract
declare -A CONTAINER_PORT_METHODS=(
    [create]="container_create"
    [start]="container_start"
    [stop]="container_stop"
    [remove]="container_remove"
    [exec]="container_exec"
    [inspect]="container_inspect"
    [list]="container_list"
    [logs]="container_logs"
    [exists]="container_exists"
    [is_running]="container_is_running"
)

# Validate adapter implements all methods
container_port_validate_adapter() {
    local adapter="$1"
    local missing=()
    
    for method in "${CONTAINER_PORT_METHODS[@]}"; do
        if ! declare -f "${adapter}_${method}" >/dev/null 2>&1; then
            missing+=("$method")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Adapter '$adapter' missing methods: ${missing[*]}"
        return 1
    fi
    
    return 0
}

# Port function - delegates to active adapter
container_create() {
    if [[ -z "$MLENV_ACTIVE_CONTAINER_ADAPTER" ]]; then
        die "No container adapter loaded"
    fi
    "${MLENV_ACTIVE_CONTAINER_ADAPTER}_container_create" "$@"
}
```

**Benefits**:
- Core code is adapter-agnostic
- Easy to swap implementations
- Testable with mock adapters
- Clear contract documentation

---

### 3. Adapters (Implementations)

**Location**: `lib/mlenv/adapters/`

**Purpose**: Implement ports to interact with external systems

#### Docker Adapter Example

```bash
# adapters/container/docker.sh

# Implement the port interface
docker_container_create() {
    local -a docker_args=("$@")
    local image="${docker_args[-1]}"
    unset 'docker_args[-1]'
    
    # Adapter-specific implementation
    if ! docker run -d "${docker_args[@]}" "$image"; then
        error "Failed to create container with Docker"
        return 1
    fi
    
    return 0
}

docker_container_start() {
    local container_name="$1"
    docker start "$container_name"
}

docker_container_stop() {
    local container_name="$1"
    docker stop "$container_name"
}

# ... implement all other port methods
```

#### Future: Podman Adapter

```bash
# adapters/container/podman.sh

# Same interface, different implementation
podman_container_create() {
    local -a podman_args=("$@")
    local image="${podman_args[-1]}"
    unset 'podman_args[-1]'
    
    # Podman-specific implementation
    podman run -d "${podman_args[@]}" "$image"
}

podman_container_start() {
    local container_name="$1"
    podman start "$container_name"
}

# ... etc
```

**Switching Adapters**:
```bash
# In config file or CLI
MLENV_CONTAINER_ADAPTER="podman"
# or
mlenv up --adapter podman
```

---

## Dependency Flow

### Traditional Architecture (BAD)
```
Core Logic
    ↓ (depends on)
Docker Library
    ↓
Docker Daemon
```

**Problem**: Core logic is tightly coupled to Docker

### Hexagonal Architecture (GOOD)
```
Core Logic
    ↓ (depends on)
Container Port (Interface)
    ↑ (implements)
Docker Adapter
    ↓
Docker Daemon
```

**Benefit**: Core logic depends on abstraction, not implementation

### Dependency Inversion Principle

```bash
# Before (v1.x) - Tight coupling
cmd_up() {
    # Direct Docker dependency
    docker run -d --name "$container_name" "$image"
}

# After (v2.0) - Loose coupling
cmd_up() {
    # Depends on port (interface), not Docker
    container_create "--name" "$container_name" "$image"
}
```

---

## Benefits of Hexagonal Architecture

### 1. ✅ Testability

**Unit Tests** - Mock adapters:
```bash
# Test core logic without Docker
mock_container_create() {
    echo "mock-container-id"
    return 0
}

# Swap in mock adapter
export MLENV_ACTIVE_CONTAINER_ADAPTER="mock"

# Test core logic
test_container_creation() {
    # Calls mock_container_create instead of docker_container_create
    result=$(container_create --name "test" "nginx")
    assert_equals "mock-container-id" "$result"
}
```

**Integration Tests** - Real adapters:
```bash
# Test Docker adapter implementation
test_docker_adapter() {
    export MLENV_ACTIVE_CONTAINER_ADAPTER="docker"
    
    # Test actual Docker calls
    container_create --name "test" "nginx"
    assert_container_exists "test"
}
```

---

### 2. ✅ Extensibility

**Add Podman Support** (1 hour):
```bash
# 1. Create adapter
$ vim lib/mlenv/adapters/container/podman.sh

# 2. Implement all port methods
podman_container_create() { ... }
podman_container_start() { ... }
# ... etc

# 3. No changes to core needed!

# 4. Use it
$ mlenv up --adapter podman
```

**Add Kubernetes Support** (future):
```bash
# Create k8s adapter
$ vim lib/mlenv/adapters/container/kubernetes.sh

# Implement port interface
k8s_container_create() {
    kubectl run ...
}

# Done! Core logic unchanged
```

---

### 3. ✅ Maintainability

**Clear Boundaries**:
```
Core ← Port → Adapter
 │       │        │
 │       │        └─ External system details
 │       └─ Contract definition
 └─ Business logic only
```

**Easy to Understand**:
- Read core logic without adapter details
- Read adapter without understanding core
- Port defines clear contract

---

### 4. ✅ Flexibility

**Swap Adapters at Runtime**:
```bash
# Development: Use Docker Desktop
mlenv up --adapter docker

# Production: Use Podman (rootless)
mlenv up --adapter podman

# Cloud: Use Kubernetes
mlenv up --adapter kubernetes
```

**Multiple Adapters**:
```bash
# Load multiple adapters
engine_load_container_adapter "docker"
engine_load_container_adapter "podman"

# Choose at command time
mlenv up --adapter docker
mlenv up --adapter podman
```

---

## Implementation Details

### Adapter Loading

```bash
# core/engine.sh

engine_init_adapters() {
    local container_adapter=$(config_get "container.adapter" "docker")
    local registry_adapter=$(config_get "registry.default" "ngc")
    
    # Load container adapter
    engine_load_container_adapter "$container_adapter"
    
    # Load registry adapter
    engine_load_registry_adapter "$registry_adapter"
}

engine_load_container_adapter() {
    local adapter="$1"
    local adapter_path="${MLENV_LIB}/adapters/container/${adapter}.sh"
    
    # Verify adapter exists
    if [[ ! -f "$adapter_path" ]]; then
        die "Container adapter not found: $adapter"
    fi
    
    # Load adapter
    source "$adapter_path"
    
    # Validate adapter implements port
    if ! container_port_validate_adapter "$adapter"; then
        die "Adapter validation failed: $adapter"
    fi
    
    # Initialize adapter
    if declare -f "${adapter}_adapter_init" >/dev/null 2>&1; then
        "${adapter}_adapter_init"
    fi
    
    # Set as active
    export MLENV_ACTIVE_CONTAINER_ADAPTER="$adapter"
    vlog "Container adapter loaded: $adapter"
}
```

### Port Delegation

```bash
# adapters/interfaces/container-port.sh

container_create() {
    # Verify adapter is loaded
    if [[ -z "$MLENV_ACTIVE_CONTAINER_ADAPTER" ]]; then
        die "No container adapter loaded"
    fi
    
    # Delegate to adapter implementation
    "${MLENV_ACTIVE_CONTAINER_ADAPTER}_container_create" "$@"
}
```

---

## Comparison: Before vs After

### v1.x (Monolithic)

```bash
# mlenv (one file, 1188 lines)
cmd_up() {
    # Direct Docker coupling
    docker run -d \
        --name "$CONTAINER_NAME" \
        --gpus all \
        "$IMAGE"
}
```

**Issues**:
- Can't test without Docker
- Can't use Podman
- Docker logic mixed with business logic

### v2.0 (Hexagonal)

```bash
# commands/up.sh
cmd_up() {
    # Business logic only
    declare -A ctx
    cmd_init_context ctx
    
    # Call port
    container_create \
        "--name" "${ctx[container_name]}" \
        "--gpus" "${ctx[gpu_devices]}" \
        "${ctx[image]}"
}

# adapters/interfaces/container-port.sh
container_create() {
    # Delegate to adapter
    "${MLENV_ACTIVE_CONTAINER_ADAPTER}_container_create" "$@"
}

# adapters/container/docker.sh
docker_container_create() {
    # Docker-specific implementation
    docker run -d "$@"
}
```

**Benefits**:
- ✅ Core logic testable with mocks
- ✅ Easy to add Podman support
- ✅ Clear separation of concerns

---

## Testing Strategy

### Unit Tests (Mock Adapters)
```bash
#!/usr/bin/env bash
# tests/unit/test-container-logic.sh

# Create mock adapter
mock_container_create() {
    echo "mock-container-123"
    return 0
}

mock_container_start() {
    return 0
}

# Export as active adapter
export MLENV_ACTIVE_CONTAINER_ADAPTER="mock"

# Test core logic without Docker
test_container_creation_logic() {
    declare -A ctx
    ctx[container_name]="test"
    ctx[image]="nginx"
    
    # Core logic calls mock adapter
    local id=$(container_create "--name" "${ctx[container_name]}" "${ctx[image]}")
    
    assert_equals "mock-container-123" "$id"
}
```

### Integration Tests (Real Adapters)
```bash
#!/usr/bin/env bash
# tests/integration/test-docker-adapter.sh

# Use real Docker adapter
export MLENV_ACTIVE_CONTAINER_ADAPTER="docker"

test_docker_container_lifecycle() {
    # Test actual Docker calls
    container_create "--name" "test-container" "nginx"
    assert_command_succeeds "docker ps --filter name=test-container"
    
    container_stop "test-container"
    assert_command_succeeds "docker ps -a --filter name=test-container"
    
    container_remove "test-container"
    assert_command_fails "docker ps -a --filter name=test-container"
}
```

---

## Best Practices

### 1. Core Never Calls Adapters Directly
```bash
# ❌ BAD
cmd_up() {
    docker run ...  # Direct adapter call
}

# ✅ GOOD
cmd_up() {
    container_create ...  # Call port
}
```

### 2. All External Calls Go Through Ports
```bash
# ❌ BAD
curl https://api.ngc.nvidia.com/...  # Direct API call

# ✅ GOOD
ngc_api_call "/api/endpoint"  # Through port
```

### 3. Ports Are Interfaces Only
```bash
# ❌ BAD - Port contains logic
container_create() {
    validate_name "$1"  # Logic in port
    "${ADAPTER}_container_create" "$@"
}

# ✅ GOOD - Port delegates only
container_create() {
    "${MLENV_ACTIVE_CONTAINER_ADAPTER}_container_create" "$@"
}
```

### 4. Adapters Implement Complete Interface
```bash
# ✅ Adapter must implement all port methods
docker_container_create() { ... }
docker_container_start() { ... }
docker_container_stop() { ... }
docker_container_remove() { ... }
# ... etc
```

---

## Further Reading

- [Architecture Overview](overview.md)
- [Module Dependencies](module-dependencies.md)
- [Creating Custom Adapters](../api/adapters/custom-adapters.md)
- [Testing Guide](../../docs.backup/development/phase5-testing.md)

## External Resources

- [Hexagonal Architecture](https://alistair.cockburn.us/hexagonal-architecture/) by Alistair Cockburn
- [Ports and Adapters Pattern](https://herbertograca.com/2017/11/16/explicit-architecture-01-ddd-hexagonal-onion-clean-cqrs-how-i-put-it-all-together/)

---

**Last Updated**: 2026-01-18  
**Version**: 2.0.0
