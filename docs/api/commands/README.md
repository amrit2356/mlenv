# Commands API Reference

## Overview

MLEnv provides 17 commands for managing ML containers, NGC integration, and project initialization.

## Command List

| Command | Description | File |
|---------|-------------|------|
| [`up`](up.md) | Create and start a container | `lib/mlenv/commands/up.sh` |
| [`down`](down.md) | Stop a running container | `lib/mlenv/commands/down.sh` |
| [`exec`](exec.md) | Execute command in container | `lib/mlenv/commands/exec.sh` |
| [`jupyter`](jupyter.md) | Start Jupyter Lab | `lib/mlenv/commands/jupyter.sh` |
| [`status`](status.md) | Show container status | `lib/mlenv/commands/status.md` |
| [`logs`](logs.md) | View container logs | `lib/mlenv/commands/logs.sh` |
| [`rm`](rm.md) | Remove container | `lib/mlenv/commands/rm.sh` |
| [`restart`](restart.md) | Restart container | `lib/mlenv/commands/restart.sh` |
| [`init`](init.md) | Initialize new project | `lib/mlenv/commands/init.sh` |
| [`clean`](clean.md) | Cleanup resources | `lib/mlenv/commands/clean.sh` |
| [`config`](config.md) | Manage configuration | `lib/mlenv/commands/config.sh` |
| [`catalog`](catalog.md) | Browse NGC catalog | `lib/mlenv/commands/catalog.sh` |
| [`login`](login.md) | Login to NGC | `lib/mlenv/commands/login.sh` |
| [`logout`](logout.md) | Logout from NGC | `lib/mlenv/commands/logout.sh` |
| [`sync`](sync.md) | Sync database state | `lib/mlenv/commands/sync.sh` |
| [`version`](version.md) | Show version info | `lib/mlenv/commands/version.sh` |
| [`help`](help.md) | Show help information | `lib/mlenv/commands/help.sh` |

## Command Categories

### Container Lifecycle
- `up` - Create/start container
- `down` - Stop container
- `restart` - Restart container
- `rm` - Remove container

### Container Interaction
- `exec` - Execute commands
- `jupyter` - Start Jupyter Lab
- `logs` - View logs
- `status` - Check status

### Project Management
- `init` - Initialize project
- `clean` - Cleanup resources
- `config` - Configure settings

### NGC Integration
- `login` - Authenticate
- `logout` - Sign out
- `catalog` - Browse images

### Utilities
- `sync` - Database sync
- `version` - Version info
- `help` - Help system

## Common Patterns

### All Commands Follow This Structure:

```bash
cmd_<name>() {
    # 1. Initialize context
    declare -A ctx
    if ! cmd_init_context ctx; then
        return 1
    fi
    
    # 2. Validate prerequisites
    cmd_require_container_env
    
    # 3. Execute business logic
    # ... command-specific logic ...
    
    # 4. Return exit code
    return 0
}
```

### Context Usage

```bash
# Extract from context
local container_name="${ctx[container_name]}"
local image="${ctx[image]}"
local workdir="${ctx[workdir]}"
```

### Error Handling

```bash
# Fatal error
if ! prerequisite_check; then
    error "Prerequisites not met"
    return 3
fi

# Non-fatal error
if ! optional_operation; then
    warn "Optional operation failed, continuing"
fi
```

### Helper Functions

All commands can use:
- `cmd_init_context` - Initialize context
- `cmd_require_container_env` - Check Docker available
- `cmd_validate_workspace` - Validate workdir
- `cmd_validate_container_name` - Validate name
- `cmd_ensure_directory` - Create directory

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Invalid arguments |
| 3 | Prerequisites not met |
| 4 | Resource error (admission control) |
| 5 | Configuration error |
| 125 | Docker daemon error |
| 126 | Permission denied |

## Quick Examples

### Container Management
```bash
# Create and start
mlenv up --auto-gpu

# Execute command
mlenv exec -c "python train.py"

# Check status
mlenv status

# Stop
mlenv down

# Remove
mlenv rm
```

### Project Initialization
```bash
# Create from template
mlenv init --template pytorch my-project
cd my-project

# Start container
mlenv up
```

### NGC Integration
```bash
# Login
mlenv login

# Search catalog
mlenv catalog search pytorch

# Use image
mlenv up --image nvcr.io/nvidia/pytorch:25.12-py3
```

## Further Reading

- [Architecture Overview](../../architecture/overview.md)
- [Core API](../core/README.md)
- [User Guide](../../docs.backup/guides/getting-started.md)

---

**Last Updated**: 2026-01-18  
**Version**: 2.0.0
