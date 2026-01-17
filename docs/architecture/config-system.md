# Configuration System

## Overview

MLEnv v2.0 implements a **4-level configuration hierarchy** that provides flexibility while maintaining clear precedence rules. Configuration can come from system defaults, user preferences, project settings, or command-line arguments.

## Configuration Hierarchy

```
┌─────────────────────────────────────┐
│   Level 4: CLI Arguments            │  ← Highest Priority
│   --image, --gpu, --memory, etc.    │
├─────────────────────────────────────┤
│   Level 3: Project Config           │
│   ./.mlenvrc                         │
├─────────────────────────────────────┤
│   Level 2: User Config               │
│   ~/.mlenvrc                         │
├─────────────────────────────────────┤
│   Level 1: System Defaults           │  ← Lowest Priority
│   /etc/mlenv/mlenv.conf             │
│   + Hardcoded defaults               │
└─────────────────────────────────────┘

Precedence: CLI > Project > User > System
```

## Configuration Files

### System Configuration
**Location**: `/etc/mlenv/mlenv.conf`

**Purpose**: System-wide defaults for all users

**Example**:
```ini
[container]
default_image = nvcr.io/nvidia/pytorch:25.12-py3
adapter = docker
auto_remove = false

[resource]
enable_admission_control = true
memory_threshold = 85
cpu_threshold = 90
min_available_memory_gb = 4

[gpu]
auto_detect = true
default_allocation = all

[registry]
default = ngc
api_endpoint = https://api.ngc.nvidia.com/v2

[core]
log_level = info
verbose = false

[paths]
state_dir = /var/mlenv/state
cache_dir = /var/mlenv/cache
templates_dir = /usr/share/mlenv/templates
```

---

### User Configuration
**Location**: `~/.mlenvrc`

**Purpose**: User-specific preferences

**Example**:
```ini
[container]
default_image = nvcr.io/nvidia/pytorch:25.12-py3
memory_limit = 32g
cpu_limit = 8

[gpu]
auto_detect = true
default_allocation = 0,1

[jupyter]
default_port = 8888
auto_start = true

[core]
log_level = debug
verbose = true

[user]
ngc_api_key = ${NGC_API_KEY}
```

---

### Project Configuration
**Location**: `./.mlenvrc` (in project directory)

**Purpose**: Project-specific settings

**Example**:
```ini
[container]
default_image = nvcr.io/nvidia/tensorflow:25.12-tf2-py3
memory_limit = 64g
cpu_limit = 16

[gpu]
default_allocation = all

[requirements]
auto_install = true
cache_hash = true

[ports]
jupyter = 8888
tensorboard = 6006
api = 5000
```

---

## Configuration Modules

### 1. Parser (`config/parser.sh`)

**Purpose**: Parse INI files

```bash
config_parse_file() {
    local config_file="$1"
    local -n result_ref=$2
    
    local current_section=""
    
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue
        
        # Section header
        if [[ "$line" =~ ^\[([^]]+)\] ]]; then
            current_section="${BASH_REMATCH[1]}"
            continue
        fi
        
        # Key=value pair
        if [[ "$line" =~ ^[[:space:]]*([^=]+)=(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            # Trim whitespace
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            
            # Store as section.key
            result_ref["${current_section}.${key}"]="$value"
        fi
    done < "$config_file"
}
```

---

### 2. Defaults (`config/defaults.sh`)

**Purpose**: Hardcoded default values

```bash
config_set_defaults() {
    # Container defaults
    export MLENV_DEFAULT_IMAGE="${MLENV_DEFAULT_IMAGE:-nvcr.io/nvidia/pytorch:25.12-py3}"
    export MLENV_CONTAINER_ADAPTER="${MLENV_CONTAINER_ADAPTER:-docker}"
    export MLENV_AUTO_REMOVE="${MLENV_AUTO_REMOVE:-false}"
    
    # Resource defaults
    export MLENV_ENABLE_ADMISSION_CONTROL="${MLENV_ENABLE_ADMISSION_CONTROL:-true}"
    export MLENV_MEMORY_THRESHOLD="${MLENV_MEMORY_THRESHOLD:-85}"
    export MLENV_CPU_THRESHOLD="${MLENV_CPU_THRESHOLD:-90}"
    export MLENV_MIN_AVAILABLE_MEMORY_GB="${MLENV_MIN_AVAILABLE_MEMORY_GB:-4}"
    
    # GPU defaults
    export MLENV_AUTO_DETECT_GPU="${MLENV_AUTO_DETECT_GPU:-true}"
    export MLENV_DEFAULT_GPU_ALLOCATION="${MLENV_DEFAULT_GPU_ALLOCATION:-all}"
    
    # Registry defaults
    export MLENV_DEFAULT_REGISTRY="${MLENV_DEFAULT_REGISTRY:-ngc}"
    export MLENV_NGC_API_ENDPOINT="${MLENV_NGC_API_ENDPOINT:-https://api.ngc.nvidia.com/v2}"
    
    # Core defaults
    export MLENV_LOG_LEVEL="${MLENV_LOG_LEVEL:-info}"
    export MLENV_VERBOSE="${MLENV_VERBOSE:-false}"
    
    # Path defaults
    export MLENV_STATE_DIR="${MLENV_STATE_DIR:-/var/mlenv/state}"
    export MLENV_CACHE_DIR="${MLENV_CACHE_DIR:-/var/mlenv/cache}"
    export MLENV_TEMPLATES_DIR="${MLENV_TEMPLATES_DIR:-/usr/share/mlenv/templates}"
}
```

---

### 3. Accessor (`config/accessor.sh`)

**Purpose**: Get configuration values with hierarchy

```bash
config_get_effective() {
    local key="$1"
    local default="${2:-}"
    
    # Priority 1: Environment variable (from CLI)
    local env_var="MLENV_${key^^}"
    env_var="${env_var//./_}"
    if [[ -n "${!env_var:-}" ]]; then
        echo "${!env_var}"
        return 0
    fi
    
    # Priority 2: Project config
    if [[ -n "${PROJECT_CONFIG[$key]:-}" ]]; then
        echo "${PROJECT_CONFIG[$key]}"
        return 0
    fi
    
    # Priority 3: User config
    if [[ -n "${USER_CONFIG[$key]:-}" ]]; then
        echo "${USER_CONFIG[$key]}"
        return 0
    fi
    
    # Priority 4: System config
    if [[ -n "${SYSTEM_CONFIG[$key]:-}" ]]; then
        echo "${SYSTEM_CONFIG[$key]}"
        return 0
    fi
    
    # Priority 5: Default value
    echo "$default"
}
```

---

### 4. Validator (`config/validator.sh`)

**Purpose**: Validate configuration values

```bash
config_validate_all() {
    # Validate memory limit
    local memory_limit=$(config_get_effective "container.memory_limit" "")
    if [[ -n "$memory_limit" ]]; then
        if ! validate_memory_format "$memory_limit"; then
            error "Invalid memory_limit: $memory_limit"
            return 1
        fi
    fi
    
    # Validate CPU limit
    local cpu_limit=$(config_get_effective "container.cpu_limit" "")
    if [[ -n "$cpu_limit" ]]; then
        if ! validate_cpu_format "$cpu_limit"; then
            error "Invalid cpu_limit: $cpu_limit"
            return 1
        fi
    fi
    
    # Validate log level
    local log_level=$(config_get_effective "core.log_level" "info")
    if ! validate_log_level "$log_level"; then
        error "Invalid log_level: $log_level"
        return 1
    fi
    
    return 0
}
```

---

## Configuration Loading

### Initialization Flow

```bash
# core/engine.sh

config_init() {
    # 1. Set hardcoded defaults
    config_set_defaults
    
    # 2. Load system config
    if [[ -f "/etc/mlenv/mlenv.conf" ]]; then
        declare -gA SYSTEM_CONFIG
        config_parse_file "/etc/mlenv/mlenv.conf" SYSTEM_CONFIG
    fi
    
    # 3. Load user config
    if [[ -f "$HOME/.mlenvrc" ]]; then
        declare -gA USER_CONFIG
        config_parse_file "$HOME/.mlenvrc" USER_CONFIG
    fi
    
    # 4. Load project config
    if [[ -f ".mlenvrc" ]]; then
        declare -gA PROJECT_CONFIG
        config_parse_file ".mlenvrc" PROJECT_CONFIG
    fi
    
    # 5. CLI arguments already in environment (highest priority)
    
    vlog "Configuration loaded"
}
```

---

## Usage Examples

### Example 1: Get Configuration Value

```bash
# Get default image with hierarchy
image=$(config_get_effective "container.default_image" "ubuntu:22.04")

# Resolution order:
# 1. $MLENV_CONTAINER_DEFAULT_IMAGE (from CLI: --image)
# 2. PROJECT_CONFIG["container.default_image"] (from ./.mlenvrc)
# 3. USER_CONFIG["container.default_image"] (from ~/.mlenvrc)
# 4. SYSTEM_CONFIG["container.default_image"] (from /etc/mlenv/mlenv.conf)
# 5. "ubuntu:22.04" (provided default)
```

### Example 2: Override in Command

```bash
# User config (~/.mlenvrc):
[gpu]
default_allocation = 0

# Command:
mlenv up --gpu 1,2

# Result: Uses GPUs 1,2 (CLI overrides user config)
```

### Example 3: Project-Specific Settings

```bash
# Project A (./.mlenvrc):
[container]
memory_limit = 32g

# Project B (./.mlenvrc):
[container]
memory_limit = 64g

# Each project gets its own memory limit
```

---

## Configuration Schema

### Container Section
```ini
[container]
default_image = <image-name>
adapter = docker|podman|kubernetes
memory_limit = <size>g|m
cpu_limit = <count>
auto_remove = true|false
user_mapping = true|false
```

### Resource Section
```ini
[resource]
enable_admission_control = true|false
memory_threshold = <0-100>
cpu_threshold = <0-100>
min_available_memory_gb = <size>
```

### GPU Section
```ini
[gpu]
auto_detect = true|false
default_allocation = all|<gpu-ids>
require_gpu = true|false
```

### Registry Section
```ini
[registry]
default = ngc|dockerhub
api_endpoint = <url>
cache_ttl = <seconds>
```

### Core Section
```ini
[core]
log_level = debug|info|warn|error
verbose = true|false
color_output = true|false
```

### Jupyter Section
```ini
[jupyter]
default_port = <port>
auto_start = true|false
token = <token>
```

### Paths Section
```ini
[paths]
state_dir = <path>
cache_dir = <path>
templates_dir = <path>
plugins_dir = <path>
```

---

## Environment Variables

All configuration can be set via environment variables:

```bash
# Format: MLENV_<SECTION>_<KEY>
export MLENV_CONTAINER_DEFAULT_IMAGE="pytorch:latest"
export MLENV_GPU_DEFAULT_ALLOCATION="0,1"
export MLENV_CORE_LOG_LEVEL="debug"

# Run command (env vars have highest priority)
mlenv up
```

---

## CLI Override

```bash
# CLI options override all config files
mlenv up \
    --image nvcr.io/nvidia/pytorch:25.12-py3 \
    --gpu 0,1 \
    --memory 64g \
    --cpus 16 \
    --verbose
```

---

## Configuration Profiles

### Multi-Environment Setup

```bash
# ~/.mlenvrc (development)
[container]
default_image = nvcr.io/nvidia/pytorch:25.12-py3-dev
memory_limit = 16g

# /etc/mlenv/mlenv.conf (production)
[container]
default_image = nvcr.io/nvidia/pytorch:25.12-py3
memory_limit = 64g
enable_admission_control = true
```

---

## Best Practices

### 1. Use System Config for Organization Defaults
```ini
# /etc/mlenv/mlenv.conf
[container]
default_image = company-registry.com/ml-base:latest

[resource]
enable_admission_control = true
memory_threshold = 85
```

### 2. Use User Config for Personal Preferences
```ini
# ~/.mlenvrc
[core]
log_level = debug
verbose = true

[gpu]
default_allocation = 0  # Use GPU 0 by default
```

### 3. Use Project Config for Project Settings
```ini
# ./mlenvrc (in project directory)
[container]
default_image = nvcr.io/nvidia/tensorflow:25.12-tf2-py3
memory_limit = 32g

[requirements]
auto_install = true
```

### 4. Use CLI for One-Off Overrides
```bash
# Testing with different GPU
mlenv up --gpu 2

# Testing with more memory
mlenv up --memory 128g
```

---

## Troubleshooting

### Debug Configuration

```bash
# Show effective configuration
mlenv config show

# Show configuration sources
mlenv config show --verbose

# Output:
# container.default_image = nvcr.io/nvidia/pytorch:25.12-py3
#   Source: Project Config (./.mlenvrc)
# 
# gpu.default_allocation = 0,1
#   Source: CLI (--gpu 0,1)
```

### Configuration Conflicts

```bash
# If unexpected value, check hierarchy:
# 1. Check CLI arguments
mlenv up --verbose --gpu <value>

# 2. Check project config
cat .mlenvrc

# 3. Check user config
cat ~/.mlenvrc

# 4. Check system config
cat /etc/mlenv/mlenv.conf

# 5. Check defaults
grep -r "DEFAULT_" lib/mlenv/config/defaults.sh
```

---

## Future Enhancements

### Profiles (Planned v2.1)
```ini
# ~/.mlenvrc
[profile:development]
container.memory_limit = 16g
gpu.default_allocation = 0

[profile:production]
container.memory_limit = 64g
gpu.default_allocation = all
```

Usage:
```bash
mlenv up --profile production
```

### Validation Schemas (Planned v2.2)
```yaml
# config-schema.yaml
container.memory_limit:
  type: size
  min: 1g
  max: 256g

gpu.default_allocation:
  type: gpu_list
  pattern: '^(all|\d+(,\d+)*)$'
```

---

## Further Reading

- [Architecture Overview](overview.md)
- [Context System](context-system.md)
- [Configuration API](../api/config/README.md)

---

**Last Updated**: 2026-01-18  
**Version**: 2.0.0
