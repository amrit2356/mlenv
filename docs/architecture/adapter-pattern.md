# Adapter Pattern Implementation

## Quick Reference

**Want to add Podman support?** Follow this guide to create a new adapter in ~1 hour.

## Creating an Adapter

### Step 1: Define the Port Interface

Already done! See `lib/mlenv/adapters/interfaces/container-port.sh`

```bash
# Required methods
CONTAINER_PORT_METHODS=(
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
```

### Step 2: Create Adapter File

```bash
# Create new adapter
touch lib/mlenv/adapters/container/podman.sh
chmod +x lib/mlenv/adapters/container/podman.sh
```

### Step 3: Implement All Methods

```bash
#!/usr/bin/env bash
# Podman Container Adapter

# Implement each port method
podman_container_create() {
    local -a args=("$@")
    local image="${args[-1]}"
    unset 'args[-1]'
    
    podman run -d "${args[@]}" "$image"
}

podman_container_start() {
    local container_name="$1"
    podman start "$container_name"
}

podman_container_stop() {
    local container_name="$1"
    podman stop "$container_name"
}

podman_container_remove() {
    local container_name="$1"
    podman rm -f "$container_name"
}

podman_container_exec() {
    local container_name="$1"
    shift
    podman exec -it "$container_name" "$@"
}

podman_container_inspect() {
    local container_name="$1"
    podman inspect "$container_name"
}

podman_container_list() {
    podman ps -a --format "{{.Names}}"
}

podman_container_logs() {
    local container_name="$1"
    podman logs "$container_name"
}

podman_container_exists() {
    local container_name="$1"
    podman ps -a --format "{{.Names}}" | grep -q "^${container_name}$"
}

podman_container_is_running() {
    local container_name="$1"
    podman ps --format "{{.Names}}" | grep -q "^${container_name}$"
}

# Optional: Adapter initialization
podman_adapter_init() {
    vlog "Initializing Podman adapter"
    
    # Check if podman is available
    if ! command -v podman >/dev/null 2>&1; then
        die "Podman not found. Install: sudo apt install podman"
    fi
    
    return 0
}

# Optional: Adapter cleanup
podman_adapter_cleanup() {
    vlog "Cleaning up Podman adapter"
    return 0
}
```

### Step 4: Configure Adapter

```ini
# ~/.mlenvrc or /etc/mlenv/mlenv.conf
[container]
adapter = podman
```

Or use CLI:
```bash
mlenv up --adapter podman
```

### Step 5: Test

```bash
# Unit test
./tests/unit/test-podman-adapter.sh

# Integration test
./tests/integration/test-podman-workflow.sh

# Manual test
mlenv up --adapter podman
```

## Example: NGC Registry Adapter

### Port Interface
```bash
# adapters/interfaces/auth-port.sh
declare -A AUTH_PORT_METHODS=(
    [login]="auth_login"
    [logout]="auth_logout"
    [is_authenticated]="auth_is_authenticated"
    [get_api_key]="auth_get_api_key"
)
```

### NGC Implementation
```bash
# adapters/registry/ngc.sh

ngc_auth_login() {
    local api_key="$1"
    
    # Validate API key
    if ! ngc_validate_api_key "$api_key"; then
        error "Invalid NGC API key"
        return 1
    fi
    
    # Store API key
    echo "$api_key" > "$HOME/.mlenv/ngc_api_key"
    chmod 600 "$HOME/.mlenv/ngc_api_key"
    
    log_info "Logged in to NGC"
    return 0
}

ngc_auth_logout() {
    rm -f "$HOME/.mlenv/ngc_api_key"
    log_info "Logged out from NGC"
    return 0
}

ngc_auth_is_authenticated() {
    [[ -f "$HOME/.mlenv/ngc_api_key" ]]
}

ngc_auth_get_api_key() {
    if ngc_auth_is_authenticated; then
        cat "$HOME/.mlenv/ngc_api_key"
    fi
}
```

## Testing Adapters

### Unit Test with Mock
```bash
# tests/unit/test-adapter.sh

# Mock external command
podman() {
    case "$1" in
        run) echo "mock-container-id"; return 0 ;;
        ps) echo "mock-container-id"; return 0 ;;
        *) return 0 ;;
    esac
}
export -f podman

# Test adapter
test_podman_create() {
    result=$(podman_container_create "--name" "test" "nginx")
    assert_equals "mock-container-id" "$result"
}
```

### Integration Test
```bash
# tests/integration/test-podman-adapter.sh

test_podman_full_lifecycle() {
    export MLENV_ACTIVE_CONTAINER_ADAPTER="podman"
    
    # Create
    container_create "--name" "test-podman" "nginx"
    assert_container_exists "test-podman"
    
    # Start
    container_start "test-podman"
    assert_container_running "test-podman"
    
    # Stop
    container_stop "test-podman"
    assert_container_stopped "test-podman"
    
    # Remove
    container_remove "test-podman"
    assert_container_gone "test-podman"
}
```

## Adapter Examples

### Minimal Adapter (Mock for Testing)
```bash
mock_container_create() { echo "mock-id"; return 0; }
mock_container_start() { return 0; }
mock_container_stop() { return 0; }
mock_container_remove() { return 0; }
mock_container_exec() { return 0; }
mock_container_inspect() { echo "{}"; return 0; }
mock_container_list() { echo "mock-container"; return 0; }
mock_container_logs() { echo "mock logs"; return 0; }
mock_container_exists() { return 0; }
mock_container_is_running() { return 0; }
```

### Kubernetes Adapter (Future)
```bash
k8s_container_create() {
    local -a args=("$@")
    local image="${args[-1]}"
    
    kubectl run "$container_name" --image="$image" ...
}

k8s_container_start() {
    kubectl scale deployment "$container_name" --replicas=1
}

k8s_container_stop() {
    kubectl scale deployment "$container_name" --replicas=0
}
# ... etc
```

## Adapter Best Practices

### 1. Always Validate Interface
```bash
# Engine validates on load
if ! container_port_validate_adapter "podman"; then
    die "Adapter validation failed"
fi
```

### 2. Handle Errors Gracefully
```bash
podman_container_create() {
    if ! podman run ...; then
        error "Podman failed to create container"
        return 1
    fi
    return 0
}
```

### 3. Log Operations
```bash
podman_container_start() {
    vlog "Starting container with Podman: $1"
    podman start "$1"
}
```

### 4. Support Adapter Options
```bash
podman_adapter_init() {
    # Adapter-specific options
    PODMAN_ROOTLESS=${PODMAN_ROOTLESS:-true}
    PODMAN_NETWORK=${PODMAN_NETWORK:-bridge}
}
```

## Further Reading

- [Hexagonal Design](hexagonal-design.md)
- [Custom Adapters Guide](../api/adapters/custom-adapters.md)
- [Docker Adapter Source](../api/adapters/docker-adapter.md)

---

**Last Updated**: 2026-01-18  
**Version**: 2.0.0
