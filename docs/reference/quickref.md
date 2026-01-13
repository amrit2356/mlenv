# MLEnv v2.0.0 - Quick Reference Card

## Installation

```bash
# Install
sudo ./install.sh

# Verify
mlenv version
```

## Configuration

```bash
# Generate config
mlenv config generate

# Edit config
vi ~/.mlenvrc

# View config
mlenv config show

# Set value
mlenv config set gpu.default_devices "0,1"
```

## Project Setup

```bash
# List templates
mlenv init --list

# Create project
mlenv init --template pytorch my-project

# Navigate
cd my-project
```

## Container Management

```bash
# Start (auto-GPU)
mlenv up --auto-gpu

# Start (manual GPU)
mlenv up --gpu 0,1

# Start (with requirements)
mlenv up --requirements requirements.txt

# Enter container
mlenv exec

# Run command
mlenv exec -c "python train.py"

# Stop
mlenv down

# Remove
mlenv rm

# Restart
mlenv restart

# Status
mlenv status
```

## GPU Management

```bash
# Show GPU status
mlenv gpu status

# Auto-detect free GPUs
mlenv up --auto-gpu

# Select 2 free GPUs
mlenv up --auto-gpu --gpu-count 2

# Manual selection
mlenv up --gpu 0,2
```

## Container Operations

```bash
# List all containers
mlenv list

# View logs
mlenv logs

# Clean logs
mlenv clean --logs

# Clean containers
mlenv clean --containers

# Clean everything
mlenv clean --all
```

## NGC Registry

```bash
# Login
mlenv login

# Logout
mlenv logout

# Search images (requires source)
source lib/mlenv/registry/catalog.sh
catalog_search "pytorch"

# List popular
catalog_list_popular
```

## Resource Monitoring

```bash
# System stats (requires source)
source lib/mlenv/resource/monitor.sh
resource_get_system_stats

# Admission check (requires source)
source lib/mlenv/resource/admission.sh
admission_check 16 4 1  # 16GB RAM, 4 CPUs, 1 GPU

# Health check (requires source)
source lib/mlenv/resource/health.sh
health_check_all
```

## Templates

```bash
# List templates
mlenv init --list

# Show template
mlenv template show pytorch

# Apply template
mlenv init --template pytorch my-project

# Create custom template
mlenv template create my-custom-template
```

## Common Workflows

### Quick Start
```bash
mlenv up --auto-gpu
mlenv exec
```

### Full Setup
```bash
mlenv init --template pytorch my-project
cd my-project
mlenv up --auto-gpu --requirements requirements.txt --port 8888:8888
mlenv exec
```

### Jupyter Workflow
```bash
mlenv up --port 8888:8888
mlenv exec -c "jupyter lab --ip=0.0.0.0 --port=8888 --no-browser"
# Open http://localhost:8888
```

### Multi-GPU Training
```bash
mlenv up --auto-gpu --gpu-count 4
mlenv exec -c "torchrun --nproc_per_node=4 train.py"
```

## Configuration File (~/.mlenvrc)

```ini
[core]
log_level = info

[container]
default_image = nvcr.io/nvidia/pytorch:25.12-py3

[gpu]
default_devices = all
auto_detect_free = true

[network]
default_ports = 8888:8888,6006:6006

[resources]
enable_admission_control = true
max_memory_percent = 85
```

## Testing

```bash
# All tests
make test

# Unit tests only
make test-unit

# Integration tests
make test-integration

# Specific test
./tests/unit/test-config-parser.sh
```

## Building Packages

```bash
# Build DEB
make build-deb

# Build RPM
make build-rpm

# Test installation
make test-package
```

## Troubleshooting

```bash
# Check prerequisites
./install.sh check

# View logs
mlenv logs

# Check Docker
docker info

# Check GPUs
nvidia-smi

# Check container
docker ps -a | grep mlenv
```

## Environment Variables

```bash
# Library path
export MLENV_LIB=/usr/local/lib/mlenv

# Log level
export MLENV_LOG_LEVEL=debug

# Verbose mode
export MLENV_VERBOSE=true

# GPU thresholds
export MLENV_GPU_UTIL_THRESHOLD=30
export MLENV_GPU_MIN_FREE_MEM=1000
```

## Exit Codes

```
0 - Success
1 - General error
2 - Assertion failed
3 - Command not found
4 - File not found
10 - Container error
11 - Image error
12 - Authentication error
13 - Configuration error
14 - Resource error
```

## File Locations

```
/usr/local/bin/mlenv                     # Binary
/usr/local/lib/mlenv/                    # Libraries
/etc/mlenv/mlenv.conf                    # System config
~/.mlenvrc                               # User config
.mlenv/config                            # Project config
/var/mlenv/registry/catalog.db           # Database
/usr/local/share/mlenv/templates/        # Templates
```

## Support

- Help: `mlenv help`
- Version: `mlenv version`
- Status: `mlenv status`
- Docs: See README.md

---

**MLEnv v2.0.0 Quick Reference**  
Production-Ready ML Container Platform
