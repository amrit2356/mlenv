# Resource Management API Reference

## Overview

Admission control and resource monitoring to prevent system crashes.

**Location**: `lib/mlenv/resource/`

## Modules

| Module | Description | File |
|--------|-------------|------|
| [Admission](admission.md) | Admission control system | `admission.sh` |
| [Monitoring](monitoring.md) | Resource monitoring | - |
| [Quotas](quotas.md) | Project quotas | - |

## Admission Control

**Purpose**: Prevent system crashes from resource exhaustion

**Checks**:
- Memory usage < 85%
- CPU usage < 90%
- Available memory > 4GB
- Load average reasonable

```bash
# Check before container creation
if ! admission_check_container_creation "$name" "$memory" "$cpu" "$gpus"; then
    die "Admission control denied"
fi
```

## Configuration

```ini
[resource]
enable_admission_control = true
memory_threshold = 85
cpu_threshold = 90
min_available_memory_gb = 4
```

---

**Last Updated**: 2026-01-18
