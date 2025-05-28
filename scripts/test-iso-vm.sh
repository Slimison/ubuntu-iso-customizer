#!/bin/bash
set -euo pipefail

# Test Custom ISO in Virtual Machine
# This script launches the custom Ubuntu ISO in QEMU for testing

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly ISO_PATH="$PROJECT_ROOT/ubuntu-custom-20250527.iso"
readonly VM_DISK="/tmp/ubuntu-test-vm.qcow2"
readonly VM_MEMORY="4G"
readonly VM_CPUS="2"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

show_help() {
    cat << EOF
Test Custom Ubuntu ISO in Virtual Machine

Usage: $0 [OPTIONS]

Options:
    --help          Show this help message
    --memory SIZE   Set VM memory (default: $VM_MEMORY)
    --cpus NUM      Set number of CPUs (default: $VM_CPUS)
    --disk PATH     Set VM disk path (default: $VM_DISK)
    --iso PATH      Set ISO path (default: $ISO_PATH)
    --vnc           Enable VNC instead of SDL display
    --no-kvm        Disable KVM acceleration
    --boot-only     Just test booting, don't install

Examples:
    $0                          # Test with default settings
    $0 --memory 2G --cpus 1     # Use less resources
    $0 --vnc                    # Use VNC display
    $0 --boot-only              # Just test boot process

EOF
}

check_requirements() {
    log "Checking requirements..."
    
    if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
        error "qemu-system-x86_64 not found. Install with: sudo apt install qemu-system-x86"
        exit 1
    fi
    
    if [ ! -f "$ISO_PATH" ]; then
        error "Custom ISO not found: $ISO_PATH"
        error "Build the ISO first with: ./scripts/iso-builder.sh"
        exit 1
    fi
    
    log "✓ QEMU available: $(qemu-system-x86_64 -version | head -1)"
    log "✓ Custom ISO found: $ISO_PATH ($(ls -lh "$ISO_PATH" | awk '{print $5}'))"
}

create_vm_disk() {
    if [ "$BOOT_ONLY" = "true" ]; then
        log "Boot-only mode: skipping disk creation"
        return
    fi
    
    log "Creating VM disk: $VM_DISK"
    qemu-img create -f qcow2 "$VM_DISK" 20G
    log "✓ VM disk created: 20GB"
}

test_iso_boot() {
    log "Testing ISO boot in QEMU..."
    log "ISO: $ISO_PATH"
    log "Memory: $VM_MEMORY"
    log "CPUs: $VM_CPUS"
    log "Display: $DISPLAY_TYPE"
    
    local qemu_args=(
        -machine type=pc,accel=kvm
        -cpu host
        -m "$VM_MEMORY"
        -smp "$VM_CPUS"
        -cdrom "$ISO_PATH"
        -boot d
        -netdev user,id=net0
        -device e1000,netdev=net0
    )
    
    if [ "$DISABLE_KVM" = "true" ]; then
        qemu_args[0]="-machine type=pc"
        log "KVM acceleration disabled"
    fi
    
    if [ "$BOOT_ONLY" = "false" ]; then
        qemu_args+=(-hda "$VM_DISK")
    fi
    
    case "$DISPLAY_TYPE" in
        vnc)
            qemu_args+=(-vnc :1)
            log "VNC display enabled on :5901"
            log "Connect with: vncviewer localhost:5901"
            ;;
        sdl)
            qemu_args+=(-display sdl)
            ;;
        gtk)
            qemu_args+=(-display gtk)
            ;;
    esac
    
    log "Starting QEMU with arguments: ${qemu_args[*]}"
    log ""
    log "VM Controls:"
    log "  - Ctrl+Alt+G: Release mouse"
    log "  - Ctrl+Alt+F: Toggle fullscreen"
    log "  - Ctrl+Alt+Q: Quit QEMU"
    log ""
    
    qemu-system-x86_64 "${qemu_args[@]}"
}

cleanup() {
    if [ "$BOOT_ONLY" = "false" ] && [ -f "$VM_DISK" ]; then
        read -p "Delete VM disk? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -f "$VM_DISK"
            log "VM disk deleted"
        fi
    fi
}

# Default values
DISPLAY_TYPE="gtk"
DISABLE_KVM=false
BOOT_ONLY=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            show_help
            exit 0
            ;;
        --memory)
            VM_MEMORY="$2"
            shift 2
            ;;
        --cpus)
            VM_CPUS="$2"
            shift 2
            ;;
        --disk)
            VM_DISK="$2"
            shift 2
            ;;
        --iso)
            ISO_PATH="$2"
            shift 2
            ;;
        --vnc)
            DISPLAY_TYPE="vnc"
            shift
            ;;
        --no-kvm)
            DISABLE_KVM=true
            shift
            ;;
        --boot-only)
            BOOT_ONLY=true
            shift
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main execution
main() {
    log "Ubuntu ISO VM Test Starting..."
    
    check_requirements
    
    if [ "$BOOT_ONLY" = "false" ]; then
        create_vm_disk
    fi
    
    test_iso_boot
    
    cleanup
    
    log "VM test completed"
}

# Trap cleanup on exit
trap cleanup EXIT

main "$@"
