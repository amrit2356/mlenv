#!/usr/bin/env bash
# MLEnv Authentication Core Logic (NGC)
# Version: 2.0.0

# Source dependencies
source "${MLENV_LIB}/utils/logging.sh"
source "${MLENV_LIB}/utils/error.sh"

# NGC Configuration
NGC_CONFIG_DIR="${MLENV_NGC_CONFIG_DIR:-$HOME/.mlenv}"
NGC_CONFIG_FILE="${NGC_CONFIG_DIR}/config"
NGC_REGISTRY="${MLENV_NGC_REGISTRY:-nvcr.io}"

# Check if authenticated with NGC
auth_is_authenticated() {
    # Check if Docker is logged into nvcr.io
    if docker info 2>/dev/null | grep -q "Username.*nvcr.io" || \
       grep -q "nvcr.io" ~/.docker/config.json 2>/dev/null; then
        return 0
    fi
    
    # Also check our config file
    if [[ -f "$NGC_CONFIG_FILE" ]]; then
        return 0
    fi
    
    return 1
}

# Check if NGC authentication is required for image
auth_check_required() {
    local image="$1"
    
    # Check if trying to use private NGC image
    if [[ "$image" == *"nvcr.io"* ]] && [[ "$image" != *"/nvidia/"* ]]; then
        # Private image - require authentication
        if ! auth_is_authenticated; then
            error "Private NGC image requires authentication"
            info "Run: mlenv login"
            return 1
        fi
    fi
    
    return 0
}

# Save NGC credentials
auth_save_credentials() {
    local api_key="$1"
    
    mkdir -p "$NGC_CONFIG_DIR"
    chmod 700 "$NGC_CONFIG_DIR"
    
    cat > "$NGC_CONFIG_FILE" <<EOF
; NVIDIA NGC CLI Configuration
[CURRENT]
apikey = $api_key
format_type = ascii
org = 

EOF
    chmod 600 "$NGC_CONFIG_FILE"
    vlog "NGC credentials saved to $NGC_CONFIG_FILE"
}

# Login to NGC
auth_login() {
    log "▶ NGC Authentication Setup"
    echo ""
    
    info "NVIDIA NGC allows you to access private container images and models"
    info "You'll need an NGC API key from: https://ngc.nvidia.com/setup/api-key"
    echo ""
    
    # Prompt for API key
    read -p "Enter your NGC API Key: " -s api_key
    echo ""
    
    if [[ -z "$api_key" ]]; then
        die "API key cannot be empty"
    fi
    
    log "▶ Logging into $NGC_REGISTRY..."
    
    # Login to Docker registry
    if echo "$api_key" | docker login "$NGC_REGISTRY" --username '$oauthtoken' --password-stdin >> "${MLENV_LOG_FILE:-/dev/null}" 2>&1; then
        success "Successfully logged into $NGC_REGISTRY"
        
        # Save credentials to NGC config
        auth_save_credentials "$api_key"
        
        echo ""
        success "NGC authentication complete!"
        info "You can now pull private images from $NGC_REGISTRY"
        echo ""
        info "Example: mlenv up --image nvcr.io/your-org/your-image:tag"
    else
        die "Login failed. Please check your API key and try again."
    fi
}

# Logout from NGC
auth_logout() {
    log "▶ Logging out of NGC"
    
    # Logout from Docker registry
    if docker logout "$NGC_REGISTRY" >> "${MLENV_LOG_FILE:-/dev/null}" 2>&1; then
        success "Logged out of $NGC_REGISTRY"
    fi
    
    # Remove saved credentials
    if [[ -f "$NGC_CONFIG_FILE" ]]; then
        rm -f "$NGC_CONFIG_FILE"
        success "Removed NGC credentials"
    fi
    
    echo ""
    info "You'll need to run 'mlenv login' again to access private images"
}

# Get stored API key
auth_get_api_key() {
    if [[ -f "$NGC_CONFIG_FILE" ]]; then
        grep "^apikey" "$NGC_CONFIG_FILE" | cut -d= -f2 | xargs
    fi
}

# Validate API key format
auth_validate_api_key() {
    local api_key="$1"
    
    # NGC API keys are typically long alphanumeric strings
    if [[ -z "$api_key" ]]; then
        return 1
    fi
    
    if [[ ${#api_key} -lt 20 ]]; then
        return 1
    fi
    
    return 0
}
