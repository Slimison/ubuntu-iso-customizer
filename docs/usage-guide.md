# Ubuntu ISO Customizer - Usage Guide

## Overview

This guide covers how to use the Ubuntu ISO Customizer to create, test, and deploy custom Ubuntu installations with pre-configured development tools.

## Current Status ✅

The project is **fully functional** with:
- Custom ISO built: `ubuntu-custom-20250527.iso` (4.7GB)
- All core scripts working and tested
- GRUB/EFI boot configuration for Ubuntu 22.04
- Comprehensive test suite
- VM testing capabilities

## Step-by-Step Usage

### 1. Quick Validation

First, verify everything is working:

```bash
cd ubuntu-iso-customizer
./quick-test.sh
```

**Expected output:**
```
=== Quick Test Suite ===
✅ Found directory: scripts
✅ Found directory: configs  
✅ Found directory: docs
✅ Syntax OK: scripts/iso-builder.sh
✅ Syntax OK: scripts/post-install.sh
✅ Syntax OK: scripts/test-suite.sh
✅ Found dependency: xorriso
✅ Found dependency: mksquashfs
✅ Found dependency: genisoimage
✅ Found dependency: rsync
✅ Config file exists
✅ Config file loads successfully
✅ Custom ISO exists
🎉 All tests passed!
```

### 2. Test the Custom ISO

#### Option A: Boot Test Only (Quick)
```bash
# Test if the ISO boots properly
./scripts/test-iso-vm.sh --boot-only
```

#### Option B: Full Installation Test
```bash  
# Test complete installation process
./scripts/test-iso-vm.sh
```

**VM Controls:**
- `Ctrl+Alt+G`: Release mouse from VM
- `Ctrl+Alt+F`: Toggle fullscreen
- `Ctrl+Alt+Q`: Quit QEMU

### 3. Customize the Post-Install Script

#### Test Changes in Dry Run Mode
```bash
# Preview what the post-install script will do
./scripts/post-install.sh --dry-run
```

#### Edit Configuration
```bash
# Main configuration
nano configs/config.env

# Package lists
nano configs/package-lists/development.list
nano configs/package-lists/multimedia.list

# Test your changes
./scripts/post-install.sh --dry-run
```

### 4. Build a New Custom ISO

When you've made changes and want to create a new ISO:

```bash
# Build new ISO (requires sudo for file system access)
sudo ./scripts/iso-builder.sh /path/to/ubuntu-22.04.4-desktop-amd64.iso
```

**The build process:**
1. Extracts the original Ubuntu ISO
2. Copies custom scripts into the filesystem
3. Modifies boot configuration
4. Creates new bootable ISO

### 5. Deploy the Custom ISO

#### Physical Installation
1. Write ISO to USB drive:
   ```bash
   sudo dd if=ubuntu-custom-20250527.iso of=/dev/sdX bs=4M status=progress
   ```
   ⚠️ **Replace `/dev/sdX` with your actual USB device**

2. Boot from USB and install Ubuntu normally
3. Post-install script runs automatically after first boot

#### Virtual Machine Deployment
```bash
# Create VM with custom ISO
./scripts/test-iso-vm.sh --memory 4G --cpus 2
```

## Configuration Options

### Main Configuration (`configs/config.env`)

```bash
# ISO Settings
SOURCE_ISO_PATH="/path/to/ubuntu-22.04.4-desktop-amd64.iso"
ISO_LABEL="Custom Ubuntu Dev"

# Features
INSTALL_DEVELOPMENT_TOOLS=true
INSTALL_MULTIMEDIA_TOOLS=false
CONFIGURE_FIREWALL=true
CONFIGURE_SSH=true

# User Settings  
DEFAULT_USERNAME="developer"
SETUP_GIT_CONFIG=true
INSTALL_DOTFILES=true
```

### Package Lists

Edit package lists to customize what gets installed:

```bash
# Development tools
configs/package-lists/development.list

# Multimedia tools
configs/package-lists/multimedia.list
```

## Available VS Code Tasks

Use VS Code's Command Palette (`Ctrl+Shift+P`) → "Tasks: Run Task":

1. **Quick Test Suite** - Fast validation of project status
2. **Test ISO in VM (Boot Only)** - Quick boot test
3. **Test ISO in VM (Full Install)** - Complete installation test
4. **Build Custom Ubuntu ISO** - Create new custom ISO
5. **Run Post-Install Script (Dry Run)** - Preview changes
6. **Make Scripts Executable** - Fix permissions

## Troubleshooting

### Common Issues

1. **Permission Errors**
   ```bash
   # Fix script permissions
   find scripts -name '*.sh' -exec chmod +x {} \;
   ```

2. **Missing Dependencies**
   ```bash
   # Install required tools
   sudo apt update
   sudo apt install xorriso squashfs-tools genisoimage rsync qemu-system-x86
   ```

3. **ISO Build Fails**
   ```bash
   # Check source ISO path in config
   nano configs/config.env
   
   # Verify source ISO exists
   ls -la /path/to/ubuntu-22.04.4-desktop-amd64.iso
   ```

4. **VM Won't Start**
   ```bash
   # Try without KVM acceleration
   ./scripts/test-iso-vm.sh --no-kvm --boot-only
   ```

### Logs and Debugging

- Test logs: `/tmp/ubuntu-customizer-test.log`
- Post-install logs: `/var/log/post-install.log` (in target system)
- ISO build logs: Check terminal output during build

## Advanced Usage

### Custom Tool Installation

Add your own tools by creating scripts in `scripts/tools/`:

```bash
#!/bin/bash
# scripts/tools/install-my-tool.sh

install_my_tool() {
    log "Installing My Custom Tool..."
    
    # Add your installation logic here
    apt update && apt install -y my-tool
    
    log "✓ My Custom Tool installed"
}
```

Then call it from `scripts/post-install.sh`:

```bash
# Add to the main installation function
install_my_tool
```

### Custom Dotfiles

Place configuration files in `configs/dotfiles/` and they'll be copied to the user's home directory.

### System Services

Add systemd services in `configs/` and reference them in the post-install script.

## Next Steps

1. **Test your custom ISO** in a VM before physical deployment
2. **Customize package lists** for your specific needs  
3. **Add custom tools** using the modular script system
4. **Document your customizations** for team deployment
5. **Set up automated building** with CI/CD if needed

## Support

For issues or questions:
1. Run the quick test suite to identify problems
2. Check logs for detailed error information
3. Verify all dependencies are installed
4. Test in VM before physical deployment
