# Utilities API Reference

## Overview

Reusable utility functions used throughout MLEnv.

**Location**: `lib/mlenv/utils/`

## Modules

| Module | Description | File |
|--------|-------------|------|
| [Logging](logging.md) | Structured logging | `logging.sh` |
| [Error](error.md) | Error handling | `error.sh` |
| [Validation](validation.md) | Input validation | `validation.sh` |
| [Cleanup](cleanup.md) | Resource cleanup | `cleanup.sh` |
| [Cache](cache.md) | Caching system | `cache.sh` |
| [Locking](locking.md) | File locking | `locking.sh` |
| [Retry](retry.md) | Retry logic | `retry.sh` |
| [Sanitization](sanitization.md) | Input sanitization | `sanitization.sh` |
| [Port Utils](port-utils.md) | Port management | `port-utils.sh` |
| [Container Utils](container-utils.md) | Container utilities | `container-utils.sh` |
| [Resource Tracker](resource-tracker.md) | Resource tracking | `resource-tracker.sh` |
| [Command Helpers](command-helpers.md) | Command helpers | `command-helpers.sh` |

## Quick Reference

```bash
# Logging
log_info "Message"
log_error "Error message"
vlog "Verbose message"  # Only if --verbose

# Error handling
error "Error occurred"
die "Fatal error"  # Exits with 1

# Validation
validate_container_name "$name"
validate_image_name "$image"
validate_memory_format "$memory"
```

## Design Principle

**No Dependencies**: Utility modules must not depend on other MLEnv modules.

---

**Last Updated**: 2026-01-18
