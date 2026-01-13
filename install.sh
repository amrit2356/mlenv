#!/bin/bash
# MLEnv Installation Script
# Version: 2.0.0

set -e

VERSION="2.0.0"
PREFIX="${PREFIX:-/usr/local}"
INSTALL_DIR="${PREFIX}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✖${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    local missing=()
    
    info "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker >/dev/null 2>&1; then
        missing+=("docker")
    elif ! docker info >/dev/null 2>&1; then
        warn "Docker is installed but daemon is not running"
    else
        success "Docker found"
    fi
    
    # Check sqlite3
    if ! command -v sqlite3 >/dev/null 2>&1; then
        missing+=("sqlite3")
    else
        success "sqlite3 found"
    fi
    
    # Check bash version
    if ! bash --version | head -1 | grep -q "version [4-9]"; then
        missing+=("bash >= 4.0")
    else
        success "bash found"
    fi
    
    # Check optional dependencies
    if ! command -v jq >/dev/null 2>&1; then
        warn "jq not found (optional, recommended for JSON parsing)"
    else
        success "jq found"
    fi
    
    if ! command -v nvidia-smi >/dev/null 2>&1; then
        warn "nvidia-smi not found (required for GPU support)"
    elif ! docker info 2>/dev/null | grep -q "Runtimes:.*nvidia"; then
        warn "NVIDIA Container Toolkit not detected"
    else
        success "NVIDIA Container Toolkit found"
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing[*]}"
        echo ""
        echo "Install with:"
        echo "  Ubuntu/Debian: sudo apt-get install docker.io sqlite3"
        echo "  RHEL/CentOS:   sudo yum install docker sqlite"
        echo ""
        return 1
    fi
    
    return 0
}

# Install MLEnv
install_mlenv() {
    info "Installing MLEnv v${VERSION} to ${INSTALL_DIR}..."
    echo ""
    
    # Create directories
    mkdir -p "${INSTALL_DIR}/bin"
    mkdir -p "${INSTALL_DIR}/lib/mlenv"
    mkdir -p "/etc/mlenv"
    mkdir -p "${INSTALL_DIR}/share/mlenv"
    mkdir -p "/var/mlenv/registry"
    mkdir -p "/var/mlenv/cache"
    mkdir -p "/var/mlenv/plugins"
    
    # Install binary
    info "Installing binary..."
    install -m 0755 bin/mlenv "${INSTALL_DIR}/bin/mlenv"
    success "Binary installed"
    
    # Install libraries
    info "Installing libraries..."
    cp -r lib/mlenv/* "${INSTALL_DIR}/lib/mlenv/"
    chmod +x "${INSTALL_DIR}/lib/mlenv/core"/*.sh 2>/dev/null || true
    chmod +x "${INSTALL_DIR}/lib/mlenv/adapters"/*/*.sh 2>/dev/null || true
    chmod +x "${INSTALL_DIR}/lib/mlenv/commands"/*.sh 2>/dev/null || true
    success "Libraries installed"
    
    # Install configuration
    info "Installing configuration..."
    if [[ ! -f "/etc/mlenv/mlenv.conf" ]]; then
        install -m 0644 etc/mlenv/mlenv.conf "/etc/mlenv/mlenv.conf"
        success "Configuration installed"
    else
        info "Configuration exists, skipping"
    fi
    
    # Install shared files
    info "Installing templates and examples..."
    cp -r share/mlenv/* "${INSTALL_DIR}/share/mlenv/"
    success "Shared files installed"
    
    # Install bash completions
    if [[ -d "/usr/share/bash-completion/completions" ]]; then
        info "Installing bash completions..."
        # Placeholder for future completion file
        success "Completions ready"
    fi
    
    # Initialize database
    info "Initializing database..."
    export MLENV_LIB="${INSTALL_DIR}/lib/mlenv"
    export MLENV_VAR="/var/mlenv"
    source "${MLENV_LIB}/utils/logging.sh"
    source "${MLENV_LIB}/database/init.sh"
    
    if db_init >/dev/null 2>&1; then
        success "Database initialized"
    else
        warn "Database initialization failed (will retry on first use)"
    fi
    
    echo ""
    success "MLEnv v${VERSION} installed successfully!"
    echo ""
}

# Show post-install message
show_post_install() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "MLEnv v${VERSION} - Installation Complete"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Quick Start:"
    echo ""
    echo "  1. Verify installation:"
    echo "     mlenv version"
    echo ""
    echo "  2. Create a project:"
    echo "     mlenv init --template pytorch my-project"
    echo ""
    echo "  3. Start container:"
    echo "     cd my-project"
    echo "     mlenv up --auto-gpu"
    echo ""
    echo "  4. Enter container:"
    echo "     mlenv exec"
    echo ""
    echo "Documentation:"
    echo "  - User guide:    mlenv help"
    echo "  - Configuration: ${INSTALL_DIR}/share/mlenv/examples/mlenvrc.example"
    echo "  - Templates:     mlenv init --list"
    echo ""
    echo "Support:"
    echo "  - Issues: https://github.com/your-username/mlenv/issues"
    echo ""
}

# Uninstall MLEnv
uninstall_mlenv() {
    info "Uninstalling MLEnv..."
    
    rm -f "${INSTALL_DIR}/bin/mlenv"
    rm -rf "${INSTALL_DIR}/lib/mlenv"
    rm -rf "/etc/mlenv"
    rm -rf "${INSTALL_DIR}/share/mlenv"
    
    echo ""
    read -p "Remove user data (/var/mlenv)? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "/var/mlenv"
        success "User data removed"
    else
        info "User data preserved in /var/mlenv"
    fi
    
    success "MLEnv uninstalled"
}

# Main
main() {
    case "${1:-install}" in
        install)
            if ! check_prerequisites; then
                exit 1
            fi
            install_mlenv
            show_post_install
            ;;
        uninstall)
            uninstall_mlenv
            ;;
        check)
            check_prerequisites
            ;;
        --help|-h)
            echo "MLEnv Installation Script v${VERSION}"
            echo ""
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  install     Install MLEnv (default)"
            echo "  uninstall   Remove MLEnv"
            echo "  check       Check prerequisites only"
            echo ""
            echo "Environment Variables:"
            echo "  PREFIX      Installation prefix (default: /usr/local)"
            echo ""
            echo "Examples:"
            echo "  sudo ./install.sh"
            echo "  PREFIX=/opt sudo ./install.sh"
            echo "  sudo ./install.sh uninstall"
            ;;
        *)
            error "Unknown command: $1"
            echo "Run: $0 --help"
            exit 1
            ;;
    esac
}

main "$@"
