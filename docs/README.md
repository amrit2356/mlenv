# MLEnv Documentation

This directory contains the complete documentation for MLEnv v2.0.0.

## 📁 Structure

```
docs/
├── index.md                    # Documentation homepage
├── architecture/               # System architecture
│   ├── overview.md
│   ├── hexagonal-design.md
│   ├── context-system.md
│   ├── config-system.md
│   ├── database-design.md
│   ├── error-handling.md
│   ├── security-model.md
│   ├── module-dependencies.md
│   └── diagrams/              # Architecture diagrams
│
└── api/                       # API documentation
    ├── commands/              # Command reference
    ├── core/                  # Core modules
    ├── adapters/              # Adapters & ports
    ├── config/                # Configuration
    ├── database/              # Database layer
    ├── resource/              # Resource management
    ├── templates/             # Template engine
    └── utils/                 # Utility functions
```

## 🚀 Quick Start

### Viewing Documentation

**Option 1: GitHub (Recommended)**
Browse the documentation directly on GitHub at:
https://github.com/amrit2356/mlenv/tree/main/docs

**Option 2: Local Server**
```bash
cd docs
python3 -m http.server 8000
# Open http://localhost:8000 in your browser
```

**Option 3: GitHub Pages**
Visit: https://amrit2356.github.io/mlenv/

### Navigation

Start with [`index.md`](index.md) for the documentation homepage with complete navigation.

## 📚 Key Sections

### For Users
- Start with the [main README](../README.md)
- Explore [Commands API](api/commands/README.md) for command reference

### For Developers
- Read [Architecture Overview](architecture/overview.md)
- Study [API Documentation](api/core/README.md)

### For Contributors
- Review [Architecture Documentation](architecture/overview.md)
- Check [Module Dependencies](architecture/module-dependencies.md)

## 🔧 Building Documentation

### Generate Diagrams
```bash
./scripts/generate-diagrams.sh
```

### Validate Links
```bash
./scripts/validate-docs.sh
```

### Generate API Docs
```bash
./scripts/generate-api-docs.sh
```

## 📝 Documentation Standards

- Use Markdown for all documentation
- Include code examples that are tested
- Cross-reference related documentation
- Keep diagrams in SVG format (generated from source)
- Follow the template structure in each section

## 🤝 Contributing

To contribute to documentation:

1. Follow the existing structure
2. Use clear, concise language
3. Include practical examples
4. Update the index when adding new docs
5. Validate links before committing

## 📊 Coverage

- ✅ Architecture: 100%
- ✅ Commands API: 100%
- ✅ Core API: 100%
- ✅ Adapters API: 100%
- ✅ Configuration API: 100%
- ✅ Database API: 100%
- ✅ Utilities API: 100%

## 📞 Support

For documentation issues or suggestions:
- Open an [issue](https://github.com/amrit2356/mlenv/issues)
- Submit a [pull request](https://github.com/amrit2356/mlenv/pulls)
- Join [discussions](https://github.com/amrit2356/mlenv/discussions)

---

**Version**: 2.0.0  
**Last Updated**: 2026-01-18
