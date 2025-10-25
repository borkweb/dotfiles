#!/usr/bin/env bash

set -e

echo "=== macOS Bootstrap Script ==="
echo "Installing prerequisites for Ansible dotfiles setup"
echo

# Check if Command Line Tools are installed
if ! xcode-select -p &>/dev/null; then
    echo "Installing Command Line Tools..."
    xcode-select --install
    echo "Please complete the Command Line Tools installation in the dialog,"
    echo "then run this script again."
    exit 1
else
    echo "✓ Command Line Tools installed"
fi

# Check if Homebrew is installed
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for this session
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    echo "✓ Homebrew installed"
else
    echo "✓ Homebrew already installed"
fi

# Check if Ansible is installed
if ! command -v ansible &>/dev/null; then
    echo "Installing Ansible..."
    brew install ansible
    echo "✓ Ansible installed"
else
    echo "✓ Ansible already installed ($(ansible --version | head -n1))"
fi

echo
echo "=== macOS Bootstrap Complete ==="
