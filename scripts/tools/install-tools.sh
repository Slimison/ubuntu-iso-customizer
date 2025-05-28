#!/usr/bin/env bash
#=======================================
# Individual Tool Installation Scripts
#=======================================

# Docker installation script
install_docker() {
    echo "Installing Docker..."
    
    # Remove old versions
    apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null
    
    # Install prerequisites
    apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    echo "Docker installed successfully"
}

# Node.js installation script
install_nodejs() {
    echo "Installing Node.js..."
    
    # Install NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
    
    # Install Node.js
    apt install -y nodejs
    
    # Install global packages
    npm install -g yarn typescript @angular/cli create-react-app vue-cli @vue/cli
    
    echo "Node.js and global packages installed successfully"
}

# Python tools installation script
install_python_tools() {
    echo "Installing Python development tools..."
    
    # Install Python and pip
    apt install -y python3 python3-pip python3-venv python3-dev
    
    # Upgrade pip
    pip3 install --upgrade pip setuptools wheel
    
    # Install common packages
    pip3 install virtualenv pipenv jupyter notebook pandas numpy matplotlib requests flask django fastapi
    
    echo "Python development tools installed successfully"
}

# Visual Studio Code installation script
install_vscode() {
    echo "Installing Visual Studio Code..."
    
    # Add Microsoft GPG key and repository
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
    
    # Install VS Code
    apt update
    apt install -y code
    
    echo "Visual Studio Code installed successfully"
}

# Git configuration script
configure_git() {
    echo "Configuring Git..."
    
    # Install Git
    apt install -y git git-lfs
    
    # Set up Git LFS
    git lfs install --system
    
    echo "Git configured successfully"
}

# Firewall configuration script
configure_firewall() {
    echo "Configuring UFW firewall..."
    
    # Install and configure UFW
    apt install -y ufw
    
    # Set default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH
    ufw allow ssh
    
    # Allow common development ports
    ufw allow 3000  # React/Node development
    ufw allow 8000  # Django development
    ufw allow 8080  # General development
    ufw allow 5000  # Flask development
    
    # Enable firewall
    ufw --force enable
    
    echo "Firewall configured successfully"
}

# Main function to install selected tools
main() {
    case "${1:-all}" in
        docker)
            install_docker
            ;;
        nodejs)
            install_nodejs
            ;;
        python)
            install_python_tools
            ;;
        vscode)
            install_vscode
            ;;
        git)
            configure_git
            ;;
        firewall)
            configure_firewall
            ;;
        all)
            install_docker
            install_nodejs
            install_python_tools
            install_vscode
            configure_git
            configure_firewall
            ;;
        *)
            echo "Usage: $0 [docker|nodejs|python|vscode|git|firewall|all]"
            exit 1
            ;;
    esac
}

# Run main function with arguments
main "$@"
