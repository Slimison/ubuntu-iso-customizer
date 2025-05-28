#!/usr/bin/env bash
set -euo pipefail

#=======================================
# Ubuntu Post-Installation Script
# Automatically installs development tools and configures system
#=======================================

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../configs"
LOG_FILE="/var/log/post-install-$(date +%Y%m%d-%H%M%S).log"

# Runtime options
DRY_RUN=false
VERBOSE=false
SKIP_UPDATES=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo -e "${BLUE}${message}${NC}"
    if [[ "$DRY_RUN" == "false" ]]; then
        echo "$message" >> "$LOG_FILE"
    fi
}

log_success() {
    local message="[SUCCESS] $1"
    echo -e "${GREEN}${message}${NC}"
    if [[ "$DRY_RUN" == "false" ]]; then
        echo "$message" >> "$LOG_FILE"
    fi
}

log_warning() {
    local message="[WARNING] $1"
    echo -e "${YELLOW}${message}${NC}"
    if [[ "$DRY_RUN" == "false" ]]; then
        echo "$message" >> "$LOG_FILE"
    fi
}

log_error() {
    local message="[ERROR] $1"
    echo -e "${RED}${message}${NC}"
    if [[ "$DRY_RUN" == "false" ]]; then
        echo "$message" >> "$LOG_FILE"
    fi
}

# Execute command with dry-run support
execute() {
    local cmd="$1"
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY-RUN] Would execute: $cmd"
        return 0
    else
        if [[ "$VERBOSE" == "true" ]]; then
            log "Executing: $cmd"
        fi
        eval "$cmd"
    fi
}

# Check if running with sudo (unless dry-run)
check_sudo() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log "Dry-run mode: skipping sudo check"
        return 0
    fi
    
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run with sudo privileges"
        log_error "Usage: sudo $0 [options]"
        exit 1
    fi
}

# Update system packages
update_system() {
    log "Starting system update and upgrade..."
    
    # Update package lists
    if execute "apt update"; then
        log_success "Package lists updated"
    else
        log_error "Failed to update package lists"
        return 1
    fi
    
    # Upgrade packages
    if execute "DEBIAN_FRONTEND=noninteractive apt upgrade -y"; then
        log_success "System packages upgraded"
    else
        log_error "Failed to upgrade packages"
        return 1
    fi
    
    # Install essential packages
    local essential_packages=(
        curl
        wget
        git
        vim
        htop
        tree
        unzip
        software-properties-common
        apt-transport-https
        ca-certificates
        gnupg
        lsb-release
    )
    
    log "Installing essential packages..."
    if execute "DEBIAN_FRONTEND=noninteractive apt install -y ${essential_packages[*]}"; then
        log_success "Essential packages installed"
        else
        log_error "Failed to install essential packages"
        return 1
    fi
    
    log_success "System update completed"
}

# Install development tools
install_development_tools() {
    log "Installing development tools..."
    
    # Programming languages and tools
    local dev_packages=(
        "build-essential"
        "cmake"
        "git"
        "vim"
        "nano"
        "htop"
        "tree"
        "unzip"
        "zip"
        "jq"
        "curl"
        "wget"
        "net-tools"
        "openssh-server"
        "ufw"
        "fail2ban"
    )
    
    for package in "${dev_packages[@]}"; do
        log "Installing $package..."
        if execute "DEBIAN_FRONTEND=noninteractive apt install -y $package"; then
            log_success "$package installed successfully"
        else
            log_warning "Failed to install $package"
        fi
    done
}

# Install Node.js and npm
install_nodejs() {
    log "Installing Node.js and npm..."
    
    # Install NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - 2>&1 | tee -a "$LOG_FILE"
    apt install -y nodejs 2>&1 | tee -a "$LOG_FILE"
    
    # Verify installation
    if command -v node &> /dev/null && command -v npm &> /dev/null; then
        local node_version=$(node --version)
        local npm_version=$(npm --version)
        log_success "Node.js $node_version and npm $npm_version installed successfully"
        
        # Install global packages
        npm install -g yarn typescript @angular/cli create-react-app 2>&1 | tee -a "$LOG_FILE"
        log_success "Global npm packages installed"
    else
        log_error "Node.js installation failed"
    fi
}

# Install Python development tools
install_python_tools() {
    log "Installing Python development tools..."
    
    apt install -y python3 python3-pip python3-venv python3-dev 2>&1 | tee -a "$LOG_FILE"
    
    # Install common Python packages
    pip3 install --upgrade pip setuptools wheel 2>&1 | tee -a "$LOG_FILE"
    pip3 install virtualenv pipenv jupyter notebook pandas numpy matplotlib 2>&1 | tee -a "$LOG_FILE"
    
    log_success "Python development tools installed"
}

# Install Docker
install_docker() {
    log "Installing Docker..."
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg 2>&1 | tee -a "$LOG_FILE"
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    apt update 2>&1 | tee -a "$LOG_FILE"
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin 2>&1 | tee -a "$LOG_FILE"
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    # Add current user to docker group (if not root)
    if [[ -n "${SUDO_USER:-}" ]]; then
        usermod -aG docker "$SUDO_USER"
        log_success "User $SUDO_USER added to docker group"
    fi
    
    log_success "Docker installed successfully"
}

# Install Visual Studio Code
install_vscode() {
    log "Installing Visual Studio Code..."
    
    # Add Microsoft GPG key and repository
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
    
    # Install VS Code
    apt update 2>&1 | tee -a "$LOG_FILE"
    apt install -y code 2>&1 | tee -a "$LOG_FILE"
    
    log_success "Visual Studio Code installed"
}

# Configure firewall
configure_firewall() {
    log "Configuring UFW firewall..."
    
    # Enable UFW
    ufw --force enable 2>&1 | tee -a "$LOG_FILE"
    
    # Configure basic rules
    ufw default deny incoming 2>&1 | tee -a "$LOG_FILE"
    ufw default allow outgoing 2>&1 | tee -a "$LOG_FILE"
    ufw allow ssh 2>&1 | tee -a "$LOG_FILE"
    
    log_success "Firewall configured"
}

# Configure SSH
configure_ssh() {
    log "Configuring SSH server..."
    
    # Backup original config
    if [[ -f /etc/ssh/sshd_config ]]; then
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)
    fi
    
    # Basic SSH hardening
    sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    
    # Restart SSH service
    systemctl restart sshd
    
    log_success "SSH server configured"
}

# Install additional development tools
install_additional_tools() {
    log "Installing additional development tools..."
    
    # Install Snap packages
    snap install --classic code
    snap install --classic sublime-text
    snap install postman
    
    # Install Flatpak applications
    apt install -y flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    
    log_success "Additional tools installed"
}

# Clean up system
cleanup_system() {
    log "Cleaning up system..."
    
    apt autoremove -y 2>&1 | tee -a "$LOG_FILE"
    apt autoclean 2>&1 | tee -a "$LOG_FILE"
    
    log_success "System cleanup completed"
}

# Create user development directories
setup_user_environment() {
    log "Setting up user development environment..."
    
    if [[ -n "${SUDO_USER:-}" ]]; then
        local user_home="/home/$SUDO_USER"
        local dev_dirs=("$user_home/Development" "$user_home/Projects" "$user_home/Scripts")
        
        for dir in "${dev_dirs[@]}"; do
            if [[ ! -d "$dir" ]]; then
                mkdir -p "$dir"
                chown "$SUDO_USER:$SUDO_USER" "$dir"
                log "Created directory: $dir"
            fi
        done
        
        log_success "User development environment configured"
    fi
}

# Main execution function
run_installation() {
    log "Starting Ubuntu post-installation script..."
    log "Log file: $LOG_FILE"
    
    check_sudo
    
    # Execute installation steps
    update_system || log_error "System update failed"
    install_development_tools || log_error "Development tools installation failed"
    install_nodejs || log_error "Node.js installation failed"
    install_python_tools || log_error "Python tools installation failed"
    install_docker || log_error "Docker installation failed"
    install_vscode || log_error "VS Code installation failed"
    configure_firewall || log_error "Firewall configuration failed"
    configure_ssh || log_error "SSH configuration failed"
    install_additional_tools || log_error "Additional tools installation failed"
    setup_user_environment || log_error "User environment setup failed"
    cleanup_system || log_error "System cleanup failed"
    
    log_success "Post-installation script completed successfully!"
    log "Please reboot the system to ensure all changes take effect."
    log "Log file saved at: $LOG_FILE"
    
    # Ask user if they want to reboot
    if [[ -t 0 && "$DRY_RUN" == "false" ]]; then  # Check if running interactively and not dry-run
        read -p "Would you like to reboot now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "Rebooting system..."
            reboot
        fi
    fi
}

# Help function
show_help() {
    cat << EOF
Ubuntu Post-Installation Script

This script automatically installs development tools and configures
the system after a fresh Ubuntu installation.

Usage: $0 [OPTIONS]

Options:
    --help, -h         Show this help message
    --version          Show version information
    --dry-run          Show what would be done without executing
    --verbose          Enable verbose output
    --skip-updates     Skip system updates and upgrades
    --config FILE      Use custom configuration file

Features:
    - System updates and upgrades
    - Development tools installation (Node.js, Python, Docker, VS Code)
    - Security configuration (UFW firewall, SSH hardening)
    - User environment setup (Git config, bash aliases)
    - Additional productivity tools

Examples:
    sudo $0                          # Run with default settings
    sudo $0 --dry-run               # Preview what would be done
    sudo $0 --skip-updates          # Skip system updates
    $0 --help                       # Show this help

Log files are saved to /var/log/post-install-YYYYMMDD-HHMMSS.log

EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --version)
                echo "Ubuntu Post-Installation Script v1.0"
                exit 0
                ;;
            --dry-run)
                DRY_RUN=true
                log "Dry-run mode enabled"
                shift
                ;;
            --verbose)
                VERBOSE=true
                set -x
                shift
                ;;
            --skip-updates)
                SKIP_UPDATES=true
                shift
                ;;
            --config)
                CONFIG_FILE="$2"
                if [[ ! -f "$CONFIG_FILE" ]]; then
                    log_error "Configuration file not found: $CONFIG_FILE"
                    exit 1
                fi
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Load configuration file
load_config() {
    local config_files=(
        "${CONFIG_FILE:-}"
        "$CONFIG_DIR/config.env"
        "$SCRIPT_DIR/config.env"
    )
    
    for config in "${config_files[@]}"; do
        if [[ -n "$config" && -f "$config" ]]; then
            log "Loading configuration from: $config"
            # shellcheck source=/dev/null
            source "$config"
            return 0
        fi
    done
    
    log_warning "No configuration file found, using defaults"
}

# Main function
main() {
    echo "Ubuntu Post-Installation Script"
    echo "==============================="
    echo
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}DRY-RUN MODE: No changes will be made${NC}"
        echo
    fi
    
    parse_arguments "$@"
    load_config
    
    log "Starting post-installation setup..."
    
    if [[ "$SKIP_UPDATES" == "false" ]]; then
        update_system || log_error "System update failed"
    else
        log "Skipping system updates as requested"
    fi
    
    install_development_tools || log_error "Development tools installation failed"
    configure_firewall || log_error "Firewall configuration failed"
    configure_ssh || log_error "SSH configuration failed"
    install_additional_tools || log_error "Additional tools installation failed"
    setup_user_environment || log_error "User environment setup failed"
    cleanup_system || log_error "System cleanup failed"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_success "Dry-run completed successfully!"
        log "To actually run the installation, execute without --dry-run"
    else
        log_success "Post-installation script completed successfully!"
        log "Please reboot the system to ensure all changes take effect."
        log "Log file saved at: $LOG_FILE"
        
        # Ask user if they want to reboot
        if [[ -t 0 ]]; then  # Check if running interactively
            echo
            read -p "Would you like to reboot now? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log "Rebooting system..."
                reboot
            fi
        fi
    fi
}

# Run the script
main "$@"
