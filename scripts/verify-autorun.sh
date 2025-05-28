#!/bin/bash

# Verification script to check if autorun mechanism worked
# Run this script inside the VM that was installed from the custom ISO

echo "=== Ubuntu ISO Customizer - Autorun Verification ==="
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo ""

# Check 1: Verify the systemd service exists and its status
echo "1. Checking systemd service status:"
echo "=================================="
if systemctl list-unit-files | grep -q "custom-post-install.service"; then
    echo "✓ custom-post-install.service is installed"
    echo "Service status:"
    systemctl status custom-post-install.service --no-pager
    echo ""
    echo "Service is enabled:" $(systemctl is-enabled custom-post-install.service 2>/dev/null || echo "NO")
else
    echo "✗ custom-post-install.service NOT found"
fi
echo ""

# Check 2: Verify custom scripts were copied
echo "2. Checking custom scripts installation:"
echo "======================================="
if [ -d "/usr/local/bin/custom-setup" ]; then
    echo "✓ Custom setup directory exists"
    echo "Contents:"
    ls -la /usr/local/bin/custom-setup/
    echo ""
    
    if [ -f "/usr/local/bin/custom-setup/post-install.sh" ]; then
        echo "✓ post-install.sh is present"
        echo "Permissions: $(ls -l /usr/local/bin/custom-setup/post-install.sh | awk '{print $1}')"
    else
        echo "✗ post-install.sh NOT found"
    fi
else
    echo "✗ Custom setup directory NOT found at /usr/local/bin/custom-setup"
fi
echo ""

# Check 3: Check journal logs for execution evidence
echo "3. Checking systemd journal for execution logs:"
echo "=============================================="
echo "Recent custom-post-install service logs:"
journalctl -u custom-post-install.service --no-pager -n 20 2>/dev/null || echo "No logs found"
echo ""

# Check 4: Check if custom user was created
echo "4. Checking user configuration:"
echo "=============================="
current_user=$(whoami)
echo "Current user: $current_user"
if [ "$current_user" = "developer" ]; then
    echo "✓ Custom user 'developer' was created as expected"
else
    echo "ℹ User is '$current_user' (may be different from preseed config)"
fi
echo ""

# Check 5: Check hostname
echo "5. Checking hostname configuration:"
echo "=================================="
hostname=$(hostname)
if [ "$hostname" = "ubuntu-dev" ]; then
    echo "✓ Hostname is 'ubuntu-dev' as configured in preseed"
else
    echo "ℹ Hostname is '$hostname' (may be different from preseed config)"
fi
echo ""

# Check 6: Check for any custom configuration files
echo "6. Checking for custom configuration evidence:"
echo "============================================="
if [ -f "/var/log/custom-setup.log" ]; then
    echo "✓ Custom setup log found:"
    tail -10 /var/log/custom-setup.log
elif [ -f "/tmp/custom-setup.log" ]; then
    echo "✓ Custom setup log found in /tmp:"
    tail -10 /tmp/custom-setup.log
else
    echo "ℹ No custom setup log found (this may be normal)"
fi
echo ""

# Check 7: Check for installed packages from preseed
echo "7. Checking preseed-specified packages:"
echo "======================================"
packages=("openssh-server" "curl" "wget" "git" "vim")
for pkg in "${packages[@]}"; do
    if dpkg -l | grep -q "^ii.*$pkg "; then
        echo "✓ $pkg is installed"
    else
        echo "✗ $pkg is NOT installed"
    fi
done
echo ""

# Check 8: Check system timezone
echo "8. Checking timezone configuration:"
echo "================================="
timezone=$(timedatectl show --property=Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null)
if [ "$timezone" = "UTC" ]; then
    echo "✓ Timezone is UTC as configured in preseed"
else
    echo "ℹ Timezone is '$timezone' (may be different from preseed config)"
fi
echo ""

# Summary
echo "=== VERIFICATION SUMMARY ==="
echo "Run this verification inside your VM to check if:"
echo "- The systemd service was created and enabled"
echo "- Custom scripts were properly copied"
echo "- The autorun mechanism executed"
echo "- Preseed configuration was applied"
echo ""
echo "If the service exists but failed, check:"
echo "  journalctl -u custom-post-install.service -f"
echo "  systemctl status custom-post-install.service"
echo ""
