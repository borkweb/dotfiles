#!/usr/bin/env bash

set -e

echo "=== Ubuntu/Debian Bootstrap Script ==="
echo "Installing prerequisites for Ansible dotfiles setup"
echo

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    SUDO=""
else
    SUDO="sudo"
    # Verify sudo access
    $SUDO -v
fi

# Detect WSL
if grep -qi microsoft /proc/version 2>/dev/null; then
    echo "Detected WSL environment"
    IS_WSL=true
else
    IS_WSL=false
fi

# Update apt cache
echo "Updating apt cache..."
$SUDO apt-get update -qq
echo "✓ apt cache updated"

# Install required packages
echo "Installing required packages..."
$SUDO apt-get install -y -qq \
    software-properties-common \
    python3 \
    python3-pip \
    git \
    curl
echo "✓ Required packages installed"

# Check if Ansible is installed
if ! command -v ansible &>/dev/null; then
    echo "Installing Ansible..."
    $SUDO apt-get install -y -qq ansible
    echo "✓ Ansible installed"
else
    echo "✓ Ansible already installed ($(ansible --version | head -n1))"
fi

echo
echo "=== Ubuntu/Debian Bootstrap Complete ==="
if [[ $IS_WSL == true ]]; then
    echo
    echo "WSL detected: Remember to install X server on Windows for GUI apps"
    echo "  - Download VcXsrv: https://sourceforge.net/projects/vcxsrv/"
    echo "  - Launch with: 'Disable access control' checked"
fi
