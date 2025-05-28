#!/bin/bash
set -euo pipefail

echo "=== Quick Test Suite ==="

# Test 1: Directory structure
echo "Testing directory structure..."
required_dirs=("scripts" "configs" "docs")
for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "❌ Missing directory: $dir"
        exit 1
    else
        echo "✅ Found directory: $dir"
    fi
done

# Test 2: Script syntax
echo "Testing script syntax..."
for script in scripts/*.sh; do
    if bash -n "$script"; then
        echo "✅ Syntax OK: $script"
    else
        echo "❌ Syntax error: $script"
        exit 1
    fi
done

# Test 3: Dependencies
echo "Testing dependencies..."
deps=("xorriso" "mksquashfs" "genisoimage" "rsync")
for dep in "${deps[@]}"; do
    if command -v "$dep" >/dev/null 2>&1; then
        echo "✅ Found dependency: $dep"
    else
        echo "❌ Missing dependency: $dep"
        exit 1
    fi
done

# Test 4: Config file
echo "Testing config file..."
if [ -f "configs/config.env" ]; then
    echo "✅ Config file exists"
    if source configs/config.env; then
        echo "✅ Config file loads successfully"
    else
        echo "❌ Config file has errors"
        exit 1
    fi
else
    echo "❌ Config file missing"
    exit 1
fi

# Test 5: ISO exists
echo "Testing custom ISO..."
if [ -f "ubuntu-custom-20250527.iso" ]; then
    echo "✅ Custom ISO exists"
    size=$(ls -lh ubuntu-custom-20250527.iso | awk '{print $5}')
    echo "   Size: $size"
else
    echo "⚠️  Custom ISO not found (may need to be built)"
fi

echo ""
echo "🎉 All tests passed!"
