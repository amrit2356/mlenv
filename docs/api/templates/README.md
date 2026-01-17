# Templates API Reference

## Overview

Project scaffolding system for quick initialization.

**Location**: `lib/mlenv/templates/`

## Modules

| Module | Description | File |
|--------|-------------|------|
| [Engine](engine.md) | Template engine | `engine.sh` |
| [Creating Templates](creating-templates.md) | Template development | - |

## Available Templates

| Template | Description | Location |
|----------|-------------|----------|
| `pytorch` | PyTorch project | `share/mlenv/templates/pytorch/` |
| `minimal` | Minimal project | `share/mlenv/templates/minimal/` |

## Quick Reference

```bash
# List templates
mlenv init --list

# Create from template
mlenv init --template pytorch my-project
```

## Template Structure

```
templates/pytorch/
├── template.yaml        # Template metadata
├── requirements.txt     # Python dependencies
├── .mlenvrc            # MLEnv config
├── README.md           # Project README
└── src/                # Source code
    └── train.py
```

---

**Last Updated**: 2026-01-18
