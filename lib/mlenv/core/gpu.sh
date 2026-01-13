#!/usr/bin/env bash
# MLEnv Auto GPU Detection & Allocation
# Version: 2.0.0

# Source dependencies
source "${MLENV_LIB}/utils/logging.sh"
source "${MLENV_LIB}/utils/error.sh"

# GPU selection thresholds (configurable)
GPU_UTILIZATION_THRESHOLD="${MLENV_GPU_UTIL_THRESHOLD:-30}"
GPU_MIN_FREE_MEMORY_MB="${MLENV_GPU_MIN_FREE_MEM:-1000}"

# Get all GPU information
gpu_get_all_info() {
    if ! command -v nvidia-smi >/dev/null 2>&1; then
        error "nvidia-smi not found - no GPU support"
        return 1
    fi
    
    # Get GPU info as JSON-like format
    nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total,memory.free,temperature.gpu \
        --format=csv,noheader,nounits 2>/dev/null
}

# Check if GPU is "free" (low utilization, enough memory)
gpu_is_free() {
    local gpu_id="$1"
    local util="$2"
    local mem_free="$3"
    
    # Check utilization
    if (( util >= GPU_UTILIZATION_THRESHOLD )); then
        return 1
    fi
    
    # Check free memory
    if (( mem_free < GPU_MIN_FREE_MEMORY_MB )); then
        return 1
    fi
    
    return 0
}

# Auto-detect free GPUs
gpu_auto_detect_free() {
    local count="${1:-1}"  # Number of GPUs to select
    
    vlog "Auto-detecting free GPUs (count=$count, util_threshold=${GPU_UTILIZATION_THRESHOLD}%, min_memory=${GPU_MIN_FREE_MEMORY_MB}MB)"
    
    local free_gpus=()
    
    while IFS=, read -r gpu_id name util mem_used mem_total mem_free temp; do
        vlog "  GPU $gpu_id: ${util}% util, ${mem_free}MB free"
        
        if gpu_is_free "$gpu_id" "$util" "$mem_free"; then
            free_gpus+=("$gpu_id")
            vlog "    → Available"
        else
            vlog "    → Busy"
        fi
    done < <(gpu_get_all_info)
    
    # Check if we found enough GPUs
    if [[ ${#free_gpus[@]} -eq 0 ]]; then
        warn "No free GPUs found"
        return 1
    fi
    
    if [[ ${#free_gpus[@]} -lt $count ]]; then
        warn "Only ${#free_gpus[@]} free GPUs found (requested $count)"
    fi
    
    # Return requested number of GPUs (or all available if less)
    local result_count=$(( count < ${#free_gpus[@]} ? count : ${#free_gpus[@]} ))
    local result="${free_gpus[@]:0:$result_count}"
    echo "${result// /,}"
    
    return 0
}

# Get best GPU (lowest utilization)
gpu_get_best() {
    local best_gpu=-1
    local best_util=100
    local best_mem_free=0
    
    while IFS=, read -r gpu_id name util mem_used mem_total mem_free temp; do
        # Prefer low utilization, then high free memory
        if (( util < best_util )) || \
           (( util == best_util && mem_free > best_mem_free )); then
            best_gpu=$gpu_id
            best_util=$util
            best_mem_free=$mem_free
        fi
    done < <(gpu_get_all_info)
    
    if [[ $best_gpu -eq -1 ]]; then
        return 1
    fi
    
    echo "$best_gpu"
    return 0
}

# Show GPU status
gpu_status() {
    if ! command -v nvidia-smi >/dev/null 2>&1; then
        echo "No NVIDIA GPUs detected"
        return 1
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "GPU Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total,memory.free,temperature.gpu \
        --format=table 2>/dev/null
    
    echo ""
    echo "Free GPUs (util<${GPU_UTILIZATION_THRESHOLD}%, mem>${GPU_MIN_FREE_MEMORY_MB}MB):"
    
    local free_count=0
    while IFS=, read -r gpu_id name util mem_used mem_total mem_free temp; do
        if gpu_is_free "$gpu_id" "$util" "$mem_free"; then
            echo "  GPU $gpu_id: $name (${util}% util, ${mem_free}MB free)"
            ((free_count++))
        fi
    done < <(gpu_get_all_info)
    
    if [[ $free_count -eq 0 ]]; then
        echo "  (none available)"
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Allocate GPUs for container
gpu_allocate() {
    local strategy="${1:-auto}"  # auto, best, all, specific (0,1,2)
    local count="${2:-1}"
    
    case "$strategy" in
        auto)
            gpu_auto_detect_free "$count"
            ;;
        best)
            gpu_get_best
            ;;
        all)
            echo "all"
            ;;
        [0-9]*)
            # Specific GPU IDs provided
            echo "$strategy"
            ;;
        *)
            warn "Unknown GPU strategy: $strategy (using all)"
            echo "all"
            ;;
    esac
}

# Check GPU availability
gpu_check_available() {
    if ! command -v nvidia-smi >/dev/null 2>&1; then
        return 1
    fi
    
    local gpu_count
    gpu_count=$(nvidia-smi --list-gpus 2>/dev/null | wc -l)
    
    if [[ $gpu_count -gt 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Get GPU count
gpu_get_count() {
    if ! gpu_check_available; then
        echo "0"
        return 1
    fi
    
    nvidia-smi --list-gpus 2>/dev/null | wc -l
}

# Wait for GPU to become free
gpu_wait_for_free() {
    local timeout="${1:-300}"  # 5 minutes default
    local interval="${2:-10}"   # Check every 10 seconds
    
    info "Waiting for free GPU (timeout: ${timeout}s)..."
    
    local elapsed=0
    while (( elapsed < timeout )); do
        local free_gpu
        free_gpu=$(gpu_auto_detect_free 1)
        
        if [[ -n "$free_gpu" ]]; then
            success "GPU $free_gpu available"
            echo "$free_gpu"
            return 0
        fi
        
        echo -n "."
        sleep "$interval"
        ((elapsed += interval))
    done
    
    echo ""
    warn "Timeout waiting for free GPU"
    return 1
}
