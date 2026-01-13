# MLEnv Deployment Guide

## Overview

MLEnv v2.0.0 can be deployed in multiple ways depending on your Linux distribution and use case.

## Installation Methods

### Method 1: Using Install Script (Recommended)

```bash
# Download MLEnv
git clone https://github.com/your-username/mlenv.git
cd mlenv

# Check prerequisites
./install.sh check

# Install system-wide
sudo ./install.sh

# Verify installation
mlenv version
```

### Method 2: Debian/Ubuntu Package (.deb)

```bash
# Build package
make build-deb

# Install
sudo dpkg -i packaging/mlenv_2.0.0_amd64.deb
sudo apt-get install -f  # Fix dependencies

# Verify
mlenv version
```

### Method 3: RPM Package (RHEL/CentOS/Fedora)

```bash
# Build package
make build-rpm

# Install
sudo rpm -ivh packaging/rpm-build/mlenv-2.0.0-1.*.rpm
# or
sudo yum install packaging/rpm-build/mlenv-2.0.0-1.*.rpm

# Verify
mlenv version
```

### Method 4: From Source (Development)

```bash
# Clone repository
git clone https://github.com/your-username/mlenv.git
cd mlenv

# Set library path
export MLENV_LIB=$(pwd)/lib/mlenv

# Use directly
./bin/mlenv version
```

## Prerequisites

### Required Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| Docker | >= 20.10 | Container runtime |
| sqlite3 | >= 3.0 | Database backend |
| bash | >= 4.0 | Shell interpreter |

### Optional Dependencies

| Package | Purpose |
|---------|---------|
| jq | JSON parsing (recommended) |
| nvidia-container-toolkit | GPU support |
| nvidia-smi | GPU detection |

### Installing Prerequisites

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y docker.io sqlite3 jq

# For GPU support
sudo apt-get install -y nvidia-container-toolkit
```

#### RHEL/CentOS/Fedora
```bash
sudo yum install -y docker sqlite jq

# For GPU support
sudo yum install -y nvidia-container-toolkit
```

## Post-Installation

### 1. Verify Installation

```bash
# Check version
mlenv version

# Check prerequisites
make check
# or
./install.sh check
```

### 2. Initialize Configuration

```bash
# Generate user config
mlenv config generate

# Edit configuration
vi ~/.mlenvrc

# Verify configuration
mlenv config show
```

### 3. Test GPU Support

```bash
# Check GPU availability
mlenv gpu status

# Test GPU detection
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi
```

### 4. Create First Project

```bash
# List available templates
mlenv init --list

# Create project from template
mlenv init --template pytorch my-first-project

# Navigate and start
cd my-first-project
mlenv up --auto-gpu
```

## Package Management

### Debian/Ubuntu

#### Install
```bash
sudo dpkg -i mlenv_2.0.0_amd64.deb
sudo apt-get install -f
```

#### Update
```bash
sudo dpkg -i mlenv_2.0.0_amd64.deb
```

#### Remove
```bash
# Remove package (keep config)
sudo apt-get remove mlenv

# Purge (remove everything)
sudo apt-get purge mlenv
```

#### Query
```bash
# Check if installed
dpkg -l | grep mlenv

# List files
dpkg -L mlenv

# Show info
apt show mlenv
```

### RHEL/CentOS/Fedora

#### Install
```bash
sudo rpm -ivh mlenv-2.0.0-1.*.rpm
# or
sudo yum install mlenv-2.0.0-1.*.rpm
```

#### Update
```bash
sudo rpm -Uvh mlenv-2.0.0-1.*.rpm
```

#### Remove
```bash
sudo rpm -e mlenv
# or
sudo yum remove mlenv
```

#### Query
```bash
# Check if installed
rpm -qa | grep mlenv

# List files
rpm -ql mlenv

# Show info
rpm -qi mlenv
```

## Directory Structure

### After Installation

```
/usr/local/
├── bin/
│   └── mlenv                   # Main binary
├── lib/mlenv/                  # Libraries
│   ├── core/
│   ├── ports/
│   ├── adapters/
│   ├── config/
│   ├── database/
│   ├── registry/
│   ├── resource/
│   ├── templates/
│   └── utils/
└── share/mlenv/                # Shared files
    ├── templates/
    └── examples/

/etc/mlenv/
└── mlenv.conf                  # System configuration

/var/mlenv/                     # Runtime data
├── registry/
│   └── catalog.db              # Database
├── cache/                      # Cache files
└── plugins/                    # Plugins
```

## Uninstallation

### Using Install Script

```bash
sudo ./install.sh uninstall
```

### Manual Uninstallation

```bash
# Remove binaries
sudo rm -f /usr/local/bin/mlenv

# Remove libraries
sudo rm -rf /usr/local/lib/mlenv

# Remove configuration
sudo rm -rf /etc/mlenv

# Remove shared files
sudo rm -rf /usr/local/share/mlenv

# Remove user data (optional)
sudo rm -rf /var/mlenv
```

## Upgrade

### From v1.x to v2.0.0

MLEnv v2.0.0 is a complete rewrite with backward compatibility:

```bash
# Backup v1.x configuration
cp ~/.mlenv ~/.mlenv.v1.backup

# Install v2.0.0
sudo ./install.sh

# Migrate (automatic)
# v2.0.0 will work with existing containers

# Update config (optional)
mlenv config generate
```

### Between v2.x versions

```bash
# Download new version
git pull

# Reinstall
sudo ./install.sh

# Or upgrade package
sudo dpkg -i mlenv_2.0.1_amd64.deb
```

## Troubleshooting

### Installation Issues

#### Permission Denied
```bash
# Ensure you're using sudo
sudo ./install.sh

# Check file permissions
ls -la install.sh
chmod +x install.sh
```

#### Missing Dependencies
```bash
# Check what's missing
./install.sh check

# Install missing packages
sudo apt-get install docker.io sqlite3 jq
```

#### Docker Daemon Not Running
```bash
# Start Docker
sudo systemctl start docker

# Enable on boot
sudo systemctl enable docker

# Verify
sudo docker info
```

### Package Issues

#### DEB: Dependency Problems
```bash
# Fix broken dependencies
sudo apt-get install -f

# Force install (not recommended)
sudo dpkg -i --force-depends mlenv_2.0.0_amd64.deb
```

#### RPM: Conflicts
```bash
# Force reinstall
sudo rpm -ivh --force mlenv-2.0.0-1.*.rpm

# Skip dependency check (not recommended)
sudo rpm -ivh --nodeps mlenv-2.0.0-1.*.rpm
```

### Post-Installation Issues

#### Command Not Found
```bash
# Check if installed
which mlenv

# Add to PATH if needed
export PATH="/usr/local/bin:$PATH"

# Make permanent
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
```

#### Database Errors
```bash
# Reinitialize database
sudo rm -rf /var/mlenv/registry/catalog.db
mlenv up  # Will auto-initialize
```

#### GPU Not Detected
```bash
# Check nvidia-smi
nvidia-smi

# Check NVIDIA Container Toolkit
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi

# Reinstall toolkit if needed
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

## Verification Checklist

After installation, verify:

- [ ] `mlenv version` shows v2.0.0
- [ ] `mlenv help` displays help
- [ ] `mlenv config show` shows configuration
- [ ] `mlenv gpu status` shows GPUs (if available)
- [ ] `mlenv init --list` shows templates
- [ ] Database exists: `/var/mlenv/registry/catalog.db`
- [ ] Config exists: `/etc/mlenv/mlenv.conf`

## Next Steps

1. **Configure**: Edit `~/.mlenvrc` with your preferences
2. **Create Project**: `mlenv init --template pytorch my-project`
3. **Start Container**: `mlenv up --auto-gpu`
4. **Develop**: `mlenv exec`

## Support

- **Documentation**: `mlenv help`
- **Issues**: https://github.com/your-username/mlenv/issues
- **Discussions**: https://github.com/your-username/mlenv/discussions

## Security Considerations

### File Permissions

MLEnv sets appropriate permissions during installation:
- Binaries: 755 (rwxr-xr-x)
- Libraries: 755 for scripts
- Config: 644 (rw-r--r--)
- User data: 700 (rwx------)

### User Mapping

By default, MLEnv runs containers as your user (not root):
- Prevents permission issues
- Enhances security
- Can be disabled with `--no-user-mapping`

### Database

The SQLite database at `/var/mlenv/registry/catalog.db` stores:
- NGC image metadata
- Container inventory
- Resource metrics
- No sensitive data

### NGC Credentials

If using private NGC images:
- API keys stored in `~/.mlenv/config` (600 permissions)
- Docker credentials in `~/.docker/config.json`
- Both encrypted by Docker

## Production Deployment

### Multi-User Server

```bash
# Install system-wide
sudo ./install.sh

# Each user gets their own:
# - ~/.mlenvrc (config)
# - ~/.mlenv/ (user data)
# - Containers named mlenv-{user}-{project}-{hash}
```

### Resource Limits

Enable admission control in `/etc/mlenv/mlenv.conf`:

```ini
[resources]
enable_admission_control = true
max_memory_percent = 85
min_available_memory_gb = 4
```

### Monitoring

Set up continuous monitoring:

```bash
# Run monitor in background
nohup mlenv monitor &

# Or add to systemd (future feature)
```

### Backups

Important directories to backup:
- `/var/mlenv/registry/` - Database
- `~/.mlenvrc` - User config
- `~/.mlenv/` - User templates

```bash
# Backup script
tar czf mlenv-backup-$(date +%Y%m%d).tar.gz \
    /var/mlenv/registry \
    ~/.mlenvrc \
    ~/.mlenv
```

---

**MLEnv v2.0.0 Deployment Guide**  
Last Updated: 2025-01-13
