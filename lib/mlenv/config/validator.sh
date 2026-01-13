#!/usr/bin/env bash
# MLEnv Configuration Validator
# Version: 2.0.0

# Source dependencies
source "${MLENV_LIB}/utils/logging.sh"
source "${MLENV_LIB}/utils/validation.sh"

# Validate entire configuration
config_validate_all() {
    local errors=0
    
    vlog "Validating configuration..."
    
    # Validate adapter
    if ! config_validate_adapter; then
        ((errors++))
    fi
    
    # Validate log level
    if ! config_validate_log_level; then
        ((errors++))
    fi
    
    # Validate ports
    if ! config_validate_ports; then
        ((errors++))
    fi
    
    # Validate GPU settings
    if ! config_validate_gpu; then
        ((errors++))
    fi
    
    # Validate resource limits
    if ! config_validate_resources; then
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        vlog "Configuration validation passed"
        return 0
    else
        warn "Configuration validation found $errors error(s)"
        return 1
    fi
}

# Validate container adapter
config_validate_adapter() {
    local adapter=$(config_get "container.adapter" "docker")
    
    case "$adapter" in
        docker|podman|containerd)
            return 0
            ;;
        *)
            warn "Invalid container adapter: $adapter (using docker)"
            config_set "container.adapter" "docker"
            return 1
            ;;
    esac
}

# Validate log level
config_validate_log_level() {
    local log_level=$(config_get "core.log_level" "info")
    
    case "$log_level" in
        debug|info|warn|error)
            return 0
            ;;
        *)
            warn "Invalid log level: $log_level (using info)"
            config_set "core.log_level" "info"
            return 1
            ;;
    esac
}

# Validate port configuration
config_validate_ports() {
    local ports=$(config_get "network.default_ports" "")
    
    if [[ -z "$ports" ]]; then
        return 0
    fi
    
    if ! validate_ports "$ports"; then
        warn "Invalid port format: $ports"
        return 1
    fi
    
    return 0
}

# Validate GPU settings
config_validate_gpu() {
    local devices=$(config_get "gpu.default_devices" "all")
    
    if ! validate_gpu_devices "$devices"; then
        warn "Invalid GPU devices format: $devices (using all)"
        config_set "gpu.default_devices" "all"
        return 1
    fi
    
    return 0
}

# Validate resource limits
config_validate_resources() {
    local errors=0
    
    # Validate memory limit
    local memory_limit=$(config_get "resources.default_memory_limit" "")
    if [[ -n "$memory_limit" ]] && ! validate_memory_limit "$memory_limit"; then
        warn "Invalid memory limit format: $memory_limit"
        ((errors++))
    fi
    
    # Validate CPU limit
    local cpu_limit=$(config_get "resources.default_cpu_limit" "")
    if [[ -n "$cpu_limit" ]] && ! validate_cpu_limit "$cpu_limit"; then
        warn "Invalid CPU limit format: $cpu_limit"
        ((errors++))
    fi
    
    return $errors
}

# Validate boolean value
config_validate_boolean() {
    local key="$1"
    local value=$(config_get "$key" "")
    
    if [[ -z "$value" ]]; then
        return 0
    fi
    
    if ! validate_boolean "$value"; then
        warn "Invalid boolean value for $key: $value"
        return 1
    fi
    
    return 0
}

# Sanitize configuration values
config_sanitize_all() {
    vlog "Sanitizing configuration values..."
    
    # Normalize boolean values
    for key in "${!MLENV_CONFIG[@]}"; do
        local value="${MLENV_CONFIG[$key]}"
        
        # Check if key name suggests boolean
        if [[ "$key" == *"enable"* ]] || [[ "$key" == *"auto"* ]] || [[ "$key" == *"run_as_user"* ]]; then
            if validate_boolean "$value"; then
                MLENV_CONFIG[$key]=$(normalize_boolean "$value")
            fi
        fi
    done
    
    vlog "Configuration sanitization complete"
}
