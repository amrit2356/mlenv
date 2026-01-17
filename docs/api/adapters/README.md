# Adapters API Reference

## Overview

Adapters implement external system integrations using the Ports & Adapters pattern. Core logic depends on abstract ports, not concrete adapters.

**Location**: `lib/mlenv/adapters/`

## Adapter Types

### Ports (Interfaces)
**Location**: `lib/mlenv/adapters/interfaces/`

| Port | Description | File |
|------|-------------|------|
| [Container Port](container-port.md) | Container operations interface | `container-port.sh` |
| [Image Port](image-port.md) | Image operations interface | `image-port.sh` |
| [Auth Port](auth-port.md) | Authentication interface | `auth-port.sh` |

### Implementations
**Location**: `lib/mlenv/adapters/container/`, `lib/mlenv/adapters/registry/`

| Adapter | Description | File |
|---------|-------------|------|
| [Docker Adapter](docker-adapter.md) | Docker container implementation | `container/docker.sh` |
| [NGC Adapter](ngc-adapter.md) | NVIDIA NGC registry | `registry/ngc.sh` |
| [Custom Adapters](custom-adapters.md) | Creating your own adapters | - |

## Quick Start

### Using Adapters

```bash
# Adapters loaded automatically by engine
source lib/mlenv/core/engine.sh
engine_init  # Loads Docker adapter by default

# Use via port interface
container_create "--name" "test" "nginx"
# → Delegates to docker_container_create()
```

### Creating Custom Adapter

See [Custom Adapters Guide](custom-adapters.md) for complete tutorial.

```bash
# 1. Create file
touch lib/mlenv/adapters/container/podman.sh

# 2. Implement all port methods
podman_container_create() { podman run "$@"; }
podman_container_start() { podman start "$1"; }
# ... etc

# 3. Use it
mlenv up --adapter podman
```

## Further Reading

- [Hexagonal Architecture](../../architecture/hexagonal-design.md)
- [Adapter Pattern](../../architecture/adapter-pattern.md)
- [Custom Adapters Guide](custom-adapters.md)

---

**Last Updated**: 2026-01-18
