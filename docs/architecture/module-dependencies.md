# Module Dependencies

## Dependency Graph

```
┌─────────────────────────────────────────────────────────────┐
│                         bin/mlenv                            │
│                      (CLI Entry Point)                       │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    lib/mlenv/core/engine.sh                  │
│             (Initialization & Orchestration)                 │
└──┬──────────────────┬─────────────────┬─────────────────────┘
   │                  │                 │
   │                  ▼                 ▼
   │      ┌──────────────────┐  ┌──────────────────┐
   │      │  config/         │  │  utils/          │
   │      │  - parser.sh     │  │  - logging.sh    │
   │      │  - defaults.sh   │  │  - error.sh      │
   │      │  - accessor.sh   │  │  - validation.sh │
   │      └──────────────────┘  └──────────────────┘
   │
   ▼
┌────────────────────────────────────────────────────────────┐
│                   lib/mlenv/commands/                       │
│    up│down│exec│jupyter│status│logs│rm│restart│init│...    │
└─────┬──────────────────────────────────────────────────────┘
      │
      ▼
┌────────────────────────────────────────────────────────────┐
│                      lib/mlenv/core/                        │
│  container│image│gpu│auth│context│devcontainer             │
└─────┬──────────────────────────────────────────────────────┘
      │
      ▼
┌────────────────────────────────────────────────────────────┐
│              lib/mlenv/adapters/interfaces/                 │
│         container-port│image-port│auth-port                 │
└─────┬──────────────────────────────────────────────────────┘
      │
      ▼
┌────────────────────────────────────────────────────────────┐
│                  lib/mlenv/adapters/                        │
│          container/docker│registry/ngc                      │
└────────────────────────────────────────────────────────────┘
```

## Dependency Rules

### 1. **Utilities** - No Dependencies
```
utils/
├── logging.sh       (standalone)
├── error.sh         (standalone)
├── validation.sh    (standalone)
└── ...
```

**Rule**: Utility modules must not depend on other MLEnv modules.

### 2. **Configuration** - Only Utils
```
config/
├── parser.sh        → utils/{logging,error}
├── defaults.sh      → (none)
├── accessor.sh      → utils/logging
└── validator.sh     → utils/{validation,error}
```

**Rule**: Config modules can only depend on utils.

### 3. **Core** - Config + Utils
```
core/
├── engine.sh        → {config/*,utils/*}
├── context.sh       → utils/{logging,validation}
├── container.sh     → utils/*
├── image.sh         → utils/*
├── gpu.sh           → utils/*
└── auth.sh          → utils/*
```

**Rule**: Core modules depend on config and utils, NOT on adapters directly.

### 4. **Ports** - Utils Only
```
adapters/interfaces/
├── container-port.sh   → utils/{error,logging}
├── image-port.sh       → utils/{error,logging}
└── auth-port.sh        → utils/{error,logging}
```

**Rule**: Ports define interfaces, minimal dependencies.

### 5. **Adapters** - Ports + Utils
```
adapters/
├── container/docker.sh    → {interfaces/container-port,utils/*}
└── registry/ngc.sh        → {interfaces/auth-port,utils/*}
```

**Rule**: Adapters implement ports, depend on ports and utils.

### 6. **Commands** - Everything
```
commands/
├── up.sh       → {core/*,adapters/interfaces/*,utils/*,config/*}
├── exec.sh     → {core/*,adapters/interfaces/*,utils/*}
└── ...
```

**Rule**: Commands orchestrate, can depend on any module.

### 7. **CLI** - Commands Only
```
bin/mlenv → {commands/*,core/engine}
```

**Rule**: CLI routes to commands, minimal logic.

## File Dependencies

### bin/mlenv
```bash
# Direct dependencies
source "${MLENV_LIB}/core/engine.sh"
source "${MLENV_LIB}/commands/*.sh"

# Indirect (via engine.sh)
# - config/*
# - utils/*
# - core/*
# - adapters/interfaces/*
```

### core/engine.sh
```bash
# Utilities
source "${MLENV_LIB}/utils/logging.sh"
source "${MLENV_LIB}/utils/error.sh"
source "${MLENV_LIB}/utils/validation.sh"

# Configuration
source "${MLENV_LIB}/config/parser.sh"
source "${MLENV_LIB}/config/defaults.sh"
source "${MLENV_LIB}/config/accessor.sh"
source "${MLENV_LIB}/config/validator.sh"

# Core
source "${MLENV_LIB}/core/context.sh"
source "${MLENV_LIB}/core/container.sh"
source "${MLENV_LIB}/core/image.sh"
source "${MLENV_LIB}/core/auth.sh"
source "${MLENV_LIB}/core/devcontainer.sh"

# Ports
source "${MLENV_LIB}/adapters/interfaces/container-port.sh"
source "${MLENV_LIB}/adapters/interfaces/image-port.sh"
source "${MLENV_LIB}/adapters/interfaces/auth-port.sh"
```

### commands/up.sh
```bash
# Utilities
source "${MLENV_LIB}/utils/cleanup.sh"
source "${MLENV_LIB}/utils/command-helpers.sh"
source "${MLENV_LIB}/utils/retry.sh"
source "${MLENV_LIB}/utils/resource-tracker.sh"

# Resource management
source "${MLENV_LIB}/resource/admission.sh"

# All others inherited from engine.sh
```

### adapters/container/docker.sh
```bash
# Port interface (must implement)
# container-port.sh already loaded by engine

# Utilities
source "${MLENV_LIB}/utils/logging.sh"
source "${MLENV_LIB}/utils/error.sh"
source "${MLENV_LIB}/utils/retry.sh"
```

## Circular Dependency Prevention

### ❌ BAD - Circular Dependency
```
utils/validation.sh → config/accessor.sh → utils/validation.sh
```

### ✅ GOOD - One-Way Dependency
```
config/accessor.sh → utils/validation.sh
(utils never imports config)
```

## Dependency Injection

### Port Example
```bash
# Core depends on interface, not implementation
container_create() {
    # Calls port, which delegates to adapter
    "${MLENV_ACTIVE_CONTAINER_ADAPTER}_container_create" "$@"
}

# Adapter injected at runtime
engine_load_container_adapter "docker"
# Now container_create() calls docker_container_create()
```

### Configuration Example
```bash
# Commands receive config, don't load it
cmd_up() {
    # Config already loaded by engine
    local image=$(config_get_effective "container.default_image")
    
    # Use it
    container_create "$image"
}
```

## Module Loading Order

```
1. Utilities (logging, error, validation)
   ↓
2. Configuration (parser, defaults, accessor)
   ↓
3. Core (engine, context, container, image, gpu, auth)
   ↓
4. Ports (container-port, image-port, auth-port)
   ↓
5. Adapters (loaded dynamically by engine)
   ↓
6. Commands (loaded by CLI)
```

## Testing Dependencies

### Unit Tests
```
test → mock_adapter → test_subject
(no real adapter dependencies)
```

### Integration Tests
```
test → real_adapter → external_system
(full dependency chain)
```

## Further Reading

- [Architecture Overview](overview.md)
- [Hexagonal Design](hexagonal-design.md)
- [Adapter Pattern](adapter-pattern.md)

---

**Last Updated**: 2026-01-18  
**Version**: 2.0.0
