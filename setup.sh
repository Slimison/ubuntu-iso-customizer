#!/bin/bash
set -euo pipefail

# Ubuntu ISO Customizer Setup Script
# Installs dependencies and prepares the environment

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$SCRIPT_DIR"
readonly LOG_FILE="/tmp/ubuntu-customizer-setup.log"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log "INFO: $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log "SUCCESS: $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log "WARNING: $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log "ERROR: $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root"
        exit 1
    fi
}

# Check Ubuntu version
check_ubuntu_version() {
    if [ ! -f /etc/os-release ]; then
        print_error "Cannot determine OS version"
        exit 1
    fi
    
    . /etc/os-release
    
    if [[ "$ID" != "ubuntu" ]]; then
        print_warning "This script is designed for Ubuntu, detected: $ID"
    fi
    
    print_status "Detected Ubuntu $VERSION_ID"
}

# Update package lists
update_packages() {
    print_status "Updating package lists..."
    
    if sudo apt update; then
        print_success "Package lists updated"
    else
        print_error "Failed to update package lists"
        exit 1
    fi
}

# Install required packages
install_dependencies() {
    print_status "Installing required dependencies..."
    
    local packages=(
        xorriso
        squashfs-tools
        genisoimage
        rsync
        curl
        wget
        git
        build-essential
    )
    
    local missing=()
    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            missing+=("$package")
        fi
    done
    
    if [ ${#missing[@]} -eq 0 ]; then
        print_success "All dependencies already installed"
        return 0
    fi
    
    print_status "Installing missing packages: ${missing[*]}"
    
    if sudo apt install -y "${missing[@]}"; then
        print_success "Dependencies installed successfully"
    else
        print_error "Failed to install dependencies"
        exit 1
    fi
}

# Set up workspace
setup_workspace() {
    print_status "Setting up workspace..."
    
    # Fix ownership of the entire project directory first
    print_status "Ensuring correct file ownership..."
    current_user=$(whoami)
    
    # Check if any files are owned by root and fix them
    if find "$PROJECT_ROOT" -user root -print -quit | grep -q .; then
        print_warning "Found root-owned files, attempting to fix ownership..."
        if sudo chown -R "$current_user:$current_user" "$PROJECT_ROOT"; then
            print_success "Fixed file ownership to $current_user:$current_user"
        else
            print_error "Failed to fix file ownership. You may need to run: sudo chown -R \$USER:\$USER $(basename "$PROJECT_ROOT")"
        fi
    else
        print_success "All files are correctly owned by $current_user"
    fi
    
    # Remove iso-workspace if it exists and is owned by root
    if [ -d "$PROJECT_ROOT/iso-workspace" ]; then
        if [ "$(stat -c '%U' "$PROJECT_ROOT/iso-workspace" 2>/dev/null)" = "root" ]; then
            print_warning "Removing root-owned iso-workspace directory..."
            sudo rm -rf "$PROJECT_ROOT/iso-workspace"
            print_success "Removed root-owned iso-workspace"
        fi
    fi
    
    # Create necessary directories
    local dirs=(
        "$HOME/.local/share/ubuntu-customizer"
        "$HOME/.cache/ubuntu-customizer"
        "$HOME/.config/ubuntu-customizer"
    )
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_status "Created directory: $dir"
        fi
    done
    
    # Make all scripts executable
    find "$PROJECT_ROOT/scripts" -name "*.sh" -exec chmod +x {} \;
    print_success "Made all scripts executable"
    
    # Copy example config if it doesn't exist
    if [ ! -f "$PROJECT_ROOT/configs/config.env" ] && [ -f "$PROJECT_ROOT/configs/config.env.example" ]; then
        cp "$PROJECT_ROOT/configs/config.env.example" "$PROJECT_ROOT/configs/config.env"
        print_status "Created config.env from example"
    fi
    
    print_success "Workspace setup complete"
}

# Verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    local commands=(xorriso mksquashfs genisoimage rsync)
    local missing=()
    
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -eq 0 ]; then
        print_success "All required commands are available"
    else
        print_error "Missing commands: ${missing[*]}"
        exit 1
    fi
}

# Run test suite
run_tests() {
    print_status "Running test suite..."
    
    if [ -f "$PROJECT_ROOT/scripts/test-suite.sh" ]; then
        if "$PROJECT_ROOT/scripts/test-suite.sh"; then
            print_success "All tests passed"
        else
            print_warning "Some tests failed, but setup is complete"
        fi
    else
        print_warning "Test suite not found"
    fi
}

# Show next steps
show_next_steps() {
    cat << EOF

${GREEN}Setup Complete!${NC}

Next steps:
1. Edit the configuration file:
   ${BLUE}$PROJECT_ROOT/configs/config.env${NC}

2. Download an Ubuntu ISO file and note its path

3. Run the ISO builder:
   ${BLUE}$PROJECT_ROOT/scripts/iso-builder.sh /path/to/ubuntu.iso /path/to/output.iso${NC}

4. Test your custom ISO in a virtual machine

Documentation:
- Installation guide: ${BLUE}$PROJECT_ROOT/docs/installation.md${NC}
- Customization guide: ${BLUE}$PROJECT_ROOT/docs/customization.md${NC}
- Tools reference: ${BLUE}$PROJECT_ROOT/docs/tools.md${NC}

For help with any script, run it with --help option.

EOF
}

# Main function
main() {
    echo "Ubuntu ISO Customizer Setup"
    echo "============================"
    echo
    
    log "Starting setup process"
    
    check_root
    check_ubuntu_version
    update_packages
    install_dependencies
    setup_workspace
    verify_installation
    
    if [[ "${RUN_TESTS:-true}" == "true" ]]; then
        run_tests
    fi
    
    show_next_steps
    
    log "Setup completed successfully"
}

# Help function
show_help() {
    cat << EOF
Ubuntu ISO Customizer Setup Script

This script installs all required dependencies and sets up the workspace
for building custom Ubuntu ISO files.

Usage: $0 [OPTIONS]

Options:
    --help          Show this help message
    --no-tests      Skip running the test suite
    --verbose       Enable verbose output

Requirements:
    - Ubuntu 18.04 or later
    - Internet connection
    - sudo privileges

What this script does:
    1. Checks system requirements
    2. Updates package lists
    3. Installs required tools (xorriso, squashfs-tools, etc.)
    4. Sets up workspace directories
    5. Makes scripts executable
    6. Creates configuration files
    7. Runs test suite (optional)

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            show_help
            exit 0
            ;;
        --no-tests)
            RUN_TESTS=false
            shift
            ;;
        --verbose)
            set -x
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

main "$@"
