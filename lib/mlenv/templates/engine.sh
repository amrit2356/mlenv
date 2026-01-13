#!/usr/bin/env bash
# MLEnv Template Engine
# Version: 2.0.0

# Source dependencies
source "${MLENV_LIB}/utils/logging.sh"
source "${MLENV_LIB}/utils/error.sh"

# Template paths
MLENV_TEMPLATE_DIR="${MLENV_SHARE:-/usr/local/share/mlenv}/templates"
MLENV_USER_TEMPLATE_DIR="$HOME/.mlenv/templates"

# Initialize template system
template_init() {
    vlog "Initializing template system..."
    
    # Create user template directory
    if [[ ! -d "$MLENV_USER_TEMPLATE_DIR" ]]; then
        mkdir -p "$MLENV_USER_TEMPLATE_DIR"
        vlog "Created user template directory: $MLENV_USER_TEMPLATE_DIR"
    fi
}

# List available templates
template_list() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Available Templates"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    echo "Built-in Templates:"
    if [[ -d "$MLENV_TEMPLATE_DIR" ]]; then
        for template in "$MLENV_TEMPLATE_DIR"/*; do
            if [[ -d "$template" ]]; then
                local name=$(basename "$template")
                local desc=""
                if [[ -f "$template/template.yaml" ]]; then
                    desc=$(grep "^description:" "$template/template.yaml" | cut -d: -f2- | xargs)
                fi
                printf "  %-20s %s\n" "$name" "$desc"
            fi
        done
    fi
    
    echo ""
    echo "User Templates:"
    if [[ -d "$MLENV_USER_TEMPLATE_DIR" ]]; then
        local found=0
        for template in "$MLENV_USER_TEMPLATE_DIR"/*; do
            if [[ -d "$template" ]]; then
                local name=$(basename "$template")
                local desc=""
                if [[ -f "$template/template.yaml" ]]; then
                    desc=$(grep "^description:" "$template/template.yaml" | cut -d: -f2- | xargs)
                fi
                printf "  %-20s %s\n" "$name" "$desc"
                found=1
            fi
        done
        if [[ $found -eq 0 ]]; then
            echo "  (none)"
        fi
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Get template path
template_get_path() {
    local template_name="$1"
    
    # Check user templates first
    if [[ -d "$MLENV_USER_TEMPLATE_DIR/$template_name" ]]; then
        echo "$MLENV_USER_TEMPLATE_DIR/$template_name"
        return 0
    fi
    
    # Check built-in templates
    if [[ -d "$MLENV_TEMPLATE_DIR/$template_name" ]]; then
        echo "$MLENV_TEMPLATE_DIR/$template_name"
        return 0
    fi
    
    return 1
}

# Show template details
template_show() {
    local template_name="$1"
    
    local template_path
    template_path=$(template_get_path "$template_name")
    
    if [[ $? -ne 0 ]]; then
        die "Template not found: $template_name"
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Template: $template_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if [[ -f "$template_path/template.yaml" ]]; then
        cat "$template_path/template.yaml"
    else
        echo "No template.yaml found"
    fi
    
    echo ""
    echo "Files:"
    find "$template_path" -type f | sed "s|^$template_path/||" | grep -v "^template.yaml$" | while read -r file; do
        echo "  $file"
    done
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Apply template to project
template_apply() {
    local template_name="$1"
    local project_dir="${2:-.}"
    local project_name="${3:-$(basename "$(pwd)")}"
    
    vlog "Applying template '$template_name' to '$project_dir'"
    
    local template_path
    template_path=$(template_get_path "$template_name")
    
    if [[ $? -ne 0 ]]; then
        die "Template not found: $template_name"
    fi
    
    # Create project directory
    if [[ ! -d "$project_dir" ]]; then
        mkdir -p "$project_dir" || die "Failed to create directory: $project_dir"
        vlog "Created directory: $project_dir"
    fi
    
    cd "$project_dir" || die "Failed to enter directory: $project_dir"
    
    info "Initializing project from template: $template_name"
    
    # Copy template files
    local files_copied=0
    find "$template_path" -type f ! -name "template.yaml" | while read -r file; do
        local rel_path="${file#$template_path/}"
        local target_dir=$(dirname "$rel_path")
        
        # Create target directory if needed
        if [[ "$target_dir" != "." ]] && [[ ! -d "$target_dir" ]]; then
            mkdir -p "$target_dir"
        fi
        
        # Process template variables
        template_process_file "$file" "$rel_path" "$project_name"
        ((files_copied++))
    done
    
    success "Template applied successfully"
    
    # Show next steps
    if [[ -f "README.md" ]]; then
        echo ""
        info "Next steps:"
        echo ""
        sed -n '/## Getting Started/,/##/p' README.md | head -n -1
    fi
}

# Process template file (substitute variables)
template_process_file() {
    local source_file="$1"
    local target_file="$2"
    local project_name="$3"
    
    local author="${USER}"
    local date=$(date +%Y-%m-%d)
    local year=$(date +%Y)
    
    vlog "  Creating: $target_file"
    
    # Substitute variables
    sed -e "s/{{PROJECT_NAME}}/${project_name}/g" \
        -e "s/{{AUTHOR}}/${author}/g" \
        -e "s/{{DATE}}/${date}/g" \
        -e "s/{{YEAR}}/${year}/g" \
        "$source_file" > "$target_file"
}

# Create new template
template_create() {
    local template_name="$1"
    local template_dir="$MLENV_USER_TEMPLATE_DIR/$template_name"
    
    if [[ -d "$template_dir" ]]; then
        die "Template already exists: $template_name"
    fi
    
    info "Creating template: $template_name"
    
    mkdir -p "$template_dir"
    
    # Create template.yaml
    cat > "$template_dir/template.yaml" <<EOF
name: $template_name
description: Custom template
author: ${USER}
created: $(date +%Y-%m-%d)

# Template metadata
category: custom
framework: custom
gpu_required: false

# Default configuration
defaults:
  image: nvcr.io/nvidia/pytorch:25.12-py3
  ports:
    - 8888:8888
    - 6006:6006
  gpu_devices: all

# Files to create
files:
  - requirements.txt
  - README.md
  - .gitignore
EOF
    
    # Create sample files
    cat > "$template_dir/requirements.txt" <<EOF
# {{PROJECT_NAME}} Requirements
# Generated: {{DATE}}

# Add your dependencies here
EOF
    
    cat > "$template_dir/README.md" <<EOF
# {{PROJECT_NAME}}

Created: {{DATE}}
Author: {{AUTHOR}}

## Getting Started

\`\`\`bash
# Start environment
mlenv up --requirements requirements.txt

# Enter container
mlenv exec
\`\`\`

## Description

Add your project description here.
EOF
    
    cat > "$template_dir/.gitignore" <<EOF
# MLEnv
.mlenv/
.devcontainer/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Jupyter
.ipynb_checkpoints
*.ipynb

# IDEs
.vscode/
.idea/
*.swp
*.swo

# Data & Models
data/
models/
*.pth
*.ckpt
*.h5

# Environment
.env
EOF
    
    success "Template created: $template_dir"
    info "Edit files in: $template_dir"
}

# Delete template
template_delete() {
    local template_name="$1"
    
    if [[ ! -d "$MLENV_USER_TEMPLATE_DIR/$template_name" ]]; then
        die "User template not found: $template_name"
    fi
    
    warn "Deleting template: $template_name"
    read -p "Are you sure? [y/N] " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$MLENV_USER_TEMPLATE_DIR/$template_name"
        success "Template deleted: $template_name"
    else
        info "Cancelled"
    fi
}

# Validate template
template_validate() {
    local template_name="$1"
    
    local template_path
    template_path=$(template_get_path "$template_name")
    
    if [[ $? -ne 0 ]]; then
        die "Template not found: $template_name"
    fi
    
    info "Validating template: $template_name"
    
    local errors=0
    
    # Check template.yaml exists
    if [[ ! -f "$template_path/template.yaml" ]]; then
        error "Missing template.yaml"
        ((errors++))
    fi
    
    # Check required fields in template.yaml
    if [[ -f "$template_path/template.yaml" ]]; then
        local required_fields=("name" "description")
        for field in "${required_fields[@]}"; do
            if ! grep -q "^${field}:" "$template_path/template.yaml"; then
                error "Missing required field in template.yaml: $field"
                ((errors++))
            fi
        done
    fi
    
    # Check for at least one file
    local file_count=$(find "$template_path" -type f ! -name "template.yaml" | wc -l)
    if [[ $file_count -eq 0 ]]; then
        error "Template has no files"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        success "Template is valid"
        return 0
    else
        error "Template validation failed with $errors error(s)"
        return 1
    fi
}
