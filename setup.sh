#!/usr/bin/env bash

set -e

echo "=== Dotfiles Bootstrap ==="
echo "Detecting operating system..."
echo

# Detect OS
OS="$(uname -s)"

case "${OS}" in
    Darwin*)
        echo "Detected: macOS"
        echo "Running macOS bootstrap script..."
        echo
        ./setup/setup-mac.sh
        ;;
    Linux*)
        # Check if it's Ubuntu/Debian by looking for apt
        if command -v apt-get &>/dev/null; then
            echo "Detected: Ubuntu/Debian Linux"
            echo "Running Ubuntu bootstrap script..."
            echo
            ./setup/setup-ubuntu.sh
        else
            echo "Error: Unsupported Linux distribution"
            echo "This script supports Ubuntu/Debian systems with apt-get."
            echo "Please install Ansible manually and run: cd ansible && ansible-playbook playbook.yml"
            exit 1
        fi
        ;;
    *)
        echo "Error: Unsupported operating system: ${OS}"
        echo "Supported systems: macOS, Ubuntu, Debian"
        echo "Please install Ansible manually and run: cd ansible && ansible-playbook playbook.yml"
        exit 1
        ;;
esac

# Run the Ansible playbook
echo
echo "=== Running Ansible Playbook ==="
cd ansible
ansible-playbook playbook.yml
