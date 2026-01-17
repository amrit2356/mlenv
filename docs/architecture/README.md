# Architecture Documentation

This section provides comprehensive documentation of MLEnv's architecture, design patterns, and system internals.

## 📐 Overview

MLEnv v2.0 is built on **Hexagonal Architecture** (Ports & Adapters pattern), providing a clean separation between core business logic and external dependencies.

## 📚 Architecture Documents

### Core Architecture
- **[Architecture Overview](overview.md)** - High-level system architecture and component interaction
- **[Hexagonal Design](hexagonal-design.md)** - Ports & Adapters pattern implementation
- **[Module Dependencies](module-dependencies.md)** - Module interaction and dependency graph

### System Components
- **[Context System](context-system.md)** - Context object flow and state management
- **[Configuration System](config-system.md)** - 4-level configuration hierarchy
- **[Database Design](database-design.md)** - SQLite schema and data model
- **[Error Handling](error-handling.md)** - Error handling patterns and strategies
- **[Security Model](security-model.md)** - Security architecture and user mapping
- **[Adapter Pattern](adapter-pattern.md)** - Implementing adapters for extensibility

## 🎨 Architecture Diagrams

All diagrams are in the [`diagrams/`](diagrams/) directory:

- **[architecture.svg](diagrams/architecture.svg)** - Overall system architecture
- **[hexagonal-structure.svg](diagrams/hexagonal-structure.svg)** - Ports & adapters visualization
- **[context-flow.svg](diagrams/context-flow.svg)** - Context object flow through commands
- **[config-precedence.svg](diagrams/config-precedence.svg)** - Configuration hierarchy & precedence
- **[command-flow.svg](diagrams/command-flow.svg)** - Command execution pipeline
- **[adapter-interaction.svg](diagrams/adapter-interaction.svg)** - Docker/NGC adapter interaction
- **[database-schema.svg](diagrams/database-schema.svg)** - SQLite database schema
- **[module-dependencies.svg](diagrams/module-dependencies.svg)** - Module dependency graph

## 🏗️ Key Architectural Principles

### 1. Hexagonal Architecture (Ports & Adapters)
```
┌─────────────────────────────────────────────────┐
│              CLI (bin/mlenv)                    │
├─────────────────────────────────────────────────┤
│           Commands Layer (Orchestration)        │
├─────────────────────────────────────────────────┤
│              Core Business Logic                │
│  (Container, Image, GPU, Context, Config)       │
├─────────────────────────────────────────────────┤
│          Ports (Abstract Interfaces)            │
├─────────────────────────────────────────────────┤
│        Adapters (Implementations)               │
│      - Docker Adapter                           │
│      - NGC Registry Adapter                     │
│      - Future: Podman, Containerd               │
└─────────────────────────────────────────────────┘
```

### 2. Context-Based State Management
Instead of global variables, state is passed through a **context object**:
```bash
declare -A ctx
ctx[workdir]="/path/to/project"
ctx[container_name]="mlenv-project-abc123"
ctx[image]="nvcr.io/nvidia/pytorch:25.12-py3"
# ... passed to all functions
```

### 3. Configuration Hierarchy
Four-level configuration with precedence:
```
CLI Arguments > Project Config > User Config > System Defaults
    (highest priority)                    (lowest priority)
```

### 4. Dependency Inversion
Core logic depends on **interfaces** (ports), not implementations:
```bash
# Port (interface)
container_create() { ... }

# Adapter (implementation)
docker_container_create() { ... }
podman_container_create() { ... }
```

## 🎯 Design Goals

1. **Modularity** - Each module has a single responsibility
2. **Testability** - Mock adapters for unit testing
3. **Extensibility** - Add new adapters without changing core
4. **Maintainability** - Clear boundaries between components
5. **Reliability** - Error handling at all layers

## 📊 System Layers

### Layer 1: CLI & Command Routing
**Location**: `bin/mlenv`
- Command-line parsing
- Option validation
- Command routing to handlers

### Layer 2: Commands (Application Layer)
**Location**: `lib/mlenv/commands/`
- Orchestrates core logic
- Validates inputs
- Manages context lifecycle
- Returns exit codes

### Layer 3: Core Business Logic
**Location**: `lib/mlenv/core/`
- Container lifecycle
- Image management
- GPU detection
- Authentication
- Context management

### Layer 4: Ports (Interfaces)
**Location**: `lib/mlenv/adapters/interfaces/`
- Abstract contracts
- Interface validation
- Adapter delegation

### Layer 5: Adapters (Implementations)
**Location**: `lib/mlenv/adapters/`
- Docker implementation
- NGC registry implementation
- Future: Podman, Containerd, etc.

### Layer 6: Supporting Systems
**Location**: `lib/mlenv/config/`, `lib/mlenv/database/`, `lib/mlenv/utils/`
- Configuration management
- Database persistence
- Utility functions
- Error handling
- Logging

## 🔄 Data Flow

```
User Command (CLI)
    ↓
Command Handler (validates, creates context)
    ↓
Core Logic (business rules)
    ↓
Port (abstract interface)
    ↓
Adapter (Docker/NGC implementation)
    ↓
External System (Docker daemon, NGC API)
```

## 🧪 Testing Architecture

### Unit Tests
Test individual functions with mocked dependencies:
```bash
tests/unit/
├── test-config-parser.sh
├── test-context.sh
├── test-gpu-detection.sh
└── test-validation.sh
```

### Integration Tests
Test multiple components together:
```bash
tests/integration/
├── test-docker-adapter.sh
├── test-full-workflow.sh
└── test-phase1-phase2.sh
```

### E2E Tests
Test complete user workflows:
```bash
tests/e2e/
└── test-basic-workflow.sh
```

## 📖 Further Reading

- [Hexagonal Architecture Explained](hexagonal-design.md)
- [Context System Deep Dive](context-system.md)
- [Configuration System](config-system.md)
- [API Documentation](../api/commands/README.md)

## 🤝 Contributing

When extending the architecture:
1. Follow the hexagonal pattern
2. Create adapters for external dependencies
3. Use context objects for state
4. Add tests for new components
5. Update this documentation

---

**Last Updated**: 2026-01-18  
**Version**: 2.0.0
