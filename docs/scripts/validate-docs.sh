#!/usr/bin/env bash
# Validate documentation: check links, references, and completeness

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== MLEnv Documentation: Validation ==="
echo

errors=0
warnings=0

# Check for broken internal links
echo "Checking for broken internal links..."
while IFS= read -r -d '' file; do
    # Extract markdown links: [text](path)
    while IFS= read -r link; do
        # Skip external links
        [[ "$link" =~ ^http ]] && continue
        
        # Remove anchor
        link_path="${link%%#*}"
        
        # Skip empty
        [[ -z "$link_path" ]] && continue
        
        # Resolve relative to file directory
        file_dir="$(dirname "$file")"
        full_path="$file_dir/$link_path"
        
        # Check if exists
        if [[ ! -f "$full_path" ]]; then
            echo "  ✖ Broken link in $(basename "$file"): $link_path"
            ((errors++))
        fi
    done < <(grep -oP '\[.*?\]\(\K[^)]+' "$file" 2>/dev/null || true)
done < <(find "$DOCS_DIR" -name "*.md" -type f -print0)

if [[ $errors -eq 0 ]]; then
    echo "  ✓ No broken links found"
fi
echo

# Check for TODO markers
echo "Checking for TODO markers..."
todo_count=$(grep -r "TODO" "$DOCS_DIR" --include="*.md" | wc -l || echo "0")
if [[ $todo_count -gt 0 ]]; then
    echo "  ⚠ Found $todo_count TODO markers"
    ((warnings++))
else
    echo "  ✓ No TODO markers found"
fi
echo

# Check required files exist
echo "Checking required files..."
required_files=(
    "index.md"
    "README.md"
    "architecture/README.md"
    "architecture/overview.md"
    "architecture/hexagonal-design.md"
    "api/commands/README.md"
    "api/core/README.md"
    "_config.yml"
)

for file in "${required_files[@]}"; do
    if [[ ! -f "$DOCS_DIR/$file" ]]; then
        echo "  ✖ Missing required file: $file"
        ((errors++))
    fi
done

if [[ $errors -eq 0 ]]; then
    echo "  ✓ All required files present"
fi
echo

# Summary
echo "=== Validation Summary ==="
echo "Errors: $errors"
echo "Warnings: $warnings"
echo

if [[ $errors -gt 0 ]]; then
    echo "✖ Validation failed with $errors error(s)"
    exit 1
else
    echo "✓ Validation passed!"
    exit 0
fi
