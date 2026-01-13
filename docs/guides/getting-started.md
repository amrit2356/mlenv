---
layout: page
title: Getting Started
---

# Getting Started with MLEnv

This guide will help you install MLEnv and run your first GPU-accelerated container in minutes.

## Prerequisites

Before installing MLEnv, ensure you have:

### Required
- **Docker** (>= 20.10)
- **sqlite3** (>= 3.0)
- **bash** (>= 4.0)

### Optional
- **jq** - JSON parsing (recommended)
- **nvidia-smi** - GPU support
- **NVIDIA Container Toolkit** - GPU passthrough

### Verify Prerequisites

```bash
# Check Docker
docker --version
docker info

# Check sqlite
sqlite3 --version

# Check bash
bash --version

# Check GPU support (optional)
nvidia-smi
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi
```

## Installation

### Method 1: Install Script (Recommended)

```bash
# Clone repository
git clone https://github.com/your-username/mlenv.git
cd mlenv

# Check prerequisites
./install.sh check

# Install system-wide
sudo ./install.sh

# Verify installation
mlenv version
```

### Method 2: Debian Package

```bash
# Download package
wget https://github.com/your-username/mlenv/releases/download/v2.0.0/mlenv_2.0.0_amd64.deb

# Install
sudo dpkg -i mlenv_2.0.0_amd64.deb
sudo apt-get install -f
```

### Method 3: From Source

```bash
git clone https://github.com/your-username/mlenv.git
cd mlenv

export MLENV_LIB=$(pwd)/lib/mlenv
./bin/mlenv version
```

## First Steps

### 1. Verify Installation

```bash
mlenv version
# Output:
# MLEnv - ML Environment Manager v2.0.0
# MLEnv Engine v2.0.0
# Container Adapter: docker
# Registry Adapter: ngc
```

### 2. Check GPU Support

```bash
mlenv gpu status
# Shows all available GPUs and their status
```

### 3. Generate Configuration (Optional)

```bash
mlenv config generate
# Creates ~/.mlenvrc with defaults

# Edit to customize
vi ~/.mlenvrc
```

## Create Your First Project

### Quick Start (Minimal)

```bash
# Create project directory
mkdir my-first-project
cd my-first-project

# Start container
mlenv up

# Enter container
mlenv exec

# You're in! Try:
python3 -c "import torch; print(torch.cuda.is_available())"

# Exit
exit

# Stop container
mlenv down
```

### With Template (Recommended)

```bash
# List available templates
mlenv init --list

# Create PyTorch project
mlenv init --template pytorch my-pytorch-project

# Navigate to project
cd my-pytorch-project

# Start with auto-GPU
mlenv up --auto-gpu --requirements requirements.txt

# Enter container
mlenv exec

# Training code is already there!
python train.py
```

## Common Workflows

### Workflow 1: Interactive Development

```bash
mlenv up --port 8888:8888
mlenv exec

# Inside container:
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser

# Open http://localhost:8888 in browser
```

### Workflow 2: Run Training Script

```bash
mlenv up --auto-gpu
mlenv exec -c "python train.py --epochs 100"
```

### Workflow 3: Multi-GPU Training

```bash
# Auto-select 4 free GPUs
mlenv up --auto-gpu --gpu-count 4

# Run distributed training
mlenv exec -c "torchrun --nproc_per_node=4 train_ddp.py"
```

## Configuration

### Create ~/.mlenvrc

```bash
mlenv config generate
```

### Example Configuration

```ini
[gpu]
default_devices = all
auto_detect_free = true

[network]
default_ports = 8888:8888,6006:6006

[container]
default_image = nvcr.io/nvidia/pytorch:25.12-py3
```

### Use Configuration

```bash
# Config is automatically loaded
mlenv up
# Uses settings from ~/.mlenvrc
```

## Troubleshooting

### Docker Not Running

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### GPU Not Detected

```bash
# Install NVIDIA Container Toolkit
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

### Permission Denied

```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

## Next Steps

- [User Guide](user-guide.md) - Complete feature documentation
- [Configuration Reference](../reference/configuration.md) - All config options
- [Templates](../reference/templates.md) - Template system details
- [Best Practices](best-practices.md) - Recommendations

---

**Ready to start?** → [User Guide](user-guide.md)
