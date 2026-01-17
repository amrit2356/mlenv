# Command: `mlenv up`

## Synopsis

```bash
mlenv up [OPTIONS]
```

## Description

Creates and starts a new container in the current directory. If a container already exists for this project, starts it. Supports automatic GPU detection, resource limits, and requirements installation.

**File**: `lib/mlenv/commands/up.sh`

## Options

| Option | Argument | Description |
|--------|----------|-------------|
| `--image` | `<image>` | Docker image to use |
| `--requirements` | `<file>` | Requirements file to install |
| `--force-requirements` | - | Force reinstall requirements |
| `--gpu` | `<devices>` | GPU devices (e.g., `0,1` or `all`) |
| `--auto-gpu` | - | Auto-detect free GPUs |
| `--port` | `<mapping>` | Port mapping (e.g., `8888:8888`) |
| `--memory` | `<size>` | Memory limit (e.g., `32g`) |
| `--cpus` | `<count>` | CPU limit (e.g., `8`) |
| `--env-file` | `<file>` | Environment file to load |
| `--no-user-mapping` | - | Don't map host user |
| `--verbose` | - | Verbose output |

## Examples

### Basic Usage

```bash
# Start with default image
mlenv up

# Start with specific image
mlenv up --image nvcr.io/nvidia/pytorch:25.12-py3

# Start with all GPUs
mlenv up --gpu all
```

### Auto GPU Detection

```bash
# Let MLEnv select free GPUs
mlenv up --auto-gpu

# Auto-select with memory limit
mlenv up --auto-gpu --memory 64g
```

### Requirements Installation

```bash
# Install from requirements.txt
mlenv up --requirements requirements.txt

# Force reinstall
mlenv up --force-requirements

# Different requirements file
mlenv up --requirements requirements-gpu.txt
```

### Port Mapping

```bash
# Map single port
mlenv up --port 8888:8888

# Map multiple ports
mlenv up --port 8888:8888 --port 6006:6006

# Auto port for Jupyter
mlenv jupyter  # Automatically maps 8888
```

### Resource Limits

```bash
# Set memory and CPU limits
mlenv up --memory 32g --cpus 16

# With specific GPUs
mlenv up --memory 64g --cpus 32 --gpu 0,1,2,3
```

### Advanced Usage

```bash
# Complete example
mlenv up \
    --image nvcr.io/nvidia/pytorch:25.12-py3 \
    --requirements requirements.txt \
    --gpu 0,1 \
    --memory 64g \
    --cpus 16 \
    --port 8888:8888 \
    --port 6006:6006 \
    --env-file .env \
    --verbose
```

## Behavior

### Container States

| Current State | Action |
|---------------|--------|
| No container | Create new container |
| Stopped container | Start existing container |
| Running container | Do nothing (success) |

### Admission Control

Before creating a container, checks:
- System memory usage < 85%
- System CPU usage < 90%
- Available memory > 4GB
- Project quotas not exceeded

If checks fail, container creation is denied.

### Requirements Installation

Requirements are installed if:
- `--requirements` specified AND
- (No marker file OR `--force-requirements`)

**Caching**: Requirements hash is checked to avoid redundant installs.

### GPU Allocation

**Manual**: `--gpu 0,1`
- Allocates specified GPUs
- Fails if GPUs not available

**Automatic**: `--auto-gpu`
- Detects free GPUs
- Allocates least-utilized GPUs
- Skips GPU if none available (warns)

## Implementation Details

### Flow

```
1. Initialize context
2. Validate prerequisites (Docker running)
3. Admission control check
4. Check container status
5. If exists and running → Done
6. If exists and stopped → Start
7. If not exists → Create
8. Install requirements (if needed)
9. Update database
10. Display success message
```

### Context Fields Used

```bash
ctx[container_name]    # Container identifier
ctx[workdir]           # Project directory
ctx[image]             # Docker image
ctx[requirements_path] # Requirements file
ctx[gpu_devices]       # GPU allocation
ctx[memory_limit]      # Memory limit
ctx[cpu_limit]         # CPU limit
ctx[ports]             # Port mappings
ctx[env_file]          # Environment file
```

### Dependencies

```bash
# Core modules
container_create()
container_start()
container_get_status()

# Resource management
admission_check_container_creation()
resource_tracking_init()

# GPU detection
gpu_auto_detect_free()

# Utilities
cleanup_init()
retry()
```

## Exit Codes

| Code | Condition |
|------|-----------|
| 0 | Container created or started successfully |
| 1 | General error (container creation failed) |
| 2 | Invalid arguments |
| 3 | Docker not running |
| 4 | Admission control denied |

## Files Modified

- `$PROJECT_DIR/.mlenv/mlenv.log` - Log file
- `$PROJECT_DIR/.mlenv/.requirements_installed` - Requirements marker
- `$PROJECT_DIR/.devcontainer/devcontainer.json` - VS Code config (if not exists)
- `/var/mlenv/state/mlenv.db` - Database (container record)

## Environment Variables

| Variable | Description |
|----------|-------------|
| `MLENV_DEFAULT_IMAGE` | Default image if `--image` not specified |
| `MLENV_AUTO_DETECT_GPU` | Enable auto-GPU by default |
| `MLENV_ENABLE_ADMISSION_CONTROL` | Enable/disable admission control |

## Configuration

Can be configured via `.mlenvrc`:

```ini
[container]
default_image = nvcr.io/nvidia/pytorch:25.12-py3
memory_limit = 32g
cpu_limit = 16

[gpu]
auto_detect = true
default_allocation = 0,1

[requirements]
auto_install = true
cache_hash = true
```

## Error Messages

### Docker Not Running
```
✖ Error: Docker is not running
  Start Docker: sudo systemctl start docker
```

### Admission Control Denied
```
✖ Error: Insufficient resources to create container
  System memory usage: 92% (threshold: 85%)
  System CPU usage: 95% (threshold: 90%)
  
  Free up resources or adjust thresholds in /etc/mlenv/mlenv.conf
```

### Image Not Found
```
✖ Error: Image not found: nvcr.io/nvidia/pytorch:invalid
  
  Suggestions:
  - Check image name spelling
  - Login to NGC: mlenv login
  - Search available images: mlenv catalog search pytorch
```

### GPU Not Available
```
✖ Error: GPU 0 not available
  Available GPUs: 1, 2, 3
  
  Use --gpu 1 or --auto-gpu
```

## Performance

**Cold start** (first time):
- Image pull: 2-5 minutes (depends on image size)
- Container create: 5-10 seconds
- Requirements install: 30-120 seconds (depends on packages)

**Warm start** (container exists):
- Container start: 2-5 seconds

## Troubleshooting

### Container Name Conflict
```bash
# Different project in same directory name
mlenv rm  # Remove old container
mlenv up  # Create new
```

### Out of Memory During Creation
```bash
# Reduce memory limit
mlenv up --memory 16g  # Instead of 32g
```

### GPU Not Detected
```bash
# Check NVIDIA drivers
nvidia-smi

# Check Docker GPU support
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi
```

## See Also

- [`mlenv down`](down.md) - Stop container
- [`mlenv exec`](exec.md) - Execute in container
- [`mlenv jupyter`](jupyter.md) - Start Jupyter Lab
- [`mlenv status`](status.md) - Container status
- [Architecture Overview](../../architecture/overview.md)

## Source Code

**File**: `lib/mlenv/commands/up.sh`

**Key Functions**:
- `cmd_up()` - Main command handler
- `cmd_init_context()` - Context initialization
- `admission_check_container_creation()` - Resource checks

---

**Last Updated**: 2026-01-18  
**Version**: 2.0.0
