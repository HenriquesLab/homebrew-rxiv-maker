#!/bin/bash

# Setup script for installing and configuring Homebrew on Linux
# Used by GitHub Actions workflow for consistent environment setup

set -euo pipefail

# Configuration
HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/home/linuxbrew/.linuxbrew}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-600}"
VERBOSE="${VERBOSE:-0}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Verbose logging
log_debug() {
    if [[ "${VERBOSE}" == "1" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1" >&2
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if we're running on Linux
check_linux() {
    if [[ "$(uname -s)" != "Linux" ]]; then
        log_error "This script is intended for Linux only"
        exit 1
    fi
}

# Install system dependencies required for Homebrew
install_system_dependencies() {
    log_info "Installing system dependencies for Homebrew..."
    
    # Detect package manager
    if command_exists apt-get; then
        log_debug "Using apt package manager"
        export DEBIAN_FRONTEND=noninteractive
        
        # Update package list
        sudo apt-get update -qq
        
        # Install required packages
        sudo apt-get install -y \
            build-essential \
            procps \
            curl \
            file \
            git \
            locales \
            ca-certificates \
            gzip \
            libz-dev \
            libbz2-dev \
            libreadline-dev \
            libsqlite3-dev \
            libssl-dev \
            libxml2-dev \
            libxslt-dev \
            zlib1g-dev
            
    elif command_exists yum; then
        log_debug "Using yum package manager"
        sudo yum groupinstall -y 'Development Tools'
        sudo yum install -y \
            procps-ng \
            curl \
            file \
            git \
            libxcrypt-compat
            
    elif command_exists dnf; then
        log_debug "Using dnf package manager"
        sudo dnf groupinstall -y 'Development Tools'
        sudo dnf install -y \
            procps-ng \
            curl \
            file \
            git \
            libxcrypt-compat
    else
        log_warning "Unknown package manager - continuing anyway"
    fi
    
    log_success "System dependencies installed"
}

# Install Homebrew
install_homebrew() {
    log_info "Installing Homebrew..."
    
    # Download and run Homebrew installer
    timeout "${TIMEOUT_SECONDS}" bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
        log_error "Homebrew installation failed or timed out"
        return 1
    }
    
    log_success "Homebrew installation completed"
}

# Configure Homebrew environment
configure_homebrew() {
    log_info "Configuring Homebrew environment..."
    
    # Add Homebrew to PATH for current session
    export PATH="${HOMEBREW_PREFIX}/bin:${PATH}"
    
    # Set environment variables
    export HOMEBREW_PREFIX
    export HOMEBREW_CELLAR="${HOMEBREW_PREFIX}/Cellar"
    export HOMEBREW_REPOSITORY="${HOMEBREW_PREFIX}/Homebrew"
    export PATH="${HOMEBREW_PREFIX}/bin:${HOMEBREW_PREFIX}/sbin:${PATH}"
    export MANPATH="${HOMEBREW_PREFIX}/share/man${MANPATH+:$MANPATH}:"
    export INFOPATH="${HOMEBREW_PREFIX}/share/info:${INFOPATH:-}"
    
    # Verify Homebrew is working
    if ! command_exists brew; then
        log_error "Homebrew 'brew' command not found after installation"
        log_debug "PATH: $PATH"
        log_debug "HOMEBREW_PREFIX: $HOMEBREW_PREFIX"
        return 1
    fi
    
    # Test basic Homebrew functionality
    log_debug "Testing Homebrew functionality..."
    brew --version >/dev/null 2>&1 || {
        log_error "Homebrew 'brew --version' failed"
        return 1
    }
    
    log_success "Homebrew environment configured"
}

# Update Homebrew
update_homebrew() {
    log_info "Updating Homebrew..."
    
    # Disable auto-update to speed up installation
    export HOMEBREW_NO_AUTO_UPDATE=1
    
    # Update with timeout
    timeout "${TIMEOUT_SECONDS}" brew update || {
        log_warning "Homebrew update failed or timed out - continuing anyway"
        return 0
    }
    
    log_success "Homebrew updated"
}

# Validate Homebrew installation
validate_homebrew() {
    log_info "Validating Homebrew installation..."
    
    # Check brew command works
    if ! brew --version >/dev/null 2>&1; then
        log_error "Homebrew validation failed - brew command not working"
        return 1
    fi
    
    # Check core functionality
    if ! brew --repository >/dev/null 2>&1; then
        log_error "Homebrew validation failed - repository access failed"
        return 1
    fi
    
    # Display installation info
    log_debug "Homebrew version: $(brew --version | head -1)"
    log_debug "Homebrew prefix: $(brew --prefix)"
    log_debug "Homebrew repository: $(brew --repository)"
    
    log_success "Homebrew installation validated"
}

# Export environment variables for GitHub Actions
export_github_env() {
    if [[ -n "${GITHUB_ENV:-}" ]]; then
        log_info "Exporting environment variables to GitHub Actions..."
        
        cat >> "$GITHUB_ENV" << EOF
HOMEBREW_PREFIX=${HOMEBREW_PREFIX}
HOMEBREW_CELLAR=${HOMEBREW_PREFIX}/Cellar
HOMEBREW_REPOSITORY=${HOMEBREW_PREFIX}/Homebrew
PATH=${HOMEBREW_PREFIX}/bin:${HOMEBREW_PREFIX}/sbin:${PATH}
MANPATH=${HOMEBREW_PREFIX}/share/man${MANPATH+:$MANPATH}:
INFOPATH=${HOMEBREW_PREFIX}/share/info:${INFOPATH:-}
HOMEBREW_NO_AUTO_UPDATE=1
EOF
        
        # Also add to PATH for immediate use
        echo "${HOMEBREW_PREFIX}/bin" >> "$GITHUB_PATH"
        echo "${HOMEBREW_PREFIX}/sbin" >> "$GITHUB_PATH"
        
        log_success "Environment variables exported to GitHub Actions"
    fi
}

# Main function
main() {
    log_info "Starting Homebrew setup for Linux..."
    
    # System checks
    check_linux
    
    # Check if Homebrew is already installed
    if command_exists brew && brew --version >/dev/null 2>&1; then
        log_success "Homebrew is already installed"
        configure_homebrew
        export_github_env
        validate_homebrew
        return 0
    fi
    
    # Install system dependencies
    install_system_dependencies
    
    # Install Homebrew
    install_homebrew
    
    # Configure environment
    configure_homebrew
    
    # Update Homebrew
    update_homebrew
    
    # Export for GitHub Actions
    export_github_env
    
    # Final validation
    validate_homebrew
    
    log_success "Homebrew setup completed successfully!"
}

# Handle script arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=1
            shift
            ;;
        --timeout)
            TIMEOUT_SECONDS="$2"
            shift 2
            ;;
        --prefix)
            HOMEBREW_PREFIX="$2"
            shift 2
            ;;
        --help|-h)
            cat << EOF
Usage: $0 [OPTIONS]

Options:
    --verbose, -v       Enable verbose output
    --timeout SECONDS   Set timeout for operations (default: 600)
    --prefix PATH       Set Homebrew prefix (default: /home/linuxbrew/.linuxbrew)
    --help, -h          Show this help message

Environment Variables:
    HOMEBREW_PREFIX     Homebrew installation prefix
    TIMEOUT_SECONDS     Timeout for operations
    VERBOSE             Enable verbose output (0/1)
    GITHUB_ENV          GitHub Actions environment file
    GITHUB_PATH         GitHub Actions PATH file
EOF
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main function
main "$@"