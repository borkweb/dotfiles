# dotfiles
My current dotfiles

## Quick Start (Ansible)

### Fresh Machine Setup

If you're setting up a completely fresh machine without Ansible installed, use the bootstrap script:

```bash
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

The script will automatically detect your OS and run the appropriate setup. It will install:
- Command Line Tools (macOS only)
- Homebrew (macOS) or required apt packages (Ubuntu)
- Ansible
- Git and other prerequisites

**Platform-specific scripts** (if you prefer):
- macOS: `./setup-mac.sh`
- Ubuntu/Debian/WSL2: `./setup-ubuntu.sh`

After the bootstrap script completes, proceed with the installation steps below.

### Prerequisites

- Ansible 2.9 or higher
- Git
- sudo access (for package installation)

### Installation

1. Clone this repository (skip if you already ran a bootstrap script):
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. Run the Ansible playbook:
   ```bash
   cd ansible
   ansible-playbook playbook.yml
   ```

3. For WSL users: Manually create Windows symlink for IdeaVim (see output for command)

### Selective Installation

Install only specific components using tags:

```bash
# Only shell configuration
cd ansible && ansible-playbook playbook.yml --tags shell

# Shell and tmux
cd ansible && ansible-playbook playbook.yml --tags shell,tmux

# Everything except WordPress
cd ansible && ansible-playbook playbook.yml --skip-tags wordpress

# Config files only (no packages)
cd ansible && ansible-playbook playbook.yml --skip-tags packages
```

### Customization

Edit variables in `group_vars/all.yml`:

```yaml
wordpress_dev_path: "{{ ansible_env.HOME }}/wordpress-dev"  # Or "" to skip
install_packages: true           # Set false for config-only
default_shell: /bin/zsh
```
