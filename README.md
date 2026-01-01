# NGC Container Manager

**Version 1.0.0** | Production-Ready GPU Container Management

A production-grade command-line tool for managing NVIDIA GPU-accelerated Docker containers for deep learning and scientific computing. Simplifies the workflow of running PyTorch, TensorFlow, and other GPU workloads while keeping your code safely on the host machine.

## 🚀 Features

- **Zero-Config GPU Access** - Automatic NVIDIA GPU detection and passthrough
- **Smart Requirements Management** - Hash-based caching prevents redundant pip installs
- **Persistent Workspaces** - Your code stays on the host (bind-mounted)
- **Port Forwarding** - Easy access to Jupyter, TensorBoard, APIs
- **Resource Controls** - Limit CPU, memory, and GPU usage
- **Multi-Project Support** - Unique container names prevent collisions
- **User Mapping** - Run as your user, not root (no permission issues)
- **One-Line Commands** - `ngc jupyter`, `ngc exec -c "train.py"`
- **Auto-Restart** - Containers survive system reboots

## 📋 Prerequisites

- **Docker** (version 20.10+)
- **NVIDIA GPU** with compatible drivers
- **NVIDIA Container Toolkit** ([installation guide](https://github.com/NVIDIA/nvidia-container-toolkit))

Verify your setup:
```bash
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi
```

## 🔧 Installation

### Automatic Installation (Recommended)
```bash
# Clone the repository
git clone https://github.com/your-username/ngc-manager.git
cd ngc-manager

# Run installer (checks prerequisites, installs script + completions)
sudo ./install.sh

# Verify installation
ngc help
```

The installer will:
- ✅ Check Docker and NVIDIA Container Toolkit
- ✅ Install NGC to `/usr/local/bin`
- ✅ Install shell completions (bash/zsh/fish)
- ✅ Test GPU access

### Installation Options
```bash
# Check prerequisites without installing
./install.sh --check

# Install to custom directory (no sudo needed)
./install.sh --install-dir ~/.local/bin

# Force reinstall
sudo ./install.sh --force

# Uninstall
sudo ./install.sh --uninstall
```

### Manual Installation
```bash
# Download and make executable
chmod +x ngc

# Copy to system directory
sudo cp ngc /usr/local/bin/

# Or use without sudo (add to PATH)
mkdir -p ~/.local/bin
cp ngc ~/.local/bin/
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## ⚡ Quick Start

### Basic Usage
```bash
# Start a container
ngc up

# Enter interactive shell
ngc exec

# Run your code (inside container)
python train.py

# Exit (Ctrl+D or type 'exit')
# Container keeps running in background

# Stop when done
ngc down
```

### For Private NGC Images
If you need private container images from NGC:

```bash
# 1. Get API key from https://ngc.nvidia.com/setup/api-key

# 2. Authenticate
ngc login

# 3. Use private images
ngc up --image nvcr.io/your-org/your-private-image:latest
```

**Note:** Public images like `nvcr.io/nvidia/pytorch:25.12-py3` don't require authentication.

### With Jupyter Lab
```bash
# Start with port forwarding
ngc up --port 8888:8888

# Launch Jupyter
ngc jupyter

# Open the URL shown in terminal
# http://localhost:8888/...
```

### With Requirements
```bash
# requirements.txt
# torch==2.1.0
# transformers==4.35.0
# jupyter==1.0.0

ngc up --requirements requirements.txt --port 8888:8888
ngc exec
```

## 📚 Usage

### Commands

| Command | Description |
|---------|-------------|
| `ngc up` | Create/start container |
| `ngc exec` | Open interactive shell |
| `ngc down` | Stop container |
| `ngc restart` | Restart container |
| `ngc rm` | Remove container (keeps code) |
| `ngc status` | Show container and GPU status |
| `ngc jupyter` | Start Jupyter Lab |
| `ngc logs` | View debug logs |
| `ngc clean` | Remove NGC artifacts |
| `ngc help` | Show detailed help |

### Options for `ngc up`

```bash
ngc up [OPTIONS]

Options:
  --image <name>              Docker image (default: nvcr.io/nvidia/pytorch:25.12-py3)
  --requirements <file>       Install Python packages from file
  --force-requirements        Force reinstall even if cached
  --port <mapping>            Port forwarding (e.g., "8888:8888" or "8888:8888,6006:6006")
  --gpu <devices>             GPU devices (e.g., "0,1" or "all", default: all)
  --env-file <file>           Load environment variables from file
  --memory <limit>            Memory limit (e.g., "16g", "32g")
  --cpus <limit>              CPU limit (e.g., "4.0", "8.0")
  --no-user-mapping           Run as root instead of current user
  --verbose                   Enable verbose output
```

### Options for `ngc exec`

```bash
ngc exec [-c <command>]

Options:
  -c <command>                Execute command instead of interactive shell

Examples:
  ngc exec                            # Interactive shell
  ngc exec -c "python train.py"       # Run training script
  ngc exec -c "pip list | grep torch" # Check installed packages
```

## 💡 Examples

### Example 1: PyTorch Deep Learning
```bash
# requirements.txt
torch==2.1.0
torchvision==0.16.0
tensorboard==2.15.0
wandb==0.16.0

# .env
WANDB_API_KEY=your_api_key_here
CUDA_VISIBLE_DEVICES=0,1

# Setup environment
ngc up \
  --requirements requirements.txt \
  --env-file .env \
  --port 6006:6006 \
  --gpu 0,1 \
  --memory 32g

# Start training
ngc exec -c "python train.py --batch-size 64 --epochs 100"

# Monitor with TensorBoard (in another terminal)
ngc exec -c "tensorboard --logdir runs --host 0.0.0.0"
# Open: http://localhost:6006
```

### Example 2: Jupyter Notebook Development
```bash
# Start container with Jupyter port
ngc up --requirements requirements.txt --port 8888:8888

# Launch Jupyter Lab
ngc jupyter

# Open the provided URL in your browser
# Notebooks saved in /workspace are automatically synced to host
```

### Example 3: Distributed Training (Multi-GPU)
```bash
# Use all available GPUs
ngc up --requirements requirements.txt --gpu all

# Run distributed training
ngc exec -c "torchrun --nproc_per_node=4 train_ddp.py --config config.yaml"
```

### Example 4: Model Inference API
```bash
# requirements.txt
fastapi==0.104.0
uvicorn==0.24.0
torch==2.1.0
transformers==4.35.0

# Start with API port
ngc up --requirements requirements.txt --port 8000:8000 --gpu 0

# Run FastAPI server
ngc exec -c "uvicorn app:app --host 0.0.0.0 --port 8000"

# API available at http://localhost:8000
```

### Example 5: Data Processing (CPU-Heavy)
```bash
# requirements.txt
pandas==2.1.0
polars==0.19.0
dask==2023.10.0

# High CPU/memory, no GPU needed
ngc up \
  --requirements requirements.txt \
  --memory 64g \
  --cpus 16.0 \
  --gpu 0  # Use only one GPU or none

# Process large dataset
ngc exec -c "python process_data.py --input data/raw --output data/processed"
```

### Example 6: Custom Image (TensorFlow)
```bash
# Use TensorFlow image instead of PyTorch
ngc up \
  --image nvcr.io/nvidia/tensorflow:24.12-tf2-py3 \
  --requirements requirements.txt \
  --port 8888:8888

ngc exec
```

## 🔐 NGC Authentication

### When Do You Need It?

**Public Images** - No authentication needed:
- `nvcr.io/nvidia/pytorch:*`
- `nvcr.io/nvidia/tensorflow:*`
- `nvcr.io/nvidia/cuda:*`

**Private Images** - Authentication required:
- `nvcr.io/your-org/your-private-model:*`
- Organization-specific images
- Enterprise NGC images

### Setup Authentication

```bash
# 1. Get your NGC API Key
# Visit: https://ngc.nvidia.com/setup/api-key
# Click "Generate API Key"

# 2. Login to NGC
ngc login
# Paste your API key when prompted

# 3. Verify authentication
docker info | grep nvcr.io
# Should show: Username: $oauthtoken

# 4. Use private images
ngc up --image nvcr.io/your-org/private-model:latest
```

### What Gets Stored?

```bash
~/.ngc/config           # NGC API key
~/.docker/config.json   # Docker registry credentials
```

### Logout

```bash
ngc logout
# Removes NGC credentials and Docker login
```

### Troubleshooting

**"unauthorized: authentication required"**
```bash
# Not logged in, run:
ngc login
```

**"Error response from daemon: Get https://nvcr.io/v2/: unauthorized"**
```bash
# Expired/invalid API key
ngc logout
ngc login  # Enter new key
```

**Check if logged in:**
```bash
cat ~/.ngc/config
# or
docker info | grep nvcr.io
```

## 🔍 How It Works

### Architecture
```
Host Machine                    Docker Container
┌─────────────────┐            ┌─────────────────┐
│  /your/project  │◄──bind────►│   /workspace    │
│                 │   mount    │                 │
│  ├── train.py   │            │  ├── train.py   │
│  ├── data/      │            │  ├── data/      │
│  └── .ngc/      │            │  └── (GPUs)     │
└─────────────────┘            └─────────────────┘
        ▲                               │
        └──────────────┬────────────────┘
                       │
                  localhost:8888
```

### Key Concepts

1. **Bind Mounting**: Your project directory is mounted into the container at `/workspace`. Changes are immediately synced both ways.

2. **Container Persistence**: Containers stay running in the background. Stop with `ngc down`, remove with `ngc rm`.

3. **Smart Caching**: Requirements are hashed. Reinstalls only happen if the file changes (override with `--force-requirements`).

4. **Unique Naming**: Container names include a directory hash (`ngc-myproject-a3f8c21d`) to prevent collisions across different project directories.

5. **User Mapping**: By default, runs as your user (`uid:gid`) to avoid permission issues with created files.

## 🛠️ Advanced Usage

### Multiple Projects
Each directory gets its own container:
```bash
cd /projects/nlp-research
ngc up  # Creates: ngc-nlp-research-abc123

cd /projects/computer-vision  
ngc up  # Creates: ngc-computer-vision-def456

# Both can run simultaneously
```

### Custom Docker Images
```bash
# NVIDIA PyTorch (default)
ngc up --image nvcr.io/nvidia/pytorch:25.12-py3

# NVIDIA TensorFlow
ngc up --image nvcr.io/nvidia/tensorflow:24.12-tf2-py3

# Custom image with your base setup
ngc up --image yourusername/ml-base:latest
```

### Environment Variables
```bash
# .env file
API_KEY=secret123
MODEL_PATH=/workspace/models
BATCH_SIZE=32
WANDB_PROJECT=my-experiment

ngc up --env-file .env

# Access inside container
ngc exec -c 'echo $API_KEY'
```

### Resource Management
```bash
# Limit resources to share GPU server
ngc up \
  --gpu 0,1 \        # Use only GPUs 0 and 1
  --memory 32g \     # Max 32GB RAM
  --cpus 8.0         # Max 8 CPU cores
```

### Development + Production Setup
```bash
# Development (with Jupyter, TensorBoard)
ngc up \
  --requirements requirements-dev.txt \
  --port 8888:8888,6006:6006 \
  --verbose

# Production (lean, specific resources)
ngc up \
  --requirements requirements.txt \
  --gpu 0 \
  --memory 16g \
  --no-user-mapping  # If needed for deployment
```

## 📊 Monitoring & Debugging

### Check Container Status
```bash
ngc status

# Output:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Container: ngc-myproject-a3f8c21d
# Status: running
# Workdir: /home/user/projects/myproject
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# GPU Status:
# index, name, utilization.gpu, memory.used, memory.total
# 0, NVIDIA A100, 45%, 12000 MiB, 40960 MiB
```

### View Logs
```bash
# NGC manager logs
ngc logs

# Docker container logs
docker logs ngc-myproject-a3f8c21d

# Follow logs in real-time
docker logs -f ngc-myproject-a3f8c21d
```

### GPU Monitoring
```bash
# Inside container
ngc exec -c "watch -n 1 nvidia-smi"

# Or use gpustat
ngc exec -c "pip install gpustat && gpustat -i 1"
```

## 🐛 Troubleshooting

### Container won't start
```bash
# Check Docker daemon
docker info

# Check NVIDIA runtime
docker info | grep -i nvidia

# View detailed logs
ngc up --verbose
ngc logs
```

### GPU not detected
```bash
# Verify NVIDIA driver
nvidia-smi

# Test GPU in Docker
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi

# If failed, reinstall NVIDIA Container Toolkit:
# https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html
```

### Port already in use
```bash
# Find what's using the port
lsof -ti:8888

# Kill the process
lsof -ti:8888 | xargs kill -9

# Or use a different port
ngc up --port 8889:8888
```

### Permission denied errors
```bash
# Files created in container have wrong ownership?
# By default runs as your user, but if you need root:
ngc up --no-user-mapping

# Fix existing permissions
ngc exec -c "chown -R $(id -u):$(id -g) /workspace"
```

### Requirements won't update
```bash
# Force reinstall
ngc up --force-requirements

# Or remove and recreate
ngc rm
ngc up --requirements requirements.txt
```

### Out of memory
```bash
# Check GPU memory
ngc exec -c "nvidia-smi"

# Increase shared memory (edit script line 83):
--shm-size=32g  # default is 16g

# Or reduce batch size in your code
```

### Container name collision
The script uses directory hash to prevent this, but if you renamed your project:
```bash
# List all NGC containers
docker ps -a | grep ngc-

# Remove old ones
docker rm -f ngc-oldname-12345678
```

## 🔒 Security Best Practices

1. **Use `.gitignore`**:
```bash
# .gitignore
.ngc/
.env
*.pth
*.ckpt
```

2. **Environment Variables**: Never commit API keys. Use `--env-file` with `.env` in `.gitignore`.

3. **User Mapping**: Default runs as your user (not root). Only use `--no-user-mapping` when necessary.

4. **Network Isolation**: Ports are only exposed on localhost by default. For remote access, use SSH tunneling:
```bash
# On remote server
ngc up --port 8888:8888

# On local machine
ssh -L 8888:localhost:8888 user@remote-server

# Access via localhost:8888
```

## 🎯 Best Practices

### Project Structure
```
my-ml-project/
├── ngc                 # This script
├── requirements.txt    # Python dependencies
├── .env               # Environment variables (gitignored)
├── .gitignore         # Ignore .ngc/, .env, checkpoints
├── train.py           # Training script
├── evaluate.py        # Evaluation script
├── data/              # Dataset
├── models/            # Saved models
├── notebooks/         # Jupyter notebooks
└── .ngc/              # NGC logs (gitignored)
    └── ngc.log
```

### Workflow
```bash
# 1. Setup (once per project)
ngc up --requirements requirements.txt --port 8888:8888

# 2. Develop
ngc jupyter  # or ngc exec

# 3. When done for the day
ngc down

# 4. Next day
ngc up  # Fast startup, requirements cached
ngc exec

# 5. Clean slate (if needed)
ngc rm
ngc up --force-requirements
```

### Version Control
```bash
# Commit the script with your project
git add ngc requirements.txt
git commit -m "Add NGC container manager"

# Others can use it
git clone <your-repo>
cd <your-repo>
chmod +x ngc
./ngc up --requirements requirements.txt
```

## 🚧 Known Limitations

Current version has a few limitations we're aware of:

- **No version command** - ~~Can't check installed version~~ ✅ Added in v1.0.0
- **Manual updates** - No built-in update mechanism (requires git pull + reinstall)
- **No config file** - Can't set persistent defaults (`.ngcrc` planned)
- **Basic cleanup** - ~~Old containers need manual removal~~ ✅ Added `ngc clean --containers` in v1.0.0
- **Manual completion reload** - Shell completions require terminal restart

**Note:** This tool is designed for Linux systems with NVIDIA GPUs. macOS and Windows native are not supported. Windows users should use WSL2.

See the [Roadmap](#-roadmap) below for planned improvements.

## 🗺️ Roadmap

### v1.1 (Next Release)
- [ ] **Auto-update mechanism** - `ngc update` to pull latest version
- [ ] **Container listing** - ~~`ngc list` to show all NGC containers~~ ✅ Added in v1.0.0
- [ ] **Enhanced status** - Show resource usage (CPU, memory, GPU utilization)
- [ ] **Better error messages** - Contextual help and suggestions

### v1.2 (Planned)
- [ ] **Config file support** - `~/.ngcrc` for default settings
- [ ] **Project templates** - `ngc init --template pytorch|tensorflow|transformers`
- [ ] **Auto GPU detection** - `ngc up --auto-gpu` to find free GPUs
- [ ] **Better testing** - Full integration test suite

### v2.0 (Future)
- [ ] **VS Code integration** - Auto-generate `.devcontainer.json`
- [ ] **Multi-container** - Support for related services (db, web, training)
- [ ] **Experiment tracking** - Built-in W&B, MLflow integration
- [ ] **GPU scheduling** - Wait for GPU availability
- [ ] **Jupyter extensions** - Auto-install popular extensions
- [ ] **Central management** - Team dashboard for shared servers
- [ ] **Container snapshots** - Save/restore container state

### Want a Feature?
Open an issue describing your use case, or submit a PR! Popular requests get prioritized.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup
```bash
git clone https://github.com/your-username/ngc-manager.git
cd ngc-manager
chmod +x ngc

# Test locally
./ngc up --verbose
./ngc status
```

### Priority Areas
We'd especially appreciate help with:
- **Windows WSL2** - Testing and documentation improvements
- **Shell completions** - Improvements for zsh/fish
- **Test coverage** - More comprehensive test suite
- **Documentation** - Examples for specific frameworks (Transformers, Stable Diffusion, etc.)

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

- Built on top of [NVIDIA NGC containers](https://catalog.ngc.nvidia.com/)
- Inspired by Docker Compose and development container workflows
- Uses [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-container-toolkit)

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/your-username/ngc-manager/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-username/ngc-manager/discussions)
- **Documentation**: See `QUICKSTART.md` and `IMPROVEMENTS.md`

## 🔗 Related Projects

- [nvidia-docker](https://github.com/NVIDIA/nvidia-docker) - NVIDIA Container Toolkit
- [docker-compose](https://docs.docker.com/compose/) - Multi-container orchestration
- [Dev Containers](https://containers.dev/) - VS Code development containers

---

**Made with ❤️ for the ML/DL community**