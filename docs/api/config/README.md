# Configuration API Reference

## Overview

Configuration system with 4-level hierarchy: System → User → Project → CLI.

**Location**: `lib/mlenv/config/`

## Modules

| Module | Description | File |
|--------|-------------|------|
| [Parser](parser.md) | INI file parser | `parser.sh` |
| [Defaults](defaults.md) | Default values | `defaults.sh` |
| [Accessor](accessor.md) | Get config values | `accessor.sh` |
| [Validator](validator.md) | Validate config | `validator.sh` |

## Quick Reference

```bash
# Get effective configuration value (respects hierarchy)
value=$(config_get_effective "container.default_image" "ubuntu:22.04")

# Precedence: CLI > Project > User > System > Default
```

## Configuration Hierarchy

```
CLI Args (--image)           Priority 1 (highest)
    ↓
./.mlenvrc                   Priority 2
    ↓
~/.mlenvrc                   Priority 3
    ↓
/etc/mlenv/mlenv.conf        Priority 4
    ↓
Hardcoded Defaults           Priority 5 (lowest)
```

## Further Reading

- [Configuration System](../../architecture/config-system.md)

---

**Last Updated**: 2026-01-18
