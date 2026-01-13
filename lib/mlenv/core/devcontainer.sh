#!/usr/bin/env bash
# MLEnv DevContainer Integration
# Version: 2.0.0

# Source dependencies
source "${MLENV_LIB}/utils/logging.sh"

# Create devcontainer config for VS Code integration
devcontainer_create_config() {
    local workdir="$1"
    local devcontainer_dir="$workdir/.devcontainer"
    local devcontainer_file="$devcontainer_dir/devcontainer.json"
    local backup_file="${MLENV_LOG_DIR}/devcontainer.json"
    
    # Create .devcontainer directory
    mkdir -p "$devcontainer_dir"
    
    # Generate devcontainer.json content
    local config_content
    config_content=$(cat <<'DEVCONTAINER_JSON'
{
    "name": "MLEnv GPU Container",
    "workspaceFolder": "/workspace",
    "remoteUser": "ubuntu",
    
    "customizations": {
        "vscode": {
            "extensions": [
                "ms-python.python",
                "ms-toolsai.jupyter",
                "ms-python.vscode-pylance",
                "ms-python.debugpy",
                "charliermarsh.ruff"
            ],
            "settings": {
                "python.defaultInterpreterPath": "/usr/bin/python3",
                "python.terminal.activateEnvironment": false,
                "terminal.integrated.defaultProfile.linux": "bash",
                "terminal.integrated.cwd": "/workspace",
                "files.watcherExclude": {
                    "**/.git/objects/**": true,
                    "**/.git/subtree-cache/**": true,
                    "**/node_modules/*/**": true,
                    "**/.hg/store/**": true,
                    "**/__pycache__/**": true,
                    "**/.mlenv/**": true
                },
                "jupyter.jupyterServerType": "local"
            }
        }
    },
    
    "forwardPorts": [8888, 6006],
    "portsAttributes": {
        "8888": {
            "label": "Jupyter Lab",
            "onAutoForward": "notify"
        },
        "6006": {
            "label": "TensorBoard",
            "onAutoForward": "silent"
        }
    }
}
DEVCONTAINER_JSON
)
    
    # Write to .devcontainer/ (where VS Code expects it)
    echo "$config_content" > "$devcontainer_file"
    
    # Also backup to .mlenv/
    if [[ -n "$backup_file" ]]; then
        echo "$config_content" > "$backup_file"
    fi
    
    vlog "Created devcontainer config: $devcontainer_file"
}

# Check if devcontainer config exists
devcontainer_exists() {
    local workdir="$1"
    [[ -f "$workdir/.devcontainer/devcontainer.json" ]]
}

# Update devcontainer ports
devcontainer_update_ports() {
    local workdir="$1"
    shift
    local ports=("$@")
    
    local devcontainer_file="$workdir/.devcontainer/devcontainer.json"
    
    if [[ ! -f "$devcontainer_file" ]]; then
        return 1
    fi
    
    # Use jq to update ports if available
    if command -v jq >/dev/null 2>&1; then
        local ports_json=$(printf '%s\n' "${ports[@]}" | jq -R . | jq -s .)
        local tmp_file=$(mktemp)
        jq ".forwardPorts = $ports_json" "$devcontainer_file" > "$tmp_file"
        mv "$tmp_file" "$devcontainer_file"
        vlog "Updated devcontainer ports: ${ports[*]}"
    else
        vlog "jq not available - skipping port update"
    fi
}

# Get devcontainer info
devcontainer_get_info() {
    local workdir="$1"
    local devcontainer_file="$workdir/.devcontainer/devcontainer.json"
    
    if [[ -f "$devcontainer_file" ]]; then
        cat "$devcontainer_file"
    fi
}
