#!/usr/bin/env bash
#=======================================
# Ubuntu ISO Builder Script
# Creates a customized Ubuntu ISO with post-installation scripts
#=======================================

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ISO_WORKSPACE="$PROJECT_ROOT/iso-workspace"
ORIGINAL_ISO=""
OUTPUT_ISO="$PROJECT_ROOT/ubuntu-custom-$(date +%Y%m%d).iso"
MOUNT_POINT="/tmp/ubuntu-iso-mount"
EXTRACT_DIR="$ISO_WORKSPACE/extracted"
CUSTOM_DIR="$ISO_WORKSPACE/custom"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check dependencies
check_dependencies() {
    log "Checking dependencies..."
    
    local dependencies=("xorriso" "squashfs-tools" "genisoimage" "isolinux" "syslinux-utils")
    local missing_deps=()
    
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null && ! dpkg -s "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_warning "Installing missing dependencies: ${missing_deps[*]}"
        apt update
        apt install -y "${missing_deps[@]}"
    fi
    
    log_success "Dependencies checked"
}

# Check if running with sudo
check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run with sudo privileges"
        exit 1
    fi
}

# Clean up function
cleanup() {
    log "Cleaning up temporary files..."
    
    # Unmount if mounted
    if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        umount "$MOUNT_POINT" 2>/dev/null
    fi
    
    # Remove temporary directories
    rm -rf "$MOUNT_POINT" 2>/dev/null
    
    log "Cleanup completed"
}

# Set up signal handlers
trap cleanup EXIT INT TERM

# Extract original ISO
extract_iso() {
    local iso_path="$1"
    
    log "Extracting original ISO: $iso_path"
    
    # Create directories
    mkdir -p "$MOUNT_POINT" "$EXTRACT_DIR" "$CUSTOM_DIR"
    
    # Mount ISO
    mount -o loop "$iso_path" "$MOUNT_POINT"
    if [[ $? -ne 0 ]]; then
        log_error "Failed to mount ISO"
        return 1
    fi
    
    # Copy contents
    log "Copying ISO contents..."
    rsync -av "$MOUNT_POINT/" "$EXTRACT_DIR/"
    
    # Unmount
    umount "$MOUNT_POINT"
    
    log_success "ISO extracted successfully"
}

# Prepare custom content
prepare_custom_content() {
    log "Preparing custom content..."
    
    # Copy extracted content to custom directory
    rsync -av "$EXTRACT_DIR/" "$CUSTOM_DIR/"
    
    # Create custom scripts directory
    mkdir -p "$CUSTOM_DIR/custom-scripts"
    
    # Copy post-installation script
    cp "$SCRIPT_DIR/post-install.sh" "$CUSTOM_DIR/custom-scripts/"
    cp -r "$PROJECT_ROOT/configs" "$CUSTOM_DIR/custom-scripts/"
    cp -r "$SCRIPT_DIR/tools" "$CUSTOM_DIR/custom-scripts/" 2>/dev/null || true
    
    # Make scripts executable
    chmod +x "$CUSTOM_DIR/custom-scripts"/*.sh
    
    log_success "Custom content prepared"
}

# Modify the ISO to include our scripts
modify_iso() {
    log "Modifying ISO configuration..."
    
    # Create autorun script
    cat > "$CUSTOM_DIR/custom-scripts/autorun.sh" << 'EOF'
#!/bin/bash
# Autorun script for post-installation setup

# Wait for system to be ready
sleep 10

# Check if running in live environment
if grep -q "boot=casper" /proc/cmdline; then
    # We're in live mode, set up for post-installation
    
    # Copy scripts to a persistent location
    mkdir -p /usr/local/bin/custom-setup
    cp -r /cdrom/custom-scripts/* /usr/local/bin/custom-setup/
    
    # Create systemd service for post-installation
    cat > /etc/systemd/system/custom-post-install.service << 'EOL'
[Unit]
Description=Custom Post-Installation Setup
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/custom-setup/post-install.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOL
    
    # Enable the service (it will run after installation)
    systemctl enable custom-post-install.service
    
    # Create desktop shortcut for manual execution
    cat > /home/ubuntu/Desktop/run-post-install.desktop << 'EOL'
[Desktop Entry]
Version=1.0
Type=Application
Name=Run Post-Installation Setup
Comment=Execute custom post-installation script
Exec=sudo /usr/local/bin/custom-setup/post-install.sh
Icon=applications-system
Terminal=true
Categories=System;
EOL
    
    chmod +x /home/ubuntu/Desktop/run-post-install.desktop
fi
EOF
    
    chmod +x "$CUSTOM_DIR/custom-scripts/autorun.sh"
    
    # Modify casper scripts to run our autorun (optional - for live session customization)
    # Note: This modifies the live session, not the installed system
    # if [[ -f "$CUSTOM_DIR/casper/initrd" ]]; then
    #     log "Modifying casper initrd..."
    #     
    #     # Extract initrd
    #     mkdir -p "$ISO_WORKSPACE/initrd-extract"
    #     cd "$ISO_WORKSPACE/initrd-extract"
    #     gunzip -c "$CUSTOM_DIR/casper/initrd" | cpio -id
    #     
    #     # Add our script to casper
    #     mkdir -p scripts/casper-bottom
    #     cat > scripts/casper-bottom/99custom << 'EOF'
#!/bin/sh
# Custom script integration

PREREQ=""
prereqs()
{
    echo "$PREREQ"
}

case $1 in
prereqs)
    prereqs
    exit 0
    ;;
esac

# Copy custom scripts to the live system
if [ -d /cdrom/custom-scripts ]; then
    mkdir -p /root/custom-scripts
    cp -r /cdrom/custom-scripts/* /root/custom-scripts/
    chmod +x /root/custom-scripts/*.sh
fi
EOF
    #     
    #     chmod +x scripts/casper-bottom/99custom
    #     
    #     # Repack initrd
    #     find . | cpio -o -H newc | gzip > "$CUSTOM_DIR/casper/initrd"
    #     cd "$PROJECT_ROOT"
    #     rm -rf "$ISO_WORKSPACE/initrd-extract"
    # fi
    
    log "Skipping initrd modification (not needed for post-install customization)"
    
    # Add autostart to the live session
    mkdir -p "$CUSTOM_DIR/etc/skel/.config/autostart"
    cat > "$CUSTOM_DIR/etc/skel/.config/autostart/custom-setup.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Custom Setup
Exec=/cdrom/custom-scripts/autorun.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
    
    log_success "ISO modification completed"
}

# Update filesystem size
update_filesystem_size() {
    log "Updating filesystem size..."
    
    # Calculate new filesystem size
    local new_size=$(du -s "$CUSTOM_DIR" | cut -f1)
    echo "$new_size" > "$CUSTOM_DIR/casper/filesystem.size"
    
    log_success "Filesystem size updated"
}

# Generate MD5 checksums
generate_checksums() {
    log "Generating MD5 checksums..."
    
    cd "$CUSTOM_DIR"
    find . -type f -print0 | xargs -0 md5sum | grep -v isolinux/boot.cat > md5sum.txt
    cd "$PROJECT_ROOT"
    
    log_success "Checksums generated"
}

# Create the new ISO
create_iso() {
    log "Creating new ISO: $OUTPUT_ISO"
    
    cd "$CUSTOM_DIR"
    
    # Create ISO using xorriso with proper Ubuntu 22.04 boot configuration
    xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "Ubuntu 22.04.4 LTS amd64" \
        -output "$OUTPUT_ISO" \
        -eltorito-boot boot/grub/i386-pc/eltorito.img \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        --eltorito-catalog boot/grub/i386-pc/boot.cat \
        -eltorito-alt-boot \
        -e EFI/boot/bootx64.efi \
        -no-emul-boot \
        -append_partition 2 0xef EFI/boot/bootx64.efi \
        -partition_offset 16 \
        .
    
    cd "$PROJECT_ROOT"
    
    if [[ -f "$OUTPUT_ISO" ]]; then
        log_success "ISO created successfully: $OUTPUT_ISO"
        log "ISO size: $(du -h "$OUTPUT_ISO" | cut -f1)"
    else
        log_error "Failed to create ISO"
        return 1
    fi
}

# Display help
show_help() {
    echo "Ubuntu ISO Builder Script"
    echo "Usage: sudo $0 [options] <original_iso_path>"
    echo ""
    echo "Arguments:"
    echo "  original_iso_path    Path to the original Ubuntu ISO file"
    echo ""
    echo "Options:"
    echo "  --output, -o FILE    Specify output ISO file path"
    echo "  --workspace, -w DIR  Specify workspace directory"
    echo "  --help, -h          Show this help message"
    echo "  --clean             Clean workspace before building"
    echo ""
    echo "Example:"
    echo "  sudo $0 /path/to/ubuntu-20.04.3-desktop-amd64.iso"
    echo "  sudo $0 -o /tmp/my-custom.iso ubuntu.iso"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --output|-o)
            OUTPUT_ISO="$2"
            shift 2
            ;;
        --workspace|-w)
            ISO_WORKSPACE="$2"
            shift 2
            ;;
        --clean)
            rm -rf "$ISO_WORKSPACE"
            log "Workspace cleaned"
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            if [[ -z "$ORIGINAL_ISO" ]]; then
                ORIGINAL_ISO="$1"
            else
                log_error "Multiple ISO files specified"
                exit 1
            fi
            shift
            ;;
    esac
done

# Main execution
main() {
    log "Starting Ubuntu ISO customization..."
    
    # Validate arguments
    if [[ -z "$ORIGINAL_ISO" ]]; then
        log_error "No original ISO specified"
        show_help
        exit 1
    fi
    
    if [[ ! -f "$ORIGINAL_ISO" ]]; then
        log_error "Original ISO file not found: $ORIGINAL_ISO"
        exit 1
    fi
    
    # Check prerequisites
    check_sudo
    check_dependencies
    
    # Create workspace
    mkdir -p "$ISO_WORKSPACE"
    
    # Build process
    extract_iso "$ORIGINAL_ISO" || exit 1
    prepare_custom_content || exit 1
    modify_iso || exit 1
    update_filesystem_size || exit 1
    generate_checksums || exit 1
    create_iso || exit 1
    
    log_success "ISO customization completed!"
    log "Custom ISO: $OUTPUT_ISO"
    log "You can now burn this ISO to a USB/DVD and install Ubuntu with custom tools"
}

# Run main function
main "$@"
