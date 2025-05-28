# Customization Guide

This guide explains how to customize the Ubuntu ISO builder to meet your specific needs.

## Project Structure Overview

```
ubuntu-iso-customizer/
├── scripts/
│   ├── post-install.sh          # Main post-installation script
│   ├── iso-builder.sh           # ISO customization script
│   └── tools/
│       └── install-tools.sh     # Individual tool installers
├── configs/
│   ├── package-lists/           # Software package definitions
│   ├── dotfiles/               # User configuration files
│   └── systemd/                # System service configurations
├── docs/                       # Documentation
└── iso-workspace/              # Working directory (created during build)
```

## Customizing Package Installation

### Adding New Packages

1. **Edit Package Lists**

Add packages to the appropriate list file in `configs/package-lists/`:

```bash
# For development tools
echo "neovim" >> configs/package-lists/development.list

# For multimedia applications
echo "kdenlive" >> configs/package-lists/multimedia.list
```

2. **Create Custom Package Lists**

Create a new `.list` file for specific categories:

```bash
# Create a gaming package list
cat > configs/package-lists/gaming.list << EOF
steam
lutris
wine
gamemode
mangohud
EOF
```

3. **Modify the Post-Installation Script**

Add your custom package list to the installation process:

```bash
# In scripts/post-install.sh, add to the main function:
install_custom_packages() {
    log "Installing custom packages..."
    
    if [[ -f "$CONFIG_DIR/package-lists/gaming.list" ]]; then
        while IFS= read -r package; do
            [[ $package =~ ^#.*$ ]] && continue  # Skip comments
            [[ -z "$package" ]] && continue      # Skip empty lines
            
            log "Installing $package..."
            apt install -y "$package" 2>&1 | tee -a "$LOG_FILE"
        done < "$CONFIG_DIR/package-lists/gaming.list"
    fi
}
```

## Adding Custom Scripts

### Creating Tool-Specific Installers

1. **Create Individual Installer Scripts**

```bash
# Create a new tool installer
cat > scripts/tools/install-flutter.sh << 'EOF'
#!/usr/bin/env bash

install_flutter() {
    log "Installing Flutter..."
    
    # Download Flutter
    cd /opt
    wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
    tar xf flutter_linux_3.16.0-stable.tar.xz
    
    # Add to PATH
    echo 'export PATH="$PATH:/opt/flutter/bin"' >> /etc/environment
    
    # Set permissions
    chown -R $SUDO_USER:$SUDO_USER /opt/flutter
    
    log_success "Flutter installed successfully"
}

install_flutter
EOF

chmod +x scripts/tools/install-flutter.sh
```

2. **Integrate into Main Script**

Add the new installer to `post-install.sh`:

```bash
# Add to the main function
source "$SCRIPT_DIR/tools/install-flutter.sh" || log_error "Flutter installation failed"
```

### Custom System Configurations

1. **Add Systemd Services**

Create custom services in `configs/systemd/`:

```bash
cat > configs/systemd/custom-backup.service << 'EOF'
[Unit]
Description=Custom Backup Service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup-script.sh
User=root

[Install]
WantedBy=multi-user.target
EOF
```

2. **Apply Service Configuration**

Add service installation to the post-install script:

```bash
configure_custom_services() {
    log "Configuring custom services..."
    
    # Copy service files
    if [[ -d "$CONFIG_DIR/systemd" ]]; then
        cp "$CONFIG_DIR/systemd"/*.service /etc/systemd/system/
        systemctl daemon-reload
        
        # Enable services
        systemctl enable custom-backup.service
    fi
}
```

## Customizing User Environment

### Modifying Dotfiles

1. **Update Bash Configuration**

Add custom aliases to `.bashrc_additions`:

```bash
cat >> configs/dotfiles/.bashrc_additions << 'EOF'

# Custom project aliases
alias projects='cd ~/Development'
alias scripts='cd ~/Scripts'

# Docker development shortcuts
alias ddev='docker run -it --rm -v $(pwd):/workspace -w /workspace'
alias dnode='docker run -it --rm -v $(pwd):/app -w /app node:lts bash'
alias dpython='docker run -it --rm -v $(pwd):/app -w /app python:3 bash'
EOF
```

2. **Add Vim Configuration**

```bash
cat > configs/dotfiles/.vimrc << 'EOF'
" Basic Vim configuration
set number
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent
set hlsearch
set incsearch
syntax on
colorscheme desert
EOF
```

3. **Apply Dotfiles in Post-Install**

Add dotfile installation to the post-install script:

```bash
setup_user_dotfiles() {
    log "Setting up user dotfiles..."
    
    if [[ -n "$SUDO_USER" ]]; then
        local user_home="/home/$SUDO_USER"
        
        # Copy dotfiles
        if [[ -d "$CONFIG_DIR/dotfiles" ]]; then
            cp "$CONFIG_DIR/dotfiles/.bashrc_additions" "$user_home/"
            cp "$CONFIG_DIR/dotfiles/.vimrc" "$user_home/"
            cp "$CONFIG_DIR/dotfiles/.gitconfig" "$user_home/"
            
            # Append bash additions to .bashrc
            echo "source ~/.bashrc_additions" >> "$user_home/.bashrc"
            
            # Set ownership
            chown "$SUDO_USER:$SUDO_USER" "$user_home/."*
        fi
    fi
}
```

## Advanced ISO Customization

### Modifying the Live Environment

1. **Add Files to Live Session**

Modify `iso-builder.sh` to include additional files:

```bash
# In prepare_custom_content function
prepare_live_environment() {
    log "Preparing live environment..."
    
    # Add custom wallpapers
    mkdir -p "$CUSTOM_DIR/usr/share/backgrounds/custom"
    cp assets/wallpapers/* "$CUSTOM_DIR/usr/share/backgrounds/custom/"
    
    # Add custom applications
    mkdir -p "$CUSTOM_DIR/usr/share/applications"
    cp configs/applications/*.desktop "$CUSTOM_DIR/usr/share/applications/"
}
```

2. **Modify Boot Menu**

Customize the GRUB menu:

```bash
# Edit isolinux configuration
cat > "$CUSTOM_DIR/isolinux/txt.cfg" << 'EOF'
default live
label live
  menu label ^Try or Install Ubuntu Custom
  kernel /casper/vmlinuz
  append initrd=/casper/initrd boot=casper quiet splash ---
EOF
```

### Pre-configuring Applications

1. **Firefox Bookmarks and Settings**

```bash
configure_firefox() {
    log "Configuring Firefox..."
    
    # Create Firefox profile directory
    local firefox_dir="$CUSTOM_DIR/etc/skel/.mozilla/firefox"
    mkdir -p "$firefox_dir"
    
    # Add bookmarks and preferences
    # (Implementation depends on Firefox profile structure)
}
```

2. **VS Code Extensions and Settings**

```bash
configure_vscode() {
    log "Configuring VS Code..."
    
    # Pre-install extensions
    local extensions=(
        "ms-python.python"
        "ms-vscode.vscode-typescript-next"
        "ms-vscode.vscode-json"
        "ms-azuretools.vscode-docker"
    )
    
    for ext in "${extensions[@]}"; do
        code --install-extension "$ext" --force
    done
}
```

## Testing Your Customizations

### Virtual Machine Testing

1. **Create VM Test Environment**

```bash
# Using VirtualBox CLI
VBoxManage createvm --name "Ubuntu-Test" --register
VBoxManage modifyvm "Ubuntu-Test" --memory 4096 --vram 128 --cpus 2
VBoxManage createhd --filename "Ubuntu-Test.vdi" --size 20480
VBoxManage storagectl "Ubuntu-Test" --name "SATA" --add sata
VBoxManage storageattach "Ubuntu-Test" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "Ubuntu-Test.vdi"
VBoxManage storageattach "Ubuntu-Test" --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium ubuntu-custom-20250527.iso
```

2. **Automated Testing Script**

```bash
cat > test-iso.sh << 'EOF'
#!/bin/bash
# Automated ISO testing script

echo "Starting VM for ISO testing..."
VBoxManage startvm "Ubuntu-Test" --type headless

# Wait for installation to complete
sleep 3600  # Adjust based on installation time

echo "Testing completed. Check VM for results."
EOF
```

## Best Practices

### Security Considerations

1. **Minimize Attack Surface**
   - Only install necessary packages
   - Remove or disable unused services
   - Keep software updated

2. **Secure Defaults**
   - Use strong firewall rules
   - Configure SSH securely
   - Set appropriate file permissions

3. **User Permissions**
   - Avoid running services as root when possible
   - Use sudo for administrative tasks
   - Implement proper access controls

### Performance Optimization

1. **Reduce ISO Size**
   - Remove unnecessary language packs
   - Exclude unused drivers
   - Compress filesystem efficiently

2. **Fast Boot Times**
   - Disable unnecessary services
   - Optimize systemd targets
   - Use SSD-optimized settings

### Maintenance

1. **Version Control**
   - Track changes in Git
   - Tag stable releases
   - Document modifications

2. **Regular Updates**
   - Update base Ubuntu ISO
   - Refresh package lists
   - Test security patches

## Troubleshooting Common Issues

### Build Failures

1. **Insufficient Disk Space**
   ```bash
   # Check available space
   df -h
   
   # Clean up workspace
   ./scripts/iso-builder.sh --clean
   ```

2. **Permission Errors**
   ```bash
   # Ensure proper ownership
   sudo chown -R $USER:$USER iso-workspace/
   
   # Fix script permissions
   chmod +x scripts/*.sh
   ```

### Runtime Issues

1. **Package Installation Failures**
   - Check internet connectivity
   - Verify package repository availability
   - Review package names for typos

2. **Service Configuration Problems**
   - Check systemd service status
   - Review log files
   - Verify configuration file syntax

Remember to always test your customizations thoroughly before deploying to production systems.
