#!/usr/bin/env bash
# MLEnv Default Configuration
# Version: 2.0.0

# Set default configuration values
config_set_defaults() {
    # Core settings
    MLENV_CONFIG[core.version]="2.0.0"
    MLENV_CONFIG[core.log_level]="info"
    MLENV_CONFIG[core.default_adapter]="docker"
    
    # Container settings
    MLENV_CONFIG[container.adapter]="docker"
    MLENV_CONFIG[container.default_image]="nvcr.io/nvidia/pytorch:25.12-py3"
    MLENV_CONFIG[container.runtime]="nvidia"
    MLENV_CONFIG[container.restart_policy]="unless-stopped"
    MLENV_CONFIG[container.shm_size]="16g"
    MLENV_CONFIG[container.run_as_user]="true"
    
    # GPU settings
    MLENV_CONFIG[gpu.default_devices]="all"
    MLENV_CONFIG[gpu.auto_detect_free]="false"
    MLENV_CONFIG[gpu.utilization_threshold]="30"
    MLENV_CONFIG[gpu.min_free_memory_mb]="1000"
    
    # Network settings
    MLENV_CONFIG[network.default_ports]=""
    MLENV_CONFIG[network.port_range]="8888-8899"
    MLENV_CONFIG[network.auto_port_forward]="true"
    MLENV_CONFIG[network.network_mode]="bridge"
    
    # Jupyter settings
    MLENV_CONFIG[network.jupyter_default_port]="8888"
    MLENV_CONFIG[network.jupyter_auto_start]="false"
    
    # TensorBoard settings
    MLENV_CONFIG[network.tensorboard_default_port]="6006"
    MLENV_CONFIG[network.tensorboard_auto_start]="false"
    
    # Storage settings
    MLENV_CONFIG[storage.workdir_mount]="/workspace"
    MLENV_CONFIG[storage.cache_dir]="$HOME/.mlenv/cache"
    MLENV_CONFIG[storage.volume_driver]="local"
    MLENV_CONFIG[storage.cache_images]="true"
    MLENV_CONFIG[storage.cache_requirements]="true"
    
    # Resource settings
    MLENV_CONFIG[resources.default_memory_limit]=""
    MLENV_CONFIG[resources.default_cpu_limit]=""
    MLENV_CONFIG[resources.default_gpu_limit]=""
    MLENV_CONFIG[resources.enable_admission_control]="false"
    MLENV_CONFIG[resources.max_memory_percent]="85"
    MLENV_CONFIG[resources.min_available_memory_gb]="4"
    
    # Registry settings
    MLENV_CONFIG[registry.default]="ngc"
    MLENV_CONFIG[registry.ngc_url]="nvcr.io"
    MLENV_CONFIG[registry.dockerhub_url]="docker.io"
    
    # Requirements settings
    MLENV_CONFIG[requirements.auto_detect]="true"
    MLENV_CONFIG[requirements.auto_install]="false"
    MLENV_CONFIG[requirements.force_reinstall]="false"
    
    # DevContainer settings
    MLENV_CONFIG[devcontainer.auto_generate]="true"
    MLENV_CONFIG[devcontainer.vscode_extensions]="ms-python.python,ms-toolsai.jupyter,ms-python.vscode-pylance,charliermarsh.ruff"
    
    # Features
    MLENV_CONFIG[features.enable_plugins]="false"
    MLENV_CONFIG[features.enable_telemetry]="false"
    
    vlog "Default configuration values set"
}
