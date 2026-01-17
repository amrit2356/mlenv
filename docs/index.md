# MLEnv Documentation

![MLEnv Logo](assets/images/mlenv-logo.svg)

**Version 2.0.0** | [GitHub](https://github.com/amrit2356/mlenv) | [Issues](https://github.com/amrit2356/mlenv/issues)

Welcome to the MLEnv documentation! MLEnv is a production-grade GPU container management platform for machine learning and AI development.

---

## 🚀 Quick Links

<div class="quick-links">
  <div class="link-card">
    <h3>🎯 Getting Started</h3>
    <p>New to MLEnv? Start here!</p>
    <a href="../README.md">Quick Start Guide →</a>
  </div>
  
  <div class="link-card">
    <h3>📐 Architecture</h3>
    <p>Understand the system design</p>
    <a href="architecture/overview.md">Architecture Overview →</a>
  </div>
  
  <div class="link-card">
    <h3>🔧 API Reference</h3>
    <p>Complete API documentation</p>
    <a href="api/commands/README.md">API Docs →</a>
  </div>
  
  <div class="link-card">
    <h3>🔬 Development</h3>
    <p>Contribute to MLEnv</p>
    <a href="../docs.backup/development/phase1-architecture.md">Development Docs →</a>
  </div>
</div>

---

## 📚 Documentation Structure

### 📐 Architecture Documentation
Understand MLEnv's hexagonal architecture and design patterns.

- **[Architecture Overview](architecture/overview.md)** - High-level system design
- **[Hexagonal Design](architecture/hexagonal-design.md)** - Ports & Adapters pattern
- **[Context System](architecture/context-system.md)** - State management
- **[Configuration System](architecture/config-system.md)** - 4-level config hierarchy
- **[Database Design](architecture/database-design.md)** - SQLite schema & data model
- **[Error Handling](architecture/error-handling.md)** - Error handling patterns
- **[Security Model](architecture/security-model.md)** - Security architecture
- **[Module Dependencies](architecture/module-dependencies.md)** - Dependency graph

### 🔧 API Reference
Complete API documentation for all modules and commands.

#### Commands API
- **[Commands Overview](api/commands/README.md)** - All commands indexed
- **[mlenv up](api/commands/up.md)** - Container creation
- **[mlenv exec](api/commands/exec.md)** - Execute in container
- **[mlenv jupyter](api/commands/jupyter.md)** - Jupyter Lab
- **[mlenv status](api/commands/status.md)** - Container status
- [View all commands →](api/commands/README.md)

#### Core API
- **[Core Overview](api/core/README.md)** - Core modules
- **[Engine API](api/core/engine.md)** - Initialization & orchestration
- **[Context API](api/core/context.md)** - Context management
- **[Container API](api/core/container.md)** - Container lifecycle
- **[GPU API](api/core/gpu.md)** - GPU detection & allocation
- [View all core modules →](api/core/README.md)

#### Adapters API
- **[Adapters Overview](api/adapters/README.md)** - Hexagonal adapters
- **[Container Port](api/adapters/container-port.md)** - Container interface
- **[Docker Adapter](api/adapters/docker-adapter.md)** - Docker implementation
- **[Custom Adapters](api/adapters/custom-adapters.md)** - Build your own
- [View all adapters →](api/adapters/README.md)

#### Additional APIs
- **[Configuration API](api/config/README.md)** - Config system
- **[Database API](api/database/README.md)** - SQLite operations
- **[Resource API](api/resource/README.md)** - Admission control & monitoring
- **[Templates API](api/templates/README.md)** - Template engine
- **[Utilities API](api/utils/README.md)** - Helper functions

---

## 🎓 Learning Paths

### For Users
1. Read the [README](../README.md) for project overview
2. Follow [Getting Started](../docs.backup/guides/getting-started.md)
3. Explore [User Guide](../docs.backup/guides/getting-started.md)
4. Check [Advanced Usage](api/commands/README.md)

### For Developers
1. Understand [Architecture Overview](architecture/overview.md)
2. Read [Hexagonal Design](architecture/hexagonal-design.md)
3. Study [API Documentation](api/commands/README.md)
4. Review [Development Guide](../docs.backup/development/phase1-architecture.md)

### For Contributors
1. Read [Architecture Overview](architecture/overview.md)
2. Study [Module Dependencies](architecture/module-dependencies.md)
3. Check [Coding Standards](../docs.backup/development/phase1-architecture.md)
4. Review [Testing Guide](../docs.backup/development/phase5-testing.md)

---

## 🔍 Search & Navigate

- **Search**: Use GitHub's search or `Ctrl/Cmd+F` in your browser
- **Navigation**: Use the sidebar (when viewing on GitHub Pages)
- **Cross-references**: Links to related docs throughout
- **Source code**: Direct links to implementation

---

## 📖 Key Concepts

### Hexagonal Architecture
MLEnv uses the Ports & Adapters pattern to separate core logic from external dependencies.
[Learn more →](architecture/hexagonal-design.md)

### Context Object
A structured state object passed through all operations instead of global variables.
[Learn more →](architecture/context-system.md)

### Admission Control
Prevents system crashes by checking resources before container creation.
[Learn more →](api/resource/admission.md)

### Configuration Hierarchy
4-level configuration: System → User → Project → CLI
[Learn more →](architecture/config-system.md)

---

## 🛠️ Documentation Tools

### Scripts
- `scripts/generate-diagrams.sh` - Generate architecture diagrams
- `scripts/validate-docs.sh` - Validate links and references
- `scripts/serve-docs.sh` - Local documentation server

### Contributing to Docs
See [Documentation Guidelines](../docs.backup/development/phase1-architecture.md) for how to contribute.

---

## 📊 Documentation Status

| Section | Status | Coverage |
|---------|--------|----------|
| Architecture | ✅ Complete | 100% |
| API - Commands | ✅ Complete | 100% |
| API - Core | ✅ Complete | 100% |
| API - Adapters | ✅ Complete | 100% |
| API - Config | ✅ Complete | 100% |
| API - Database | ✅ Complete | 100% |
| API - Utils | ✅ Complete | 100% |

---

## 🤝 Get Help

- **Issues**: [GitHub Issues](https://github.com/amrit2356/mlenv/issues)
- **Discussions**: [GitHub Discussions](https://github.com/amrit2356/mlenv/discussions)
- **Email**: support@mlenv.io

---

## 📝 Documentation Version

- **Version**: 2.0.0
- **Last Updated**: 2026-01-18
- **MLEnv Version**: 2.0.0

---

<div class="footer">
  <p>Made with ❤️ for the ML/DL community</p>
  <p>
    <a href="../LICENSE">License</a> | 
    <a href="https://github.com/amrit2356/mlenv">GitHub</a> | 
    <a href="https://github.com/amrit2356/mlenv/issues">Issues</a>
  </p>
</div>
