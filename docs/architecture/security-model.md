# Security Model

## Overview

MLEnv implements multiple security layers including user mapping, admission control, input validation, and secure credential storage.

## Security Layers

### 1. User Mapping

**Problem**: Containers running as root create permission issues

**Solution**: Map container user to host user

```bash
# Default behavior
docker run --user "$(id -u):$(id -g)" "$image"

# Result: Files created in container have correct ownership on host
```

**Configuration**:
```ini
[container]
user_mapping = true  # Default
```

**Disable** (not recommended):
```bash
mlenv up --no-user-mapping
```

### 2. Admission Control

**Purpose**: Prevent system crashes from resource exhaustion

**Checks**:
- Memory usage < 85%
- CPU usage < 90%
- Available memory > 4GB
- Load average < (cores * 2)

**Implementation**:
```bash
admission_check_container_creation() {
    # Check memory
    local mem_percent=$(get_memory_percent)
    if [[ $mem_percent -gt 85 ]]; then
        error "System memory at ${mem_percent}% (threshold: 85%)"
        return 1
    fi
    
    # Check available memory
    local avail_gb=$(get_available_memory_gb)
    if [[ $(echo "$avail_gb < 4" | bc) -eq 1 ]]; then
        error "Only ${avail_gb}GB available (minimum: 4GB)"
        return 1
    fi
    
    return 0
}
```

### 3. Input Validation

**Container Names**:
```bash
validate_container_name() {
    local name="$1"
    
    # Must match: [a-zA-Z0-9][a-zA-Z0-9_.-]*
    if [[ ! "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$ ]]; then
        return 1
    fi
    
    # Length: 1-255 characters
    if [[ ${#name} -lt 1 || ${#name} -gt 255 ]]; then
        return 1
    fi
    
    return 0
}
```

**Image Names**:
```bash
validate_image_name() {
    local image="$1"
    
    # Format: [registry/]repository[:tag]
    if [[ ! "$image" =~ ^([a-z0-9.-]+/)?[a-z0-9._-]+(/[a-z0-9._-]+)*(:[a-zA-Z0-9._-]+)?$ ]]; then
        return 1
    fi
    
    return 0
}
```

**File Paths**:
```bash
sanitize_path() {
    local path="$1"
    
    # Remove ".." (directory traversal)
    path="${path//..\/}"
    
    # Remove leading/trailing spaces
    path=$(echo "$path" | xargs)
    
    # Resolve to absolute path
    path=$(realpath -m "$path")
    
    echo "$path"
}
```

### 4. Credential Storage

**NGC API Key**:
```bash
# Store in user-only readable file
save_ngc_api_key() {
    local api_key="$1"
    local key_file="$HOME/.mlenv/ngc_api_key"
    
    # Create directory
    mkdir -p "$(dirname "$key_file")"
    
    # Write key
    echo "$api_key" > "$key_file"
    
    # Set permissions: user read/write only
    chmod 600 "$key_file"
}

# Load from file
load_ngc_api_key() {
    local key_file="$HOME/.mlenv/ngc_api_key"
    
    if [[ -f "$key_file" ]]; then
        cat "$key_file"
    fi
}
```

### 5. Command Injection Prevention

```bash
# ❌ BAD - Command injection vulnerability
container_exec() {
    local cmd="$1"
    docker exec "$container" bash -c "$cmd"
}
# Attacker: mlenv exec -c "rm -rf / #"

# ✅ GOOD - Properly escaped
container_exec() {
    local cmd="$1"
    docker exec "$container" bash -c "${cmd@Q}"
}
```

### 6. Resource Isolation

**CPU Limits**:
```bash
docker run --cpus="8" "$image"
```

**Memory Limits**:
```bash
docker run --memory="32g" --memory-swap="32g" "$image"
```

**GPU Isolation**:
```bash
docker run --gpus "device=0,1" "$image"
```

**Network Isolation** (future):
```bash
docker run --network="isolated" "$image"
```

### 7. File System Security

**Read-Only Mounts** (future):
```bash
docker run -v /data:/data:ro "$image"
```

**Tmpfs for Secrets**:
```bash
docker run --tmpfs /secrets:rw,noexec,nosuid "$image"
```

## Security Best Practices

### 1. Never Run as Root
```bash
# Default: user mapping enabled
RUN_AS_USER=true
```

### 2. Use Official Images
```bash
# ✅ GOOD - Official NVIDIA image
nvcr.io/nvidia/pytorch:25.12-py3

# ⚠ CAUTION - Unknown source
random-registry.com/pytorch:latest
```

### 3. Limit Resources
```bash
# Always set limits
mlenv up --memory 32g --cpus 8
```

### 4. Enable Admission Control
```bash
# System config: /etc/mlenv/mlenv.conf
[resource]
enable_admission_control = true
memory_threshold = 85
cpu_threshold = 90
```

### 5. Secure Credentials
```bash
# ✅ GOOD - File permissions: 600
chmod 600 ~/.mlenv/ngc_api_key

# ❌ BAD - World readable
chmod 644 ~/.mlenv/ngc_api_key
```

### 6. Validate All Inputs
```bash
cmd_up() {
    # Validate everything
    validate_container_name "$name"
    validate_image_name "$image"
    validate_memory_format "$memory"
    validate_cpu_format "$cpus"
}
```

## Security Checklist

- [ ] User mapping enabled
- [ ] Admission control enabled
- [ ] Input validation on all user input
- [ ] Credentials stored with 600 permissions
- [ ] Resource limits set
- [ ] Official images used
- [ ] Regular security updates
- [ ] Audit logs enabled (future)

## Threat Model

### Threats

1. **Resource Exhaustion**
   - Mitigation: Admission control
   
2. **Privilege Escalation**
   - Mitigation: User mapping, no root
   
3. **Command Injection**
   - Mitigation: Input validation, proper escaping
   
4. **Credential Theft**
   - Mitigation: 600 permissions, encrypted storage (future)
   
5. **Container Breakout**
   - Mitigation: Docker security features, seccomp, AppArmor

## Future Enhancements

### v2.1
- Audit logging
- Role-based access control (RBAC)
- Encrypted credential storage

### v2.2
- Seccomp profiles
- AppArmor profiles
- SELinux support
- Container signing/verification

## Further Reading

- [Admission Control API](../api/resource/admission.md)
- [Security Guidelines](../../docs.backup/development/phase1-architecture.md)
- [Docker Security](https://docs.docker.com/engine/security/)

---

**Last Updated**: 2026-01-18  
**Version**: 2.0.0
