# Database Design

## Overview

MLEnv v2.0 uses **SQLite** for persistent state management, resource tracking, and NGC catalog caching. The database enables features like admission control, resource monitoring, and container lifecycle tracking.

**Database Location**: `/var/mlenv/state/mlenv.db` (or `~/.mlenv/state/mlenv.db` for user installations)

## Database Schema

### Entity-Relationship Diagram

```
┌──────────────────┐       ┌────────────────────┐
│   ngc_images     │───┬───│  image_versions    │
└──────────────────┘   │   └────────────────────┘
                       │
         ┌─────────────┴──────────────┐
         │                            │
┌────────▼──────────┐     ┌───────────▼──────────┐
│ container_        │     │  resource_metrics    │
│ instances         │────►│                      │
└───────────────────┘     └──────────────────────┘
         │
         │
┌────────▼──────────┐     ┌───────────────────────┐
│ gpu_allocations   │     │  system_snapshots     │
└───────────────────┘     └───────────────────────┘
         
┌───────────────────┐     ┌───────────────────────┐
│ project_quotas    │     │  api_cache            │
└───────────────────┘     └───────────────────────┘
```

---

## Tables

### 1. ngc_images

**Purpose**: NGC catalog of available images

**Schema**:
```sql
CREATE TABLE ngc_images (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    display_name TEXT,
    organization TEXT NOT NULL,
    team TEXT,
    category TEXT,              -- pytorch, tensorflow, rapids, etc.
    description TEXT,
    created_at DATETIME,
    updated_at DATETIME,
    last_synced DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization, team, name)
);
```

**Indexes**:
```sql
CREATE INDEX idx_images_category ON ngc_images(category);
CREATE INDEX idx_images_org ON ngc_images(organization);
```

**Usage**:
```sql
-- Find PyTorch images
SELECT * FROM ngc_images WHERE category = 'pytorch';

-- Search by name
SELECT * FROM ngc_images WHERE name LIKE '%torch%';
```

---

### 2. image_versions

**Purpose**: Track tags/versions for each image

**Schema**:
```sql
CREATE TABLE image_versions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    image_id INTEGER NOT NULL,
    tag TEXT NOT NULL,
    digest TEXT,
    size_bytes INTEGER,
    created_at DATETIME,
    cuda_version TEXT,
    python_version TEXT,
    framework_version TEXT,
    architecture TEXT DEFAULT 'amd64',
    manifest_json TEXT,         -- Full manifest
    is_cached BOOLEAN DEFAULT 0,
    FOREIGN KEY (image_id) REFERENCES ngc_images(id),
    UNIQUE(image_id, tag)
);
```

**Indexes**:
```sql
CREATE INDEX idx_versions_image ON image_versions(image_id);
```

**Usage**:
```sql
-- Find all versions of PyTorch
SELECT iv.tag, iv.cuda_version, iv.framework_version
FROM image_versions iv
JOIN ngc_images ni ON iv.image_id = ni.id
WHERE ni.name = 'pytorch';

-- Find images with specific CUDA version
SELECT * FROM image_versions WHERE cuda_version = '12.0';
```

---

### 3. container_instances

**Purpose**: Track all containers created by MLEnv

**Schema**:
```sql
CREATE TABLE container_instances (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    container_id TEXT NOT NULL UNIQUE,
    container_name TEXT NOT NULL,
    image_name TEXT NOT NULL,
    project_path TEXT NOT NULL,
    status TEXT DEFAULT 'created',  -- created, running, stopped, error
    
    -- Resource allocation
    cpu_limit REAL,
    memory_limit_gb REAL,
    gpu_devices TEXT,           -- JSON array: ["0", "1"]
    
    -- Port mappings
    port_mappings TEXT,         -- JSON: {"8888": "8888", "6006": "6006"}
    
    -- Timestamps
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    started_at DATETIME,
    stopped_at DATETIME,
    
    -- Metrics (averages)
    cpu_usage_avg REAL,
    memory_usage_avg_gb REAL,
    gpu_utilization_avg REAL
);
```

**Indexes**:
```sql
CREATE INDEX idx_containers_status ON container_instances(status);
CREATE INDEX idx_containers_project ON container_instances(project_path);
```

**Usage**:
```sql
-- List running containers
SELECT container_name, image_name, created_at
FROM container_instances
WHERE status = 'running';

-- Find containers for project
SELECT * FROM container_instances
WHERE project_path = '/home/user/my-project';

-- Get resource usage
SELECT container_name, cpu_usage_avg, memory_usage_avg_gb
FROM container_instances
WHERE status = 'running'
ORDER BY memory_usage_avg_gb DESC;
```

---

### 4. resource_metrics

**Purpose**: Historical resource usage data

**Schema**:
```sql
CREATE TABLE resource_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    container_id TEXT NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    -- System resources
    cpu_percent REAL,
    memory_used_gb REAL,
    memory_percent REAL,
    
    -- GPU resources (JSON array for multi-GPU)
    gpu_metrics TEXT,           -- [{"gpu_id": 0, "utilization": 78, "memory_used": 8192}]
    
    -- I/O
    disk_read_mb REAL,
    disk_write_mb REAL,
    network_rx_mb REAL,
    network_tx_mb REAL,
    
    FOREIGN KEY (container_id) REFERENCES container_instances(container_id)
);
```

**Indexes**:
```sql
CREATE INDEX idx_metrics_container ON resource_metrics(container_id);
CREATE INDEX idx_metrics_timestamp ON resource_metrics(timestamp);
```

**Usage**:
```sql
-- Get last 5 minutes of metrics
SELECT * FROM resource_metrics
WHERE container_id = 'abc123'
  AND timestamp > datetime('now', '-5 minutes');

-- Average CPU usage over last hour
SELECT AVG(cpu_percent) as avg_cpu
FROM resource_metrics
WHERE container_id = 'abc123'
  AND timestamp > datetime('now', '-1 hour');
```

---

### 5. system_snapshots

**Purpose**: System-wide resource snapshots

**Schema**:
```sql
CREATE TABLE system_snapshots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    -- CPU
    cpu_percent REAL,
    cpu_cores INTEGER,
    
    -- Memory
    memory_total_gb REAL,
    memory_used_gb REAL,
    memory_available_gb REAL,
    memory_percent REAL,
    
    -- GPU (JSON array)
    gpu_stats TEXT,             -- [{"gpu_id": 0, "utilization": 45, ...}]
    
    -- Load average
    load_1min REAL,
    load_5min REAL,
    load_15min REAL
);
```

**Indexes**:
```sql
CREATE INDEX idx_snapshots_timestamp ON system_snapshots(timestamp);
```

**Usage**:
```sql
-- Check if system is overloaded
SELECT memory_percent, cpu_percent
FROM system_snapshots
ORDER BY timestamp DESC
LIMIT 1;

-- System load trend
SELECT timestamp, load_1min, memory_percent
FROM system_snapshots
WHERE timestamp > datetime('now', '-1 hour');
```

---

### 6. api_cache

**Purpose**: Cache NGC API responses

**Schema**:
```sql
CREATE TABLE api_cache (
    endpoint TEXT PRIMARY KEY,
    response TEXT,
    cached_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME
);
```

**Usage**:
```sql
-- Get cached response
SELECT response FROM api_cache
WHERE endpoint = '/api/v2/images'
  AND expires_at > datetime('now');

-- Clean expired cache
DELETE FROM api_cache
WHERE expires_at < datetime('now');
```

---

### 7. project_quotas

**Purpose**: Resource quotas per project

**Schema**:
```sql
CREATE TABLE project_quotas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_path TEXT NOT NULL UNIQUE,
    max_containers INTEGER DEFAULT 5,
    max_cpu_cores REAL,
    max_memory_gb REAL,
    max_gpus INTEGER,
    current_containers INTEGER DEFAULT 0,
    current_cpu_cores REAL DEFAULT 0,
    current_memory_gb REAL DEFAULT 0,
    current_gpus INTEGER DEFAULT 0
);
```

**Usage**:
```sql
-- Check if project can create container
SELECT 
    (current_containers < max_containers) as can_create,
    (max_containers - current_containers) as available_slots
FROM project_quotas
WHERE project_path = '/home/user/project';

-- Update quota usage
UPDATE project_quotas
SET current_containers = current_containers + 1,
    current_memory_gb = current_memory_gb + 32
WHERE project_path = '/home/user/project';
```

---

### 8. gpu_allocations

**Purpose**: GPU reservation system

**Schema**:
```sql
CREATE TABLE gpu_allocations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    gpu_id INTEGER NOT NULL,
    container_name TEXT NOT NULL,
    allocated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(gpu_id, container_name)
);
```

**Indexes**:
```sql
CREATE INDEX idx_gpu_allocations_gpu ON gpu_allocations(gpu_id);
CREATE INDEX idx_gpu_allocations_container ON gpu_allocations(container_name);
```

**Usage**:
```sql
-- Find free GPUs
SELECT gpu_id FROM (
    SELECT 0 as gpu_id UNION SELECT 1 UNION SELECT 2 UNION SELECT 3
) all_gpus
WHERE gpu_id NOT IN (SELECT gpu_id FROM gpu_allocations);

-- Allocate GPU
INSERT INTO gpu_allocations (gpu_id, container_name)
VALUES (0, 'mlenv-project-abc123');

-- Release GPU
DELETE FROM gpu_allocations
WHERE container_name = 'mlenv-project-abc123';
```

---

## Views

### 1. v_active_containers

**Purpose**: Active containers with recent metrics

**Definition**:
```sql
CREATE VIEW v_active_containers AS
SELECT 
    ci.container_name,
    ci.image_name,
    ci.project_path,
    ci.status,
    ci.cpu_limit,
    ci.memory_limit_gb,
    ci.gpu_devices,
    ci.created_at,
    ci.started_at,
    ROUND(AVG(rm.cpu_percent), 2) as avg_cpu,
    ROUND(AVG(rm.memory_used_gb), 2) as avg_memory_gb
FROM container_instances ci
LEFT JOIN resource_metrics rm ON ci.container_id = rm.container_id
    AND rm.timestamp > datetime('now', '-5 minutes')
WHERE ci.status = 'running'
GROUP BY ci.container_id;
```

**Usage**:
```sql
-- Get all active containers with metrics
SELECT * FROM v_active_containers;
```

---

### 2. v_system_summary

**Purpose**: System resource summary

**Definition**:
```sql
CREATE VIEW v_system_summary AS
SELECT 
    ROUND(AVG(cpu_percent), 2) as avg_cpu_percent,
    ROUND(MAX(cpu_percent), 2) as max_cpu_percent,
    ROUND(AVG(memory_percent), 2) as avg_memory_percent,
    ROUND(MAX(memory_percent), 2) as max_memory_percent,
    ROUND(AVG(memory_available_gb), 2) as avg_available_gb,
    COUNT(*) as snapshot_count
FROM system_snapshots
WHERE timestamp > datetime('now', '-1 hour');
```

**Usage**:
```sql
-- Get system summary
SELECT * FROM v_system_summary;
```

---

## Database Operations

### Initialization

```bash
# database/init.sh

db_init() {
    local db_path="${MLENV_STATE_DIR}/mlenv.db"
    
    # Create database directory
    mkdir -p "$(dirname "$db_path")"
    
    # Create tables from schema
    sqlite3 "$db_path" < "${MLENV_LIB}/database/schema.sql"
    
    # Set permissions
    chmod 600 "$db_path"
    
    vlog "Database initialized: $db_path"
}
```

### Synchronization

```bash
# database/sync.sh

db_sync_container() {
    local container_id="$1"
    local container_name="$2"
    local image="$3"
    local project_path="$4"
    local status="$5"
    
    sqlite3 "$DB_PATH" <<SQL
INSERT OR REPLACE INTO container_instances (
    container_id, container_name, image_name, project_path, status
) VALUES (
    '$container_id', '$container_name', '$image', '$project_path', '$status'
);
SQL
}
```

### Queries

```bash
# Get container status from database
db_get_container_status() {
    local container_name="$1"
    
    sqlite3 "$DB_PATH" <<SQL
SELECT status FROM container_instances
WHERE container_name = '$container_name'
LIMIT 1;
SQL
}
```

---

## Data Lifecycle

### 1. Container Creation

```
User runs: mlenv up
    ↓
Container created
    ↓
Database updated:
- INSERT into container_instances
- INSERT into gpu_allocations (if GPUs assigned)
- UPDATE project_quotas (increment usage)
```

### 2. Resource Monitoring

```
Background job (every 30s):
    ↓
Collect metrics from docker stats
    ↓
INSERT into resource_metrics
    ↓
UPDATE container_instances (set averages)
```

### 3. Container Deletion

```
User runs: mlenv rm
    ↓
Container removed
    ↓
Database updated:
- UPDATE container_instances (status = 'deleted')
- DELETE from gpu_allocations
- UPDATE project_quotas (decrement usage)
```

---

## Maintenance

### Cleanup Old Data

```sql
-- Delete metrics older than 7 days
DELETE FROM resource_metrics
WHERE timestamp < datetime('now', '-7 days');

-- Delete system snapshots older than 30 days
DELETE FROM system_snapshots
WHERE timestamp < datetime('now', '-30 days');

-- Clean expired API cache
DELETE FROM api_cache
WHERE expires_at < datetime('now');
```

### Vacuum Database

```bash
# Reclaim space
sqlite3 "$DB_PATH" "VACUUM;"
```

### Backup Database

```bash
# Backup to file
sqlite3 "$DB_PATH" ".backup /backup/mlenv.db"

# Or copy file
cp "$DB_PATH" "/backup/mlenv-$(date +%Y%m%d).db"
```

---

## Performance Considerations

### Indexes

All frequently-queried columns have indexes:
- `container_instances.status`
- `container_instances.project_path`
- `resource_metrics.container_id`
- `resource_metrics.timestamp`
- `gpu_allocations.gpu_id`

### Query Optimization

```sql
-- ✅ GOOD - Uses index
SELECT * FROM container_instances WHERE status = 'running';

-- ❌ BAD - Table scan
SELECT * FROM container_instances WHERE LOWER(status) = 'running';

-- ✅ GOOD - Uses index
SELECT * FROM resource_metrics
WHERE timestamp > datetime('now', '-5 minutes');

-- ❌ BAD - Table scan
SELECT * FROM resource_metrics
WHERE datetime(timestamp) > datetime('now', '-5 minutes');
```

### Connection Pooling

```bash
# Reuse database connection
export DB_PATH="${MLENV_STATE_DIR}/mlenv.db"

# Don't open/close for every query
db_query() {
    sqlite3 "$DB_PATH" "$@"
}
```

---

## Future Enhancements

### Multi-User Support (v2.1)
```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT UNIQUE,
    email TEXT,
    quota_profile_id INTEGER
);

ALTER TABLE container_instances ADD COLUMN user_id INTEGER;
```

### Audit Log (v2.1)
```sql
CREATE TABLE audit_log (
    id INTEGER PRIMARY KEY,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    user_id INTEGER,
    action TEXT,
    resource_type TEXT,
    resource_id TEXT,
    details TEXT
);
```

### Health Checks (v2.2)
```sql
CREATE TABLE health_checks (
    id INTEGER PRIMARY KEY,
    container_id TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    status TEXT,  -- healthy, unhealthy, unknown
    last_check DATETIME,
    failure_count INTEGER DEFAULT 0
);
```

---

## Further Reading

- [Architecture Overview](overview.md)
- [Resource Management](../api/resource/README.md)
- [Database API](../api/database/README.md)

---

**Last Updated**: 2026-01-18  
**Version**: 2.0.0
