#!/bin/bash
set -euo pipefail

# Ubuntu ISO Customizer Test Suite
# Tests various components of the customization system

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly TEST_LOG="/tmp/ubuntu-customizer-test.log"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$TEST_LOG"
}

# Test result functions
test_start() {
    ((TESTS_RUN++))
    log "TEST: $1"
}

test_pass() {
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓ PASS${NC}: $1"
    log "PASS: $1"
}

test_fail() {
    ((TESTS_FAILED++))
    echo -e "${RED}✗ FAIL${NC}: $1"
    log "FAIL: $1"
}

test_skip() {
    echo -e "${YELLOW}⚠ SKIP${NC}: $1"
    log "SKIP: $1"
}

# Test script syntax
test_script_syntax() {
    test_start "Script syntax validation"
    local errors=0
    
    while IFS= read -r -d '' script; do
        if ! bash -n "$script" 2>/dev/null; then
            test_fail "Syntax error in $script"
            ((errors++))
        fi
    done < <(find "$PROJECT_ROOT/scripts" -name "*.sh" -print0)
    
    if [ $errors -eq 0 ]; then
        test_pass "All scripts have valid syntax"
    fi
}

# Test script permissions
test_script_permissions() {
    test_start "Script permissions"
    local errors=0
    
    while IFS= read -r -d '' script; do
        if [ ! -x "$script" ]; then
            test_fail "$script is not executable"
            ((errors++))
        fi
    done < <(find "$PROJECT_ROOT/scripts" -name "*.sh" -print0)
    
    if [ $errors -eq 0 ]; then
        test_pass "All scripts are executable"
    fi
}

# Test required dependencies
test_dependencies() {
    test_start "Required dependencies"
    local missing=()
    local required=(xorriso mksquashfs genisoimage rsync)
    
    for cmd in "${required[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -eq 0 ]; then
        test_pass "All required dependencies are installed"
    else
        test_fail "Missing dependencies: ${missing[*]}"
    fi
}

# Test configuration files
test_config_files() {
    test_start "Configuration files"
    local configs=(
        "$PROJECT_ROOT/configs/config.env.example"
        "$PROJECT_ROOT/configs/preseed.cfg"
        "$PROJECT_ROOT/configs/package-lists/development.list"
        "$PROJECT_ROOT/configs/dotfiles/.gitconfig"
    )
    
    local missing=0
    for config in "${configs[@]}"; do
        if [ ! -f "$config" ]; then
            test_fail "Missing config file: $config"
            ((missing++))
        fi
    done
    
    if [ $missing -eq 0 ]; then
        test_pass "All configuration files exist"
    fi
}

# Test post-install script dry run
test_post_install_dry_run() {
    test_start "Post-install script dry run"
    
    if [ -f "$PROJECT_ROOT/scripts/post-install.sh" ]; then
        if "$PROJECT_ROOT/scripts/post-install.sh" --dry-run >/dev/null 2>&1; then
            test_pass "Post-install script dry run succeeded"
        else
            test_fail "Post-install script dry run failed"
        fi
    else
        test_fail "Post-install script not found"
    fi
}

# Test package lists
test_package_lists() {
    test_start "Package lists validation"
    local errors=0
    
    while IFS= read -r -d '' list_file; do
        if [ ! -s "$list_file" ]; then
            test_fail "Package list is empty: $list_file"
            ((errors++))
            continue
        fi
        
        # Check for invalid characters or malformed entries (allow comments and whitespace)
        if grep -v '^[[:space:]]*#' "$list_file" | grep -v '^[[:space:]]*$' | grep -q '[^a-zA-Z0-9._+[:space:]-]'; then
            test_fail "Package list contains invalid characters: $list_file"
            ((errors++))
        fi
    done < <(find "$PROJECT_ROOT/configs/package-lists" -name "*.list" -print0)
    
    if [ $errors -eq 0 ]; then
        test_pass "All package lists are valid"
    fi
}

# Test documentation
test_documentation() {
    test_start "Documentation completeness"
    local docs=(
        "$PROJECT_ROOT/README.md"
        "$PROJECT_ROOT/docs/installation.md"
        "$PROJECT_ROOT/docs/customization.md"
        "$PROJECT_ROOT/docs/tools.md"
    )
    
    local missing=0
    for doc in "${docs[@]}"; do
        if [ ! -f "$doc" ] || [ ! -s "$doc" ]; then
            test_fail "Missing or empty documentation: $doc"
            ((missing++))
        fi
    done
    
    if [ $missing -eq 0 ]; then
        test_pass "All documentation files exist and are not empty"
    fi
}

# Test directory structure
test_directory_structure() {
    test_start "Directory structure"
    local dirs=(
        "$PROJECT_ROOT/scripts"
        "$PROJECT_ROOT/scripts/tools"
        "$PROJECT_ROOT/configs"
        "$PROJECT_ROOT/configs/package-lists"
        "$PROJECT_ROOT/configs/dotfiles"
        "$PROJECT_ROOT/docs"
        "$PROJECT_ROOT/.vscode"
        "$PROJECT_ROOT/.github"
    )
    
    local missing=0
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            test_fail "Missing directory: $dir"
            ((missing++))
        fi
    done
    
    if [ $missing -eq 0 ]; then
        test_pass "All required directories exist"
    fi
}

# Test ISO builder script help
test_iso_builder_help() {
    test_start "ISO builder help functionality"
    
    if [ -f "$PROJECT_ROOT/scripts/iso-builder.sh" ]; then
        if "$PROJECT_ROOT/scripts/iso-builder.sh" --help >/dev/null 2>&1; then
            test_pass "ISO builder help works"
        else
            test_fail "ISO builder help failed"
        fi
    else
        test_fail "ISO builder script not found"
    fi
}

# Run virtual machine test (if available)
test_vm_compatibility() {
    test_start "Virtual machine compatibility"
    
    if command -v qemu-system-x86_64 >/dev/null 2>&1; then
        test_skip "VM testing requires manual setup"
    else
        test_skip "QEMU not available for VM testing"
    fi
}

# Main test runner
main() {
    log "Starting Ubuntu ISO Customizer test suite"
    echo "Ubuntu ISO Customizer Test Suite"
    echo "=================================="
    echo
    
    # Run all tests
    test_directory_structure
    test_script_syntax
    test_script_permissions
    test_dependencies
    test_config_files
    test_package_lists
    test_documentation
    test_post_install_dry_run
    test_iso_builder_help
    test_vm_compatibility
    
    # Print summary
    echo
    echo "Test Summary"
    echo "============"
    echo "Tests run: $TESTS_RUN"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    echo
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        log "All tests passed"
        exit 0
    else
        echo -e "${RED}Some tests failed. Check the log: $TEST_LOG${NC}"
        log "Test suite completed with $TESTS_FAILED failures"
        exit 1
    fi
}

# Help function
show_help() {
    cat << EOF
Ubuntu ISO Customizer Test Suite

Usage: $0 [OPTIONS]

Options:
    --help          Show this help message
    --verbose       Enable verbose output
    --log-file FILE Specify custom log file

Tests performed:
    - Directory structure validation
    - Script syntax checking
    - Script permissions verification
    - Dependency availability
    - Configuration file presence
    - Package list validation
    - Documentation completeness
    - Post-install script dry run
    - ISO builder functionality

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            show_help
            exit 0
            ;;
        --verbose)
            set -x
            shift
            ;;
        --log-file)
            readonly TEST_LOG="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

main "$@"
