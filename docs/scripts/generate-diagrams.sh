#!/usr/bin/env bash
# Generate architecture diagrams from Mermaid source

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(dirname "$SCRIPT_DIR")"
DIAGRAMS_DIR="$DOCS_DIR/architecture/diagrams"

echo "=== MLEnv Documentation: Generate Diagrams ==="
echo

# Check if mmdc (Mermaid CLI) is installed
if ! command -v mmdc >/dev/null 2>&1; then
    echo "✖ Mermaid CLI (mmdc) not found"
    echo "Install: npm install -g @mermaid-js/mermaid-cli"
    echo
    echo "For now, diagrams will be placeholders."
    echo "Create diagrams manually or install Mermaid CLI."
    exit 0
fi

# Create diagrams directory
mkdir -p "$DIAGRAMS_DIR"

echo "✓ Mermaid CLI found"
echo "✓ Diagrams directory: $DIAGRAMS_DIR"
echo

# Note: Diagram generation would require Mermaid source files
# For now, create placeholder SVGs

echo "Creating placeholder diagrams..."

cat > "$DIAGRAMS_DIR/architecture.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="800" height="600">
  <rect width="800" height="600" fill="#f5f5f5"/>
  <text x="400" y="300" font-size="24" text-anchor="middle" fill="#333">
    MLEnv Architecture Diagram
  </text>
  <text x="400" y="340" font-size="16" text-anchor="middle" fill="#666">
    (Generate using Mermaid CLI or draw.io)
  </text>
</svg>
EOF

cat > "$DIAGRAMS_DIR/hexagonal-structure.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="800" height="600">
  <rect width="800" height="600" fill="#f5f5f5"/>
  <text x="400" y="300" font-size="24" text-anchor="middle" fill="#333">
    Hexagonal Architecture Diagram
  </text>
  <text x="400" y="340" font-size="16" text-anchor="middle" fill="#666">
    (Ports & Adapters Pattern)
  </text>
</svg>
EOF

cat > "$DIAGRAMS_DIR/context-flow.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="800" height="600">
  <rect width="800" height="600" fill="#f5f5f5"/>
  <text x="400" y="300" font-size="24" text-anchor="middle" fill="#333">
    Context Flow Diagram
  </text>
</svg>
EOF

cat > "$DIAGRAMS_DIR/config-precedence.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="800" height="600">
  <rect width="800" height="600" fill="#f5f5f5"/>
  <text x="400" y="300" font-size="24" text-anchor="middle" fill="#333">
    Configuration Precedence Diagram
  </text>
</svg>
EOF

cat > "$DIAGRAMS_DIR/command-flow.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="800" height="600">
  <rect width="800" height="600" fill="#f5f5f5"/>
  <text x="400" y="300" font-size="24" text-anchor="middle" fill="#333">
    Command Execution Flow
  </text>
</svg>
EOF

cat > "$DIAGRAMS_DIR/adapter-interaction.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="800" height="600">
  <rect width="800" height="600" fill="#f5f5f5"/>
  <text x="400" y="300" font-size="24" text-anchor="middle" fill="#333">
    Adapter Interaction Diagram
  </text>
</svg>
EOF

cat > "$DIAGRAMS_DIR/database-schema.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="800" height="600">
  <rect width="800" height="600" fill="#f5f5f5"/>
  <text x="400" y="300" font-size="24" text-anchor="middle" fill="#333">
    Database Schema Diagram
  </text>
</svg>
EOF

cat > "$DIAGRAMS_DIR/module-dependencies.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="800" height="600">
  <rect width="800" height="600" fill="#f5f5f5"/>
  <text x="400" y="300" font-size="24" text-anchor="middle" fill="#333">
    Module Dependencies Diagram
  </text>
</svg>
EOF

echo "✓ Created 8 placeholder diagram files"
echo
echo "Done! Diagrams created in: $DIAGRAMS_DIR/"
echo
echo "To create actual diagrams:"
echo "1. Install Mermaid CLI: npm install -g @mermaid-js/mermaid-cli"
echo "2. Create .mmd files with Mermaid syntax"
echo "3. Run: mmdc -i diagram.mmd -o diagram.svg"
