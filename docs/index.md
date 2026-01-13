---
layout: default
title: MLEnv Documentation
---

# MLEnv v2.0.0 Documentation

**Production-Grade ML Container Management Platform**

Welcome to the comprehensive documentation for MLEnv v2.0.0 - an enterprise-grade platform for managing GPU-accelerated Docker containers for machine learning workloads.

---

## 🚀 Quick Links

- [**Getting Started**](guides/getting-started.md) - Install and run your first container
- [**User Guide**](guides/user-guide.md) - Complete feature documentation
- [**Configuration**](reference/configuration.md) - Config file reference
- [**Templates**](reference/templates.md) - Project template system
- [**API Reference**](reference/api.md) - Module and function reference
- [**Deployment**](guides/deployment.md) - Production deployment guide

---

## 📚 Documentation Sections

### Guides
- [Getting Started](guides/getting-started.md) - Quick start guide
- [User Guide](guides/user-guide.md) - Complete usage documentation
- [Migration Guide](guides/migration.md) - Upgrading from v1.x
- [Deployment Guide](guides/deployment.md) - Production deployment
- [Best Practices](guides/best-practices.md) - Recommendations

### Reference
- [Configuration Reference](reference/configuration.md) - All config options
- [Template Reference](reference/templates.md) - Template system
- [API Reference](reference/api.md) - Module documentation
- [CLI Reference](reference/cli.md) - All commands
- [Architecture](reference/architecture.md) - System design

### Development
- [Architecture Overview](development/architecture.md) - Hexagonal design
- [Contributing Guide](development/contributing.md) - How to contribute
- [Testing Guide](development/testing.md) - Test framework
- [Packaging Guide](development/packaging.md) - Building packages
- [Release Process](development/releases.md) - Release workflow

---

## 🌟 What is MLEnv?

MLEnv is a production-grade command-line tool that simplifies GPU-accelerated machine learning development by:

- **Managing Docker containers** with GPU support
- **Preventing system crashes** through admission control
- **Auto-detecting free GPUs** for intelligent allocation
- **Quick-starting projects** with templates
- **Monitoring resources** in real-time
- **Tracking container health** automatically

---

## ⚡ Quick Start

```bash
# Install
sudo ./install.sh

# Create project
mlenv init --template pytorch my-project

# Start with auto-GPU
cd my-project
mlenv up --auto-gpu

# Enter container
mlenv exec
```

---

## 🎯 Key Features

### Core Capabilities
- Zero-config GPU access
- Smart GPU allocation (auto-detect)
- User mapping (non-root security)
- Port forwarding
- Requirements caching
- VS Code DevContainer integration

### Safety & Monitoring
- **Admission control** (crash prevention)
- Real-time resource monitoring
- Container health checks
- Project quotas
- Historical metrics

### Developer Experience
- Project templates (PyTorch, Minimal)
- Config file support (~/.mlenvrc)
- Quick commands
- Auto GPU detection

### Enterprise Features
- Linux packages (DEB/RPM)
- SQLite database backend
- NGC catalog integration
- Multi-project support
- Professional testing

---

## 📊 Architecture

MLEnv uses **Hexagonal Architecture** (Ports & Adapters):

```
┌────────────────────────┐
│  CLI & Config          │
├────────────────────────┤
│  Ports (Interfaces)    │
├────────────────────────┤
│  Core Logic            │
├────────────────────────┤
│  Adapters              │
│  (Docker, NGC, etc.)   │
└────────────────────────┘
```

[Learn more about the architecture →](development/architecture.md)

---

## 🛡️ Safety Features

### Admission Control
Prevents system crashes by checking:
- Memory usage < 85%
- Available memory > 4GB
- CPU usage < 90%
- Load average reasonable
- GPU availability

### Example
```bash
mlenv up --memory 64g
# → REJECTED: Requested memory exceeds available
# System protected! ✅
```

---

## 🤖 Intelligent Features

### Auto GPU Detection
```bash
mlenv up --auto-gpu
# → Automatically selects GPU 2
# → (GPUs 0,1 are busy)
```

### Resource Monitoring
```bash
mlenv status
# → CPU: 45%, Memory: 37%
# → GPU 0: 15% util
```

---

## 📦 Installation

### Quick Install
```bash
sudo ./install.sh
```

### Package Managers
```bash
# Debian/Ubuntu
sudo dpkg -i mlenv_2.0.0_amd64.deb

# RHEL/CentOS
sudo rpm -ivh mlenv-2.0.0-1.*.rpm
```

[Complete installation guide →](guides/deployment.md)

---

## 📖 Documentation Navigation

### New Users
1. [Getting Started](guides/getting-started.md)
2. [User Guide](guides/user-guide.md)
3. [Configuration](reference/configuration.md)

### Advanced Users
1. [Architecture](reference/architecture.md)
2. [API Reference](reference/api.md)
3. [Best Practices](guides/best-practices.md)

### Developers
1. [Architecture Overview](development/architecture.md)
2. [Contributing](development/contributing.md)
3. [Testing](development/testing.md)

### Operators
1. [Deployment Guide](guides/deployment.md)
2. [Production Setup](guides/best-practices.md)

---

## 🎓 Key Concepts

### Container Lifecycle
- **Create** - `mlenv up`
- **Execute** - `mlenv exec`
- **Stop** - `mlenv down`
- **Remove** - `mlenv rm`

### GPU Management
- **Auto-detect** - `--auto-gpu`
- **Manual** - `--gpu 0,1`
- **Status** - `mlenv gpu status`

### Project Management
- **Templates** - `mlenv init --template TYPE`
- **List** - `mlenv list`
- **Clean** - `mlenv clean`

---

## 🔗 External Resources

- [GitHub Repository](https://github.com/your-username/mlenv)
- [Issue Tracker](https://github.com/your-username/mlenv/issues)
- [Discussions](https://github.com/your-username/mlenv/discussions)
- [NVIDIA NGC Catalog](https://catalog.ngc.nvidia.com/)

---

## 📊 Statistics

- **80+ Features**
- **70+ Files**
- **25+ Tests**
- **10+ Documentation Guides**
- **100% Backward Compatible**
- **Production Ready**

---

## 🆘 Need Help?

- **Quick Reference**: [QUICKREF.md](QUICKREF.md)
- **FAQ**: [guides/user-guide.md#faq](guides/user-guide.md)
- **Troubleshooting**: [guides/deployment.md#troubleshooting](guides/deployment.md)
- **Command Help**: `mlenv help`

---

**MLEnv v2.0.0** - Production-Grade ML Container Platform  
Built with ❤️ for the ML/DL community
