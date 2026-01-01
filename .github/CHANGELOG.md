# Changelog

All notable changes to NGC Container Manager will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-01

### Added
- Initial production release
- **NGC Authentication** - `ngc login` and `ngc logout` commands
  - Support for private NGC container images
  - Secure credential storage in `~/.ngc/config`
  - Automatic authentication check before pulling private images
  - Docker registry login to `nvcr.io`
- `ngc version` command to show version information
- `ngc list` command to show all NGC containers across projects
- Enhanced `ngc clean` command with options:
  - `--logs` - Clean log files (default)
  - `--containers` - Remove stopped NGC containers
  - `--images` - Remove dangling Docker images
  - `--all` - Clean everything
- Professional installer script with:
  - Docker and NVIDIA prerequisites checking
  - System-wide or user-local installation
  - Automatic shell completion installation (bash/zsh/fish)
  - GPU access testing
  - Uninstaller support
- Installation test suite (`test-install.sh`)
- Comprehensive documentation:
  - README.md - Complete project documentation
  - INSTALL.md - Installation guide
  - QUICKSTART.md - Quick reference
  - IMPROVEMENTS.md - Feature comparison
  - PACKAGE_SUMMARY.md - Package overview
  - CHANGELOG.md - Version history

### Core Features
- Smart requirements caching (hash-based)
- Port forwarding support
- GPU device selection
- User mapping (run as current user, not root)
- Environment file support
- Resource limits (CPU, memory)
- Container auto-restart on boot
- Unique container naming (prevents collisions)
- Execute commands without entering container
- One-command Jupyter Lab launch
- Enhanced status with GPU info
- Detailed logging with debug mode

### Commands
- `ngc up` - Create/start container with extensive options
- `ngc exec` - Interactive shell or execute command with `-c`
- `ngc down` - Stop container
- `ngc restart` - Quick restart
- `ngc rm` - Remove container
- `ngc status` - Container and GPU status
- `ngc list` - List all NGC containers
- `ngc jupyter` - Launch Jupyter Lab
- `ngc logs` - View debug logs
- `ngc clean` - Remove artifacts with options
- `ngc version` - Show version info
- `ngc help` - Comprehensive help

### Documentation
- 6 real-world examples (PyTorch, Jupyter, DDP, serving, data processing, TensorFlow)
- Architecture diagrams
- Troubleshooting guide
- Security best practices
- Performance tips
- Multi-user setup guide
- CI/CD integration examples

### Known Limitations
- No automatic update mechanism (manual git pull required)
- No persistent config file support (`.ngcrc` planned for v1.2)
- Shell completions require terminal restart to activate
- No built-in experiment tracking integration
- No VS Code devcontainer generation
- Not supported on macOS (Linux only, or WSL2 on Windows)

## [Unreleased]

### Planned for v1.1
- [ ] Automatic update checker and updater
- [ ] Container resource usage in status
- [ ] Improved error messages with suggestions
- [ ] Full integration test suite

### Planned for v1.2
- [ ] Config file support (`~/.ngcrc`)
- [ ] Project templates
- [ ] Auto GPU detection
- [ ] SSH server for remote development

### Planned for v2.0
- [ ] VS Code integration
- [ ] Multi-container support
- [ ] Experiment tracking integration
- [ ] GPU scheduling
- [ ] Jupyter extensions auto-install
- [ ] Team dashboard

## Contributing

See [README.md](README.md#contributing) for contribution guidelines.

## Support

- Issues: [GitHub Issues](https://github.com/your-username/ngc-manager/issues)
- Discussions: [GitHub Discussions](https://github.com/your-username/ngc-manager/discussions)