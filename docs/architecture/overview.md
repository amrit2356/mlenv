# MLEnv Architecture Overview

## Executive Summary

MLEnv v2.0 is a production-grade ML container management platform built on **Hexagonal Architecture** (Ports & Adapters pattern). This architecture provides modularity, testability, and extensibility while maintaining clean separation of concerns.

## System Architecture

```
┌───────────────────────────────────────────────────────────────┐
│                        User Interface                         │
│                      (CLI: bin/mlenv)                         │
├───────────────────────────────────────────────────────────────┤
│                     Application Layer                         │
│               (Commands: lib/mlenv/commands/)                 │
│  up│down│exec│jupyter│status│logs│rm│restart│init│clean│...  │
├───────────────────────────────────────────────────────────────┤
│                     Core Business Logic                       │
│                  (Core: lib/mlenv/core/)                      │
│ ┌──────────┬───────┬────────┬──────┬────────┬─────────────┐  │
│ │Container │ Image │  GPU   │ Auth │Context │ Devcontainer│  │
│ │ Mgmt     │ Mgmt  │Detect  │ Mgmt │  Mgmt  │  Generator  │  │
│ └──────────┴───────┴────────┴──────┴────────┴─────────────┘  │
├───────────────────────────────────────────────────────────────┤
│              Ports (Abstract Interfaces)                      │
│          (Interfaces: lib/mlenv/adapters/interfaces/)         │
│  ┌─────────────────┬──────────────────┬──────────────────┐   │
│  │ Container Port  │   Image Port     │   Auth Port      │   │
│  └─────────────────┴──────────────────┴──────────────────┘   │
├───────────────────────────────────────────────────────────────┤
│              Adapters (Implementations)                       │
│           (Adapters: lib/mlenv/adapters/)                     │
│  ┌─────────────────┬──────────────────┬──────────────────┐   │
│  │ Docker Adapter  │   NGC Adapter    │  Future: Podman  │   │
│  └─────────────────┴──────────────────┴──────────────────┘   │
├───────────────────────────────────────────────────────────────┤
│                   Supporting Systems                          │
│  ┌──────────┬─────────┬──────────┬──────────┬──────────┐    │
│  │  Config  │Database │ Resource │Templates │ Utilities│    │
│  │  System  │ Layer   │  Mgmt    │  Engine  │  (Utils) │    │
│  └──────────┴─────────┴──────────┴──────────┴──────────┘    │
└───────────────────────────────────────────────────────────────┘
                              ↓
                   ┌────────────────────┐
                   │  External Systems  │
                   │  - Docker Daemon   │
                   │  - NGC Registry    │
                   │  - File System     │
                   │  - SQLite Database │
                   └────────────────────┘
```

## Component Overview

### 1. CLI Layer (`bin/mlenv`)
**Purpose**: Entry point and command routing

**Responsibilities**:
- Parse command-line arguments
- Route to appropriate command handler
- Initialize engine
- Handle top-level errors

**Key Functions**:
```bash
# Parse command
command="${1:-help}"

# Route to handler
case "$command" in
    up)       cmd_up ;;
    exec)     cmd_exec ;;
    jupyter)  cmd_jupyter ;;
    # ... etc
esac
```

**Files**: `bin/mlenv`

---

### 2. Commands Layer (`lib/mlenv/commands/`)
**Purpose**: Application orchestration

**Responsibilities**:
- Validate inputs
- Create and manage context
- Orchestrate core logic
- Handle command-specific logic
- Return appropriate exit codes

**Command Structure**:
```bash
cmd_up() {
    # 1. Initialize context
    declare -A ctx
    cmd_init_context ctx
    
    # 2. Validate prerequisites
    cmd_require_container_env
    
    # 3. Admission control
    admission_check_container_creation
    
    # 4. Execute business logic
    container_create ...
    
    # 5. Return result
    return 0
}
```

**Available Commands**: (17 total)
- `up` - Create/start container
- `down` - Stop container
- `exec` - Execute in container
- `jupyter` - Start Jupyter Lab
- `status` - Container status
- `logs` - View logs
- `rm` - Remove container
- `restart` - Restart container
- `init` - Initialize project
- `clean` - Cleanup resources
- `config` - Manage configuration
- `catalog` - NGC catalog operations
- `login` - NGC authentication
- `logout` - NGC logout
- `sync` - Database sync
- `version` - Version info
- `help` - Help system

**Files**: `lib/mlenv/commands/*.sh`

---

### 3. Core Layer (`lib/mlenv/core/`)
**Purpose**: Business logic implementation

**Modules**:

#### `engine.sh` - Engine Initialization
- Initialize MLEnv engine
- Load configuration
- Initialize adapters
- Apply configuration to environment

#### `context.sh` - Context Management
- Create context objects
- Validate context
- Export context to environment

#### `container.sh` - Container Lifecycle
- Container operations (create, start, stop, remove)
- Container status checks
- Container inspection

#### `image.sh` - Image Management
- Pull images
- Verify images exist
- Image metadata

#### `gpu.sh` - GPU Detection & Allocation
- Detect available GPUs
- Auto-select free GPUs
- GPU allocation tracking

#### `auth.sh` - Authentication
- NGC API key management
- Authentication status
- Token storage

#### `devcontainer.sh` - VS Code Integration
- Generate `.devcontainer/devcontainer.json`
- Configure VS Code settings

**Files**: `lib/mlenv/core/*.sh`

---

### 4. Ports Layer (`lib/mlenv/adapters/interfaces/`)
**Purpose**: Abstract interfaces (contracts)

**Interfaces**:

#### Container Port
Defines container operations interface:
```bash
CONTAINER_PORT_METHODS=(
    [create]="container_create"
    [start]="container_start"
    [stop]="container_stop"
    [remove]="container_remove"
    [exec]="container_exec"
    [inspect]="container_inspect"
    [list]="container_list"
    [logs]="container_logs"
    [exists]="container_exists"
    [is_running]="container_is_running"
)
```

#### Image Port
Defines image operations interface.

#### Auth Port
Defines authentication interface.

**Files**: `lib/mlenv/adapters/interfaces/*.sh`

---

### 5. Adapters Layer (`lib/mlenv/adapters/`)
**Purpose**: External system implementations

**Current Adapters**:

#### Docker Adapter (`container/docker.sh`)
Implements container operations using Docker:
```bash
docker_container_create() { docker run ... }
docker_container_start() { docker start ... }
docker_container_stop() { docker stop ... }
# ... etc
```

#### NGC Adapter (`registry/ngc.sh`)
Implements NGC registry operations.

**Future Adapters**:
- Podman adapter
- Containerd adapter
- Kubernetes adapter

**Files**: `lib/mlenv/adapters/container/*.sh`, `lib/mlenv/adapters/registry/*.sh`

---

### 6. Configuration System (`lib/mlenv/config/`)
**Purpose**: Configuration management

**4-Level Hierarchy**:
```
1. System Config:   /etc/mlenv/mlenv.conf
2. User Config:     ~/.mlenvrc
3. Project Config:  ./.mlenvrc
4. CLI Arguments:   --image, --gpu, etc.

Priority: CLI > Project > User > System
```

**Modules**:
- `parser.sh` - INI file parser
- `defaults.sh` - Default values
- `accessor.sh` - Config access functions
- `validator.sh` - Config validation

**Files**: `lib/mlenv/config/*.sh`

---

### 7. Database Layer (`lib/mlenv/database/`)
**Purpose**: State persistence

**SQLite Database**: `var/mlenv/state/mlenv.db`

**9 Tables + 2 Views**:
- `ngc_images` - NGC catalog
- `image_versions` - Image tags/versions
- `container_instances` - Running containers
- `resource_metrics` - Resource usage history
- `system_snapshots` - System resource snapshots
- `api_cache` - NGC API cache
- `project_quotas` - Resource quotas
- `gpu_allocations` - GPU assignments
- `health_checks` - Container health (future)

**Views**:
- `v_active_containers` - Active containers with metrics
- `v_system_summary` - System resource summary

**Files**: `lib/mlenv/database/*.sh`, `lib/mlenv/database/schema.sql`

---

### 8. Resource Management (`lib/mlenv/resource/`)
**Purpose**: Admission control and monitoring

**Admission Control**:
Prevents system crashes by checking resources before container creation:
```bash
admission_check_container_creation() {
    # Check memory usage < 85%
    # Check CPU usage < 90%
    # Check available memory > 4GB
    # Check project quotas
}
```

**Resource Monitoring**:
Track CPU, memory, GPU usage over time.

**Files**: `lib/mlenv/resource/*.sh`

---

### 9. Template Engine (`lib/mlenv/templates/`)
**Purpose**: Project scaffolding

**Templates**:
- `pytorch` - PyTorch project template
- `minimal` - Minimal project template
- Future: TensorFlow, Transformers, etc.

**Usage**:
```bash
mlenv init --template pytorch my-project
```

**Files**: `lib/mlenv/templates/*.sh`, `share/mlenv/templates/*`

---

### 10. Utilities (`lib/mlenv/utils/`)
**Purpose**: Reusable helper functions

**Modules**:
- `logging.sh` - Structured logging
- `error.sh` - Error handling
- `validation.sh` - Input validation
- `cleanup.sh` - Resource cleanup
- `cache.sh` - Caching system
- `locking.sh` - File locking
- `retry.sh` - Retry logic
- `sanitization.sh` - Input sanitization
- `port-utils.sh` - Port management
- `container-utils.sh` - Container utilities
- `resource-tracker.sh` - Resource tracking
- `command-helpers.sh` - Command helpers

**Files**: `lib/mlenv/utils/*.sh`

---

## Data Flow Example: `mlenv up`

```
1. User runs: mlenv up --auto-gpu

2. CLI (bin/mlenv):
   - Parses command: "up"
   - Parses options: --auto-gpu
   - Calls: cmd_up()

3. Command Handler (commands/up.sh):
   - Creates context object
   - Validates prerequisites
   - Runs admission control check
   - Calls: container_create()

4. Core Logic (core/container.sh):
   - Prepares container parameters
   - Detects GPUs (if --auto-gpu)
   - Calls: container_create() (port)

5. Port (adapters/interfaces/container-port.sh):
   - Delegates to active adapter
   - Calls: docker_container_create()

6. Adapter (adapters/container/docker.sh):
   - Executes: docker run ...
   - Returns: container ID

7. Database Layer (database/sync.sh):
   - Records container in database
   - Updates resource allocations

8. Response flows back up:
   - Adapter → Port → Core → Command → CLI
   - User sees: "✓ Container created: mlenv-project-abc123"
```

## Design Principles

### 1. Separation of Concerns
Each layer has a single, well-defined responsibility.

### 2. Dependency Inversion
High-level modules don't depend on low-level modules. Both depend on abstractions (ports).

### 3. Single Responsibility
Each module does one thing well.

### 4. Open/Closed Principle
Open for extension (add new adapters), closed for modification (don't change core).

### 5. Interface Segregation
Small, focused interfaces instead of large, monolithic ones.

## Benefits of This Architecture

### ✅ Modularity
- 70+ small, focused files
- Clear module boundaries
- Easy to understand each component

### ✅ Testability
- Mock adapters for unit tests
- Test core logic in isolation
- Integration tests at adapter level

### ✅ Extensibility
- Add Podman support in 1 hour
- Add new commands without touching core
- Plugin system (future)

### ✅ Maintainability
- Clear dependencies
- Consistent patterns
- Well-documented

### ✅ Reliability
- Error handling at every layer
- Admission control prevents crashes
- Resource monitoring

## Migration from v1.x

### v1.x (Monolithic)
```
mlenv (1188 lines)
├── All logic in one file
├── Global variables
├── Tightly coupled
└── Hard to test
```

### v2.0 (Modular)
```
bin/mlenv (230 lines) - routing only
lib/mlenv/
├── commands/ (17 files)
├── core/ (7 files)
├── adapters/ (6 files)
├── config/ (4 files)
├── database/ (3 files)
├── resource/ (1 file)
├── templates/ (1 file)
└── utils/ (13 files)

Total: 70+ modular files
```

## Key Improvements

1. **From Global Variables → Context Objects**
2. **From Monolithic → Modular**
3. **From Tightly Coupled → Loosely Coupled**
4. **From Hard to Test → Highly Testable**
5. **From Fixed → Extensible**

## Further Reading

- [Hexagonal Architecture Deep Dive](hexagonal-design.md)
- [Context System](context-system.md)
- [Configuration System](config-system.md)
- [Database Design](database-design.md)
- [Module Dependencies](module-dependencies.md)

## Related Documentation

- [Commands API Reference](../api/commands/README.md)
- [Core API Reference](../api/core/README.md)
- [Adapters API Reference](../api/adapters/README.md)

---

**Last Updated**: 2026-01-18  
**Version**: 2.0.0
