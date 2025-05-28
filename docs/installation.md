# Installation Guide

This guide will walk you through creating a customized Ubuntu ISO with automated post-installation tools.

## Prerequisites

Before starting, ensure you have:

- Ubuntu 20.04 or later (host system)
- At least 8GB of available disk space
- sudo privileges
- Internet connection for downloading packages
- Original Ubuntu ISO file

## Installation Steps

### 1. Prepare Your Environment

First, clone or download this project:

```bash
git clone https://github.com/Slimison/ubuntu-iso-customizer.git
cd ubuntu-iso-customizer
```

**⚠️ Important: Fix permissions after cloning**

If you encounter permission issues (especially if the project was previously built with root), run:

```bash
# Fix any ownership/permission issues
./fix-permissions.sh

# Then run the setup script
./setup.sh
```

Alternative manual permission fix:
```bash
# If fix-permissions.sh doesn't work
sudo chown -R $USER:$USER ubuntu-iso-customizer/
chmod +x scripts/*.sh
chmod +x *.sh
```

### 2. Install Required Dependencies

The ISO builder script will automatically install required dependencies, but you can install them manually:

```bash
sudo apt update
sudo apt install -y xorriso squashfs-tools genisoimage isolinux syslinux-utils
```

### 3. Download Ubuntu ISO

Download the official Ubuntu ISO from [ubuntu.com](https://ubuntu.com/download/desktop):

```bash
# Example for Ubuntu 22.04 LTS
wget https://releases.ubuntu.com/22.04/ubuntu-22.04.3-desktop-amd64.iso
```

### 4. Customize Your Installation (Optional)

Before building the ISO, you can customize the installation:

#### Package Lists
Edit package lists in `configs/package-lists/`:
- `development.list` - Development tools and programming languages
- `multimedia.list` - Media applications and productivity tools

#### Post-Installation Script
Modify `scripts/post-install.sh` to add or remove installation steps.

#### Configuration Files
Update dotfiles in `configs/dotfiles/` to customize the user environment.

### 5. Build Custom ISO

Run the ISO builder script with your Ubuntu ISO:

```bash
sudo ./scripts/iso-builder.sh /path/to/ubuntu-22.04.3-desktop-amd64.iso
```

Optional parameters:
```bash
# Specify custom output location
sudo ./scripts/iso-builder.sh -o /tmp/my-custom-ubuntu.iso ubuntu.iso

# Use custom workspace
sudo ./scripts/iso-builder.sh -w /tmp/iso-workspace ubuntu.iso

# Clean workspace before building
sudo ./scripts/iso-builder.sh --clean ubuntu.iso
```

### 6. Create Bootable Media

Once the custom ISO is created, write it to a USB drive or burn to DVD:

#### Using dd (Linux)
```bash
sudo dd if=ubuntu-custom-20250527.iso of=/dev/sdX bs=4M status=progress
sync
```

#### Using Balena Etcher (Cross-platform)
1. Download [Balena Etcher](https://www.balena.io/etcher/)
2. Select your custom ISO
3. Select your USB drive
4. Flash the image

### 7. Install Ubuntu

1. Boot from your custom USB/DVD
2. **Select "Automated Install Ubuntu (Custom)"** for fully automated installation with autorun
3. Or select "Try or Install Ubuntu" for normal installation with autorun
4. The installation will proceed automatically using the preseed configuration
5. After installation and reboot, the post-installation script will run automatically
6. Check service status: `systemctl status custom-post-install.service`

## Post-Installation Features

Your custom Ubuntu installation will include:

### Development Tools
- Build essentials (gcc, make, cmake)
- Version control (Git with LFS)
- Text editors (Vim, Nano, VS Code)
- Programming languages (Python 3, Node.js)
- Package managers (npm, pip, yarn)

### Containerization
- Docker CE with Docker Compose
- Configured for non-root usage

### Security
- UFW firewall configured
- SSH server hardened
- Fail2ban installed

### System Utilities
- System monitoring tools (htop, tree, jq)
- Network utilities (curl, wget, net-tools)
- File management tools

### User Environment
- Development directories created
- Bash aliases and functions
- Git configuration template
- Custom prompt and colors

## Troubleshooting

### Common Issues

**Permission denied errors or read-only files:**
```bash
# Run the permission fix script
./fix-permissions.sh

# Or manually fix ownership
sudo chown -R $USER:$USER .
```

**ISO build fails with permissions error:**
```bash
# Ensure you're running with sudo
sudo ./scripts/iso-builder.sh ubuntu.iso
```

**Missing dependencies:**
```bash
# Install manually if auto-installation fails
sudo apt install xorriso squashfs-tools genisoimage isolinux syslinux-utils
```

**Post-installation script doesn't run:**
- Check if the systemd service is enabled: `systemctl status custom-post-install.service`
- Run manually: `sudo /usr/local/bin/custom-setup/post-install.sh`

**Permission issues with iso-workspace:**
- The iso-workspace directory must be owned by the user, not root
- Run: `sudo chown -R $USER:$USER ubuntu-iso-customizer/`
- Ensure all files are writable: `find iso-workspace/ -type f -exec chmod 644 {} \;`

**ISO build fails with read-only file errors:**
- Fix ownership: `sudo chown -R $USER:$USER ubuntu-iso-customizer/`
- Make files writable: `chmod 644 iso-workspace/custom/boot/grub/grub.cfg`

**Custom packages not installing:**
- Check internet connection during installation
- Verify package names in configuration files
- Check logs: `/var/log/post-install-*.log`

### Getting Help

1. Check the log files created during installation
2. Verify system requirements are met
3. Ensure all dependencies are installed
4. Try building with a clean workspace: `--clean` flag

## Next Steps

After successful installation, see:
- [Customization Guide](customization.md) - Learn how to modify the scripts
- [Tool Reference](tools.md) - Detailed information about installed tools

## Security Considerations

- The post-installation script runs with root privileges
- Review all scripts before building your ISO
- Only use trusted package sources
- Keep your custom ISO updated with security patches
