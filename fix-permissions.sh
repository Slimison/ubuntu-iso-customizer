#!/bin/bash
#=======================================
# Fix Permissions Script
# Fixes ownership issues after cloning the repository
# Run this immediately after cloning if you encounter permission issues
#=======================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    log_error "This script should NOT be run as root!"
    log_error "Run it as your regular user to fix ownership issues."
    exit 1
fi

echo "Ubuntu ISO Customizer - Permission Fix Script"
echo "============================================="
echo ""

current_user=$(whoami)
log_info "Current user: $current_user"

# Check for root-owned files
log_info "Checking for root-owned files..."
root_files=$(find "$PROJECT_ROOT" -user root 2>/dev/null || true)

if [[ -n "$root_files" ]]; then
    log_warning "Found root-owned files:"
    echo "$root_files" | sed 's/^/  /'
    echo ""
    
    log_info "Attempting to fix ownership..."
    if sudo chown -R "$current_user:$current_user" "$PROJECT_ROOT"; then
        log_success "Fixed ownership to $current_user:$current_user"
    else
        log_error "Failed to fix ownership. Try running:"
        echo "  sudo chown -R \$USER:\$USER $(basename "$PROJECT_ROOT")"
        exit 1
    fi
else
    log_success "No root-owned files found"
fi

# Remove problematic iso-workspace if it exists
if [[ -d "$PROJECT_ROOT/iso-workspace" ]]; then
    workspace_owner=$(stat -c '%U' "$PROJECT_ROOT/iso-workspace" 2>/dev/null || echo "unknown")
    if [[ "$workspace_owner" = "root" ]]; then
        log_warning "Found root-owned iso-workspace directory"
        log_info "Removing it to prevent build issues..."
        if sudo rm -rf "$PROJECT_ROOT/iso-workspace"; then
            log_success "Removed root-owned iso-workspace"
        else
            log_error "Failed to remove iso-workspace"
            exit 1
        fi
    else
        log_info "iso-workspace is owned by $workspace_owner (OK)"
    fi
fi

# Make all scripts executable
log_info "Making scripts executable..."
find "$PROJECT_ROOT/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
find "$PROJECT_ROOT" -maxdepth 1 -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
log_success "Scripts are now executable"

# Check final permissions
log_info "Verifying permissions..."
if [[ "$(stat -c '%U' "$PROJECT_ROOT")" = "$current_user" ]]; then
    log_success "Project directory is correctly owned by $current_user"
else
    log_warning "Project directory owner: $(stat -c '%U' "$PROJECT_ROOT")"
fi

echo ""
log_success "Permission fixes completed!"
echo ""
echo "Next steps:"
echo "1. Run './setup.sh' to install dependencies"
echo "2. Build your custom ISO with: sudo ./scripts/iso-builder.sh /path/to/ubuntu.iso"
echo ""
echo "Note: The iso-builder.sh script runs with sudo but ensures all files"
echo "      remain owned by your user to prevent future permission issues."
