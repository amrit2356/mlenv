#!/usr/bin/env bash
# MLEnv Image Management Core Logic
# Version: 2.0.0

# Source dependencies
source "${MLENV_LIB}/utils/logging.sh"
source "${MLENV_LIB}/utils/error.sh"
source "${MLENV_LIB}/utils/validation.sh"

# Check if image should be pulled
image_needs_pull() {
    local image="$1"
    
    # Will be implemented via adapter
    # Returns 0 if needs pull, 1 if already local
    true
}

# Pull image with progress
image_pull_with_progress() {
    local image="$1"
    
    log "▶ Pulling image: $image"
    info "This may take a few minutes on first run..."
    
    # Actual pull will be done via adapter
    # This is just the wrapper logic
    vlog "Pull requested for: $image"
}

# Validate image name
image_validate() {
    local image="$1"
    
    if ! validate_image_name "$image"; then
        die "Invalid image name: $image"
    fi
    
    vlog "Image name validated: $image"
}

# Parse image components
image_parse() {
    local image="$1"
    
    # Extract registry, org, name, tag
    local registry=""
    local org=""
    local name=""
    local tag="latest"
    
    # Split by tag first
    if [[ "$image" =~ ^(.+):(.+)$ ]]; then
        image="${BASH_REMATCH[1]}"
        tag="${BASH_REMATCH[2]}"
    fi
    
    # Split by /
    IFS='/' read -ra PARTS <<< "$image"
    
    case "${#PARTS[@]}" in
        1)
            # Just name
            name="${PARTS[0]}"
            ;;
        2)
            # org/name or registry/name
            if [[ "${PARTS[0]}" =~ \. ]]; then
                registry="${PARTS[0]}"
                name="${PARTS[1]}"
            else
                org="${PARTS[0]}"
                name="${PARTS[1]}"
            fi
            ;;
        3)
            # registry/org/name
            registry="${PARTS[0]}"
            org="${PARTS[1]}"
            name="${PARTS[2]}"
            ;;
    esac
    
    echo "registry=${registry}"
    echo "org=${org}"
    echo "name=${name}"
    echo "tag=${tag}"
}

# Get default image from config
image_get_default() {
    echo "${MLENV_DEFAULT_IMAGE:-nvcr.io/nvidia/pytorch:25.12-py3}"
}

# Interface methods (implemented by adapters)
image_exists() {
    local image="$1"
    die "image_exists not implemented - adapter not loaded"
}

image_pull() {
    local image="$1"
    die "image_pull not implemented - adapter not loaded"
}

image_inspect() {
    local image="$1"
    die "image_inspect not implemented - adapter not loaded"
}
