# Database API Reference

## Overview

SQLite database for state persistence, resource tracking, and NGC catalog caching.

**Location**: `lib/mlenv/database/`  
**Database**: `/var/mlenv/state/mlenv.db`

## Modules

| Module | Description | File |
|--------|-------------|------|
| [Schema](schema.md) | Database schema (9 tables + 2 views) | `schema.sql` |
| [Init](init.md) | Database initialization | `init.sh` |
| [Sync](sync.md) | State synchronization | `sync.sh` |
| [Queries](queries.md) | Common query patterns | - |

## Tables

| Table | Purpose |
|-------|---------|
| `ngc_images` | NGC catalog |
| `image_versions` | Image tags/versions |
| `container_instances` | Container records |
| `resource_metrics` | Resource usage history |
| `system_snapshots` | System resource snapshots |
| `api_cache` | NGC API cache |
| `project_quotas` | Resource quotas |
| `gpu_allocations` | GPU assignments |

## Quick Reference

```sql
-- Get running containers
SELECT * FROM container_instances WHERE status = 'running';

-- Get resource metrics
SELECT * FROM resource_metrics 
WHERE timestamp > datetime('now', '-5 minutes');
```

## Further Reading

- [Database Design](../../architecture/database-design.md)

---

**Last Updated**: 2026-01-18
