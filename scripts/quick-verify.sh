#!/bin/bash

# Quick verification script to test in VM after installation
echo "=== QUICK AUTORUN VERIFICATION ==="
echo "Run this in your VM after installation from the new ISO"
echo ""

echo "1. Checking systemd service:"
if systemctl list-unit-files | grep -q "custom-post-install.service"; then
    echo "✅ Service exists"
    systemctl status custom-post-install.service --no-pager
else
    echo "❌ Service NOT found"
fi
echo ""

echo "2. Checking custom scripts:"
if [ -d "/usr/local/bin/custom-setup" ]; then
    echo "✅ Scripts directory exists"
    ls -la /usr/local/bin/custom-setup/
else
    echo "❌ Scripts directory NOT found"
fi
echo ""

echo "3. Checking journal logs:"
journalctl -u custom-post-install.service --no-pager -n 10 2>/dev/null || echo "No service logs found"
echo ""

echo "4. Basic preseed verification:"
echo "Hostname: $(hostname)"
echo "User: $(whoami)"
echo "Timezone: $(timedatectl show --property=Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null)"
echo ""

echo "=== INSTALLATION DIAGNOSIS ==="
echo ""
echo "If the service is missing, check:"
echo "1. Did you use the 'Automated Install Ubuntu (Custom)' option from boot menu?"
echo "2. Check installation logs: journalctl --boot -p err"
echo "3. Check if late_command ran: grep -r 'late_command' /var/log/"
echo ""
