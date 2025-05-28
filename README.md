# Ubuntu ISO Customization Project

✅ **FULLY FUNCTIONAL** - Successfully builds custom Ubuntu ISOs with embedded post-installation scripts!

This project provides a complete system for creating customized Ubuntu ISOs that automatically install development tools and configure the system after installation. The project has been fully tested and is ready for production use.

## 🎉 Current Status

- ✅ **Custom ISO Built**: `ubuntu-custom-20250527.iso` (4.7GB) ready for deployment
- ✅ **All Scripts Working**: Post-install, ISO builder, and test suite all functional
- ✅ **Dependencies Installed**: All required tools (xorriso, squashfs-tools, etc.) available
- ✅ **Tests Passing**: Quick test suite validates all components
- ✅ **Boot Configuration Fixed**: Updated to GRUB/EFI for Ubuntu 22.04 compatibility

## Features

- **Post-installation script** that automatically runs after Ubuntu installation
- **Automated tool installation** for complete development environments
- **System configuration** with security and performance optimizations  
- **ISO customization tools** to integrate scripts into Ubuntu ISO
- **Modular design** for easy customization and extension
- **Virtual machine testing** with QEMU integration
- **Comprehensive test suite** for validation

## Project Structure

```
ubuntu-iso-customizer/
├── scripts/
│   ├── post-install.sh          # Main post-installation script ✅
│   ├── iso-builder.sh           # ISO customization script ✅  
│   ├── test-suite.sh           # Comprehensive test suite ✅
│   ├── test-iso-vm.sh          # VM testing script ✅
│   └── tools/                  # Individual tool installation scripts
├── configs/
│   ├── config.env              # Main configuration file ✅
│   ├── package-lists/          # Package installation lists ✅
│   ├── dotfiles/              # Configuration files
│   └── preseed.cfg            # Automated installation config
├── iso-workspace/             # Working directory for ISO modification ✅
├── docs/                      # Documentation
├── ubuntu-custom-20250527.iso # Built custom ISO ✅
└── README.md
```

## Quick Start

### 0. **Clone and Setup (New Installation)**
```bash
# Clone the repository
git clone https://github.com/Slimison/ubuntu-iso-customizer.git
cd ubuntu-iso-customizer

# Run setup script to install dependencies and fix permissions
./setup.sh

# This will:
# - Install required dependencies (xorriso, squashfs-tools, etc.)
# - Fix any root ownership issues from previous builds
# - Make all scripts executable
# - Create configuration files
```

### 1. **Test the Custom ISO (Recommended First Step)**
```bash
# Test boot in virtual machine
./scripts/test-iso-vm.sh --boot-only

# Full VM test with installation
./scripts/test-iso-vm.sh
```

### 2. **Build a New Custom ISO**
```bash
# Using the VS Code task (recommended)
# Run: "Build Custom Ubuntu ISO" task

# Or manually:
sudo ./scripts/iso-builder.sh /path/to/ubuntu-22.04.4-desktop-amd64.iso
```

### 3. **Customize the Installation**
- Edit `configs/package-lists/` to modify software packages
- Update `scripts/tools/` to add custom tool installations  
- Modify `configs/config.env` for system preferences
- Test changes with `./scripts/post-install.sh --dry-run`

### 4. **Run Tests**
```bash
# Quick validation
./quick-test.sh

# Full test suite  
./scripts/test-suite.sh
```

## Requirements

- Ubuntu 22.04 or later
- 8GB+ available disk space
- sudo privileges
- Internet connection for package downloads

## Documentation

See the `docs/` directory for detailed documentation:
- [Installation Guide](docs/installation.md)
- [Customization Guide](docs/customization.md)
- [Tool Reference](docs/tools.md)

## License

MIT License - see LICENSE file for details.
