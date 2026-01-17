# Context System

## Overview

MLEnv v2.0 uses a **context object pattern** to manage state instead of global variables. This provides better encapsulation, testability, and thread-safety (for future async operations).

## The Problem with Global Variables

### v1.x Approach (Bad)
```bash
# Global variables everywhere
CONTAINER_NAME="mlenv-project-abc123"
WORKDIR="/path/to/project"
IMAGE="nvcr.io/nvidia/pytorch:25.12-py3"
GPU_DEVICES="all"

# Used throughout the codebase
cmd_up() {
    docker run --name "$CONTAINER_NAME" ...
}

cmd_exec() {
    docker exec "$CONTAINER_NAME" ...
}
```

**Problems**:
- Globals pollute namespace
- Hard to test (global state)
- Race conditions (if async)
- Unclear data flow
- No validation of state

## The Context Object Solution

### v2.0 Approach (Good)
```bash
# Create context once
declare -A ctx
mlenv_context_create ctx

# Pass to functions
cmd_up ctx
cmd_exec ctx
```

**Benefits**:
- ✅ Explicit state passing
- ✅ Easy to test (mock context)
- ✅ Clear data flow
- ✅ Validated state
- ✅ Scoped to command

---

## Context Structure

### Context Fields

```bash
declare -A ctx=(
    # Environment
    [version]="2.0.0"
    [workdir]="/home/user/project"
    [project_name]="project"
    [workdir_hash]="abc12345"
    
    # Container
    [container_name]="mlenv-project-abc12345"
    
    # Paths
    [log_dir]="/home/user/project/.mlenv"
    [log_file]="/home/user/project/.mlenv/mlenv.log"
    [requirements_marker]="/home/user/project/.mlenv/.requirements_installed"
    
    # Command Options
    [image]="nvcr.io/nvidia/pytorch:25.12-py3"
    [requirements_path]="requirements.txt"
    [force_requirements]="false"
    [verbose]="false"
    [ports]="8888:8888"
    [jupyter_port]="8888"
    [gpu_devices]="all"
    [env_file]=".env"
    [memory_limit]="32g"
    [cpu_limit]="8"
    [run_as_user]="true"
    [exec_cmd]=""
)
```

---

## Context Lifecycle

### 1. Creation

```bash
# core/context.sh

mlenv_context_create() {
    local -n _ctx_ref=$1
    
    # Get workdir
    local _wd="${WORKDIR:-$(pwd)}"
    local _pn="$(basename "$_wd")"
    local _wh="$(echo "$_wd" | md5sum | cut -c1-8)"
    
    # Generate container name
    local _cn="mlenv-${_pn}-${_wh}"
    local _ld="${_wd}/.mlenv"
    
    # Populate context
    _ctx_ref[version]="2.0.0"
    _ctx_ref[workdir]="$_wd"
    _ctx_ref[project_name]="$_pn"
    _ctx_ref[workdir_hash]="$_wh"
    _ctx_ref[container_name]="$_cn"
    _ctx_ref[log_dir]="$_ld"
    _ctx_ref[log_file]="${_ld}/mlenv.log"
    _ctx_ref[requirements_marker]="${_ld}/.requirements_installed"
    
    # Import from global vars (for CLI compatibility)
    _ctx_ref[image]="${IMAGE:-}"
    _ctx_ref[requirements_path]="${REQUIREMENTS_PATH:-}"
    _ctx_ref[force_requirements]="${FORCE_REQUIREMENTS:-false}"
    _ctx_ref[verbose]="${VERBOSE:-false}"
    _ctx_ref[ports]="${PORTS:-}"
    _ctx_ref[jupyter_port]="${JUPYTER_PORT:-}"
    _ctx_ref[gpu_devices]="${GPU_DEVICES:-}"
    _ctx_ref[env_file]="${ENV_FILE:-}"
    _ctx_ref[memory_limit]="${MEMORY_LIMIT:-}"
    _ctx_ref[cpu_limit]="${CPU_LIMIT:-}"
    _ctx_ref[run_as_user]="${RUN_AS_USER:-true}"
    _ctx_ref[exec_cmd]="${EXEC_CMD:-}"
    
    vlog "Context created for project: $_pn"
}
```

### 2. Validation

```bash
mlenv_context_validate() {
    local -n _ctx_ref=$1
    
    # Check required fields
    if [[ -z "${_ctx_ref[workdir]}" ]]; then
        error "Context missing workdir"
        return 1
    fi
    
    if [[ -z "${_ctx_ref[container_name]}" ]]; then
        error "Context missing container_name"
        return 1
    fi
    
    if [[ -z "${_ctx_ref[project_name]}" ]]; then
        error "Context missing project_name"
        return 1
    fi
    
    return 0
}
```

### 3. Usage in Commands

```bash
# commands/up.sh

cmd_up() {
    # 1. Create context
    declare -A ctx
    if ! cmd_init_context ctx; then
        error "Failed to initialize context"
        return 1
    fi
    
    # 2. Extract values
    local container_name="${ctx[container_name]}"
    local workdir="${ctx[workdir]}"
    local image="${ctx[image]}"
    local gpu_devices="${ctx[gpu_devices]}"
    
    # 3. Use in operations
    container_create \
        "--name" "$container_name" \
        "--workdir" "$workdir" \
        "--gpus" "$gpu_devices" \
        "$image"
}
```

### 4. Export (Backward Compatibility)

```bash
mlenv_context_export() {
    local -n _ctx_ref=$1
    
    # Export to environment for legacy code
    export MLENV_WORKDIR="${_ctx_ref[workdir]}"
    export MLENV_PROJECT_NAME="${_ctx_ref[project_name]}"
    export MLENV_CONTAINER_NAME="${_ctx_ref[container_name]}"
    export MLENV_IMAGE="${_ctx_ref[image]}"
    # ... etc
}
```

---

## Context Flow

### Example: `mlenv up` Command

```
1. CLI receives command
   ↓
2. cmd_up() called
   ↓
3. Create context
   declare -A ctx
   mlenv_context_create ctx
   ↓
4. Validate context
   mlenv_context_validate ctx
   ↓
5. Extract values
   local container_name="${ctx[container_name]}"
   local image="${ctx[image]}"
   ↓
6. Pass to core functions
   container_create "$container_name" "$image"
   ↓
7. Core functions use context
   (don't modify globals)
   ↓
8. Return result
```

---

## Context Patterns

### Pattern 1: Command Initialization

```bash
cmd_init_context() {
    local -n _ctx_ref=$1
    
    # Create context
    mlenv_context_create _ctx_ref
    
    # Validate
    if ! mlenv_context_validate _ctx_ref; then
        return 1
    fi
    
    # Merge with config
    config_merge_into_context _ctx_ref
    
    # Export for compatibility
    mlenv_context_export _ctx_ref
    
    return 0
}
```

### Pattern 2: Passing Context

```bash
# Pass by reference (efficient)
process_container() {
    local -n _ctx_ref=$1
    local extra_arg="$2"
    
    # Access context
    local name="${_ctx_ref[container_name]}"
    
    # Modify context (optional)
    _ctx_ref[status]="running"
}

# Usage
declare -A ctx
process_container ctx "extra"
```

### Pattern 3: Context Cloning

```bash
clone_context() {
    local -n _src_ctx=$1
    local -n _dst_ctx=$2
    
    # Copy all fields
    for key in "${!_src_ctx[@]}"; do
        _dst_ctx[$key]="${_src_ctx[$key]}"
    done
}

# Usage
declare -A ctx1
declare -A ctx2
clone_context ctx1 ctx2
```

---

## Benefits

### 1. Testability

```bash
# Easy to test with mock context
test_container_creation() {
    # Create mock context
    declare -A ctx=(
        [container_name]="test-container"
        [image]="nginx"
        [workdir]="/tmp/test"
    )
    
    # Test function
    result=$(some_function ctx)
    assert_equals "expected" "$result"
}
```

### 2. Isolation

```bash
# Each command has its own context
cmd_up() {
    declare -A ctx  # Local context
    cmd_init_context ctx
    # ... no global pollution
}

cmd_exec() {
    declare -A ctx  # Different context
    cmd_init_context ctx
    # ... independent state
}
```

### 3. Validation

```bash
# Centralized validation
mlenv_context_validate ctx

# vs scattered checks
[[ -z "$WORKDIR" ]] && die "WORKDIR not set"
[[ -z "$CONTAINER_NAME" ]] && die "CONTAINER_NAME not set"
# ... repeated everywhere
```

### 4. Clear Data Flow

```bash
# Clear: context passed explicitly
cmd_up ctx
process_container ctx
create_container ctx

# vs Unclear: globals used implicitly
cmd_up()
process_container()  # Uses global CONTAINER_NAME?
create_container()   # Uses global IMAGE?
```

---

## Implementation Details

### Associative Arrays

```bash
# Bash 4.0+ feature
declare -A ctx

# Set values
ctx[key]="value"

# Get values
value="${ctx[key]}"

# Check existence
if [[ -n "${ctx[key]}" ]]; then
    echo "Key exists"
fi

# Iterate
for key in "${!ctx[@]}"; do
    echo "$key = ${ctx[$key]}"
done
```

### Pass by Reference

```bash
# Pass array by reference (nameref)
function_with_context() {
    local -n _ctx_ref=$1  # Reference to caller's array
    
    # Modify caller's array
    _ctx_ref[new_field]="value"
    
    # Read from caller's array
    local name="${_ctx_ref[container_name]}"
}

# Usage
declare -A ctx
function_with_context ctx
echo "${ctx[new_field]}"  # Prints: value
```

---

## Context vs Configuration

### Context
- **Runtime state**
- Created per command
- Contains computed values
- Mutable during command execution

### Configuration
- **Settings/preferences**
- Loaded once at startup
- Contains user preferences
- Immutable after loading

### Interaction

```bash
cmd_init_context() {
    local -n _ctx_ref=$1
    
    # 1. Create context with computed values
    mlenv_context_create _ctx_ref
    
    # 2. Merge config into context
    config_merge_into_context _ctx_ref
    
    # Context now has:
    # - Computed values (workdir_hash, container_name)
    # - Config values (default_image, gpu_devices)
}
```

---

## Advanced Patterns

### Nested Contexts

```bash
# Parent context
declare -A parent_ctx
mlenv_context_create parent_ctx

# Child context (inherits from parent)
create_child_context() {
    local -n _parent=$1
    local -n _child=$2
    
    # Copy parent
    for key in "${!_parent[@]}"; do
        _child[$key]="${_parent[$key]}"
    done
    
    # Override specific fields
    _child[container_name]="${_child[container_name]}-child"
}

declare -A child_ctx
create_child_context parent_ctx child_ctx
```

### Context Snapshots

```bash
# Save context state
save_context() {
    local -n _ctx_ref=$1
    local snapshot_file="$2"
    
    # Write context to file
    declare -p _ctx_ref > "$snapshot_file"
}

# Restore context state
restore_context() {
    local -n _ctx_ref=$1
    local snapshot_file="$2"
    
    # Load context from file
    source "$snapshot_file"
}
```

---

## Migration from Globals

### Before (v1.x)
```bash
# Global variables
CONTAINER_NAME="mlenv-project"
IMAGE="pytorch:latest"

cmd_up() {
    docker run --name "$CONTAINER_NAME" "$IMAGE"
}

cmd_exec() {
    docker exec "$CONTAINER_NAME" bash
}
```

### After (v2.0)
```bash
# Context object
cmd_up() {
    declare -A ctx
    cmd_init_context ctx
    
    container_create \
        "--name" "${ctx[container_name]}" \
        "${ctx[image]}"
}

cmd_exec() {
    declare -A ctx
    cmd_init_context ctx
    
    container_exec "${ctx[container_name]}" "bash"
}
```

---

## Best Practices

### 1. Always Validate Context
```bash
cmd_up() {
    declare -A ctx
    mlenv_context_create ctx
    
    # Always validate
    if ! mlenv_context_validate ctx; then
        return 1
    fi
    
    # ... proceed
}
```

### 2. Use Descriptive Field Names
```bash
# ✅ GOOD
ctx[container_name]="mlenv-project"
ctx[requirements_path]="requirements.txt"

# ❌ BAD
ctx[cn]="mlenv-project"
ctx[req]="requirements.txt"
```

### 3. Don't Modify Context Unexpectedly
```bash
# ✅ GOOD - Clear modification
update_context_status() {
    local -n _ctx_ref=$1
    _ctx_ref[status]="running"
}

# ❌ BAD - Hidden side effect
get_container_name() {
    local -n _ctx_ref=$1
    _ctx_ref[status]="running"  # Unexpected modification
    echo "${_ctx_ref[container_name]}"
}
```

### 4. Document Context Fields
```bash
# At top of file
# Context fields:
#   - container_name: Container identifier
#   - image: Docker image name
#   - workdir: Project directory
#   - gpu_devices: GPU allocation
```

---

## Troubleshooting

### Issue: Context Not Found
```bash
# Error: bash: _ctx_ref: bad array subscript

# Cause: Context not initialized
cmd_up() {
    # Missing: declare -A ctx
    local name="${ctx[container_name]}"  # Error!
}

# Fix: Initialize context
cmd_up() {
    declare -A ctx
    mlenv_context_create ctx
    local name="${ctx[container_name]}"  # Works!
}
```

### Issue: Empty Context Values
```bash
# Error: Container name is empty

# Cause: Context not populated
declare -A ctx  # Empty!
local name="${ctx[container_name]}"  # Empty string

# Fix: Create context
declare -A ctx
mlenv_context_create ctx  # Populates fields
local name="${ctx[container_name]}"  # Has value
```

---

## Further Reading

- [Architecture Overview](overview.md)
- [Configuration System](config-system.md)
- [Testing with Mock Contexts](../../docs.backup/development/phase5-testing.md)

---

**Last Updated**: 2026-01-18  
**Version**: 2.0.0
