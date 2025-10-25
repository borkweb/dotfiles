# Ansible Dotfiles Automation Design

**Date:** 2025-10-25
**Status:** Approved
**Target Systems:** macOS, WSL2 (Ubuntu/Debian)

## Overview

Convert the existing dotfiles repository to use Ansible for automated setup and configuration management across macOS and WSL2 environments. The automation will handle both package installation and configuration file management, including WordPress development utilities.

## Requirements

- **Target Platforms:** macOS and WSL2 (Ubuntu/Debian)
- **Scope:** Full automation - package installation + configuration management
- **WordPress Integration:** Include mu-plugins and bin utilities in playbook
- **Repository Structure:** Hybrid approach - simple dotfiles in root, complex configs in roles

## Architecture

### Approach: Role-Based Organization

Separate Ansible roles for each major component (shell, editor, tmux, wordpress, bin-utils). Each role owns its package installation and configuration. This provides clean separation, scalability, and maintainability.

### Repository Structure

```
dotfiles/
├── ansible.cfg              # Ansible configuration
├── playbook.yml            # Main playbook entry point
├── inventory/
│   └── hosts               # Localhost inventory
├── group_vars/
│   ├── all.yml            # Common variables
│   ├── darwin.yml         # macOS-specific variables
│   └── wsl.yml            # WSL2-specific variables
├── roles/
│   ├── common/            # Base packages, system setup
│   │   ├── tasks/main.yml
│   │   └── vars/main.yml
│   ├── shell/             # zsh, oh-my-zsh, powerlevel10k
│   │   ├── tasks/main.yml
│   │   ├── files/
│   │   └── vars/main.yml
│   ├── tmux/              # tmux configuration
│   │   ├── tasks/main.yml
│   │   └── vars/main.yml
│   ├── neovim/            # neovim + plugins setup
│   │   ├── tasks/main.yml
│   │   ├── templates/
│   │   └── vars/main.yml
│   ├── ideavim/           # IdeaVim configuration
│   │   ├── tasks/main.yml
│   │   └── files/
│   ├── bin-utils/         # Custom scripts (gentags, etc.)
│   │   ├── tasks/main.yml
│   │   └── files/
│   └── wordpress/         # WP mu-plugins setup
│       ├── tasks/main.yml
│       └── files/
├── .zshrc                 # Keep in root (hybrid approach)
├── .tmux.conf             # Keep in root
├── .vim/                  # Vim configuration directory
└── README.md
```

**Hybrid Structure Rationale:**
- Simple, frequently-viewed dotfiles (`.zshrc`, `.tmux.conf`) remain in repository root for easy access
- Complex configurations requiring templating or multiple files live in role directories
- Balances readability with proper Ansible organization

## Role Breakdown

### 1. common Role

**Responsibilities:**
- Detect operating system (macOS vs WSL2)
- Set OS-specific facts for use by other roles
- Install base packages: `git`, `curl`, `wget`, `tree`
- Create necessary directories (`~/.vim`, `~/bin`, etc.)
- Handle WSL-specific environment setup:
  - Detect HOST_IP for xdebug configuration
  - Configure DISPLAY variable for X11 forwarding

**Key Tasks:**
- OS detection via `/proc/version` (WSL) or `ansible_os_family` (Darwin)
- Directory creation with proper permissions
- WSL environment variable configuration

### 2. shell Role

**Responsibilities:**
- Install zsh package (via apt/Homebrew depending on OS)
- Install oh-my-zsh framework
- Install powerlevel10k theme
- Install required command-line tools:
  - `exa` (modern ls replacement)
  - `bat` (modern cat replacement)
  - `ag` (The Silver Searcher)
  - `fzf` (fuzzy finder)
- Symlink `.zshrc` from repository root to `~/.zshrc`
- Set zsh as default shell

**Key Tasks:**
- Oh-my-zsh installation (check if already installed)
- Powerlevel10k git clone into oh-my-zsh themes directory
- Package installation with OS-specific package managers
- Default shell configuration via `chsh`

### 3. tmux Role

**Responsibilities:**
- Install tmux package
- Symlink `.tmux.conf` from repository root to `~/.tmux.conf`
- Install tmux plugin manager (TPM) if configured

**Key Tasks:**
- Package installation
- Symlink creation with `force: yes` for updates
- Optional TPM setup

### 4. neovim Role

**Responsibilities:**
- Install neovim (version-appropriate for each OS)
- Install vim-plug plugin manager
- Sync entire `.vim/` directory structure to `~/.vim/`
- Install language servers (phpactor for PHP)
- Install Python packages for deoplete (pynvim)
- Install ctags for tag generation
- Execute `:PlugInstall` to install vim plugins

**Key Tasks:**
- Neovim package installation
- vim-plug download and installation
- Directory synchronization (`.vim/`)
- Python dependencies via pip
- Phpactor installation
- Automated plugin installation

### 5. ideavim Role

**Responsibilities:**
- Copy `.ideavimrc` to home directory
- On WSL2: Document Windows symlink creation process
- Validate required IntelliJ plugins are documented

**Key Tasks:**
- File copy to `~/.ideavimrc`
- WSL2: Provide instructions for manual Windows symlink via `/mnt/c/` path
- README documentation update with required plugins list

**Note:** Windows symlink creation requires user action as it cannot be automated from WSL2.

### 6. bin-utils Role

**Responsibilities:**
- Symlink all scripts from `bin/` directory to `~/bin/`
- Ensure `~/bin` is in PATH
- Make all scripts executable

**Key Tasks:**
- Directory creation (`~/bin`)
- Script symlinking with loop
- Permission setting (chmod +x)
- PATH verification and update if necessary

### 7. wordpress Role

**Responsibilities:**
- Create WordPress development mu-plugins directory
- Symlink mu-plugins from `wordpress/mu-plugins/` to target directory
- Conditional execution based on variable configuration

**Key Tasks:**
- Directory creation at `wordpress_dev_path`
- Symlink creation for each mu-plugin file
- Graceful skip if `wordpress_dev_path` not defined

**Configuration:**
- Role only executes when `wordpress_dev_path` variable is set
- Default path: `~/wordpress-dev/mu-plugins/`
- Users can override or unset to skip

## Playbook Execution Flow

### Main Playbook Structure

```yaml
# playbook.yml
- hosts: localhost
  connection: local

  pre_tasks:
    - name: Detect OS and set facts
      # Sets ansible_os_family, is_wsl, is_macos

  roles:
    - common          # Always runs first - system detection and base setup
    - shell           # Core shell environment
    - tmux            # Terminal multiplexer
    - neovim          # Editor configuration
    - ideavim         # IDE vim bindings
    - bin-utils       # Custom utility scripts
    - wordpress       # Conditional: only if wordpress_dev_path defined
```

### Variables

**Common Variables** (`group_vars/all.yml`):
```yaml
# User-customizable settings
wordpress_dev_path: "{{ ansible_env.HOME }}/wordpress-dev"  # Set empty to skip
install_packages: true           # Set false for config-only mode
neovim_install_plugins: true    # Auto-run :PlugInstall
default_shell: /bin/zsh

# Directory paths
bin_dir: "{{ ansible_env.HOME }}/bin"
vim_dir: "{{ ansible_env.HOME }}/.vim"
```

**WSL-Specific** (`group_vars/wsl.yml`):
```yaml
wsl_host_ip: "{{ lookup('pipe', 'ip route | grep default | awk \"{print $3}\"') }}"
wsl_display: "{{ wsl_host_ip }}:0"

# WSL package manager
package_manager: apt
```

**macOS-Specific** (`group_vars/darwin.yml`):
```yaml
# Homebrew packages
homebrew_packages:
  - neovim
  - tmux
  - zsh
  - exa
  - bat
  - the_silver_searcher
  - fzf
  - ctags

package_manager: homebrew
```

### Idempotency

All tasks designed to be idempotent:
- **File operations:** Use Ansible `file` module with `state: link, force: yes` for symlinks
- **Package installation:** Package modules naturally idempotent
- **Git clones:** Check for existing directory before cloning
- **Shell changes:** Check current shell before running `chsh`

Re-running the playbook will not break existing configurations or duplicate work.

### Tagging Strategy

Each role tagged for selective execution:

```bash
# Install everything
ansible-playbook playbook.yml

# Only shell and tmux
ansible-playbook playbook.yml --tags shell,tmux

# Skip WordPress role
ansible-playbook playbook.yml --skip-tags wordpress

# Config files only (skip package installation)
ansible-playbook playbook.yml --skip-tags packages
```

Tag categories:
- Role tags: `common`, `shell`, `tmux`, `neovim`, `ideavim`, `bin-utils`, `wordpress`
- Function tags: `packages`, `configs`, `symlinks`

## OS-Specific Handling

### OS Detection

```yaml
# Common role - early in execution
- name: Detect WSL environment
  set_fact:
    is_wsl: "{{ lookup('file', '/proc/version', errors='ignore') | regex_search('microsoft|WSL', ignorecase=True) | bool }}"

- name: Detect macOS
  set_fact:
    is_macos: "{{ ansible_os_family == 'Darwin' }}"
```

### Package Installation Differences

**WSL2:**
- Package manager: `apt` module
- Update cache before installation
- Handle missing packages gracefully
- No Homebrew installation attempts

**macOS:**
- Package manager: `homebrew` module
- Auto-install Homebrew if missing (via shell script)
- Distinguish between formula and cask packages
- Skip apt-specific tasks

### Critical OS-Specific Tasks

**WSL2-Only Tasks:**
- Set `HOST_IP` environment variable in `.zshrc` for xdebug
- Configure `DISPLAY` variable for X11 GUI forwarding
- No Homebrew-related operations
- Use `/home/` for home directory paths

**macOS-Only Tasks:**
- Install packages via Homebrew
- Handle different home directory path (`/Users/`)
- Skip apt and WSL-specific environment variables
- May require Xcode Command Line Tools

### Conditional Task Execution

```yaml
# Example from shell role
- name: Install zsh (Debian/Ubuntu)
  apt:
    name: zsh
    state: present
  when: ansible_os_family == "Debian"

- name: Install zsh (macOS)
  homebrew:
    name: zsh
    state: present
  when: is_macos
```

## Error Handling & Recovery

### Installation Error Handling

**Oh-my-zsh:**
- Check if `~/.oh-my-zsh` exists before running install script
- Catch installation failures, log warning, continue playbook
- Verify installation post-task

**Vim Plugins:**
- Attempt `:PlugInstall` via headless neovim
- Catch failures, log error details, don't fail entire playbook
- User can manually run `:PlugInstall` later if needed

**IdeaVim Windows Symlink:**
- Cannot automate from WSL2
- Display clear instructions to user
- Provide exact command for manual execution in Windows

**WordPress mu-plugins:**
- Skip gracefully if `wordpress_dev_path` undefined
- Check if target directory exists before symlinking
- Create directory if missing, fail gracefully if permissions denied

### Verification Tasks

Post-installation verification for critical components:

**After shell role:**
```yaml
- name: Verify zsh installation
  command: zsh --version
  register: zsh_version

- name: Verify zsh is default shell
  command: echo $SHELL
  register: current_shell
  failed_when: "'/zsh' not in current_shell.stdout"
```

**After neovim role:**
```yaml
- name: Verify neovim installation
  command: nvim --version
  register: nvim_version
```

**After symlinks:**
```yaml
- name: Verify symlink targets exist
  stat:
    path: "{{ item }}"
  loop:
    - ~/.zshrc
    - ~/.tmux.conf
    - ~/.ideavimrc
  register: symlink_check
  failed_when: not symlink_check.stat.exists
```

### Failure Recovery Strategy

- **Non-critical failures:** Log warning, continue execution
- **Critical failures:** Stop playbook, display clear error message
- **Partial completion:** Track completed tasks, allow resume from specific role
- **Rollback:** Not implemented - users can re-run after fixing issues

## Success Criteria

The implementation is successful when:

1. **Cross-platform execution:** Playbook runs successfully on both macOS and WSL2 without modification
2. **Idempotency:** Re-running playbook produces no changes (all tasks report "ok" not "changed")
3. **Complete automation:** Fresh system can be configured with single `ansible-playbook` command
4. **Selective execution:** Tags allow installing only specific components
5. **Configuration accuracy:** All dotfiles symlinked correctly, all tools functional
6. **Documentation:** README updated with clear installation and usage instructions

## Migration Path

For existing dotfiles users:

1. **Backup:** Current configurations automatically backed up by symlink force behavior
2. **Test run:** `ansible-playbook playbook.yml --check` shows what would change
3. **Incremental adoption:** Use tags to migrate one component at a time
4. **Rollback:** Original files remain in repository root for easy manual restoration

## Future Enhancements

Possible future improvements:

- Additional roles: `git` (global gitconfig), `python` (pyenv, virtualenv)
- Template-based dotfiles: Allow variable substitution in `.zshrc`
- Backup role: Automatically backup existing dotfiles before replacement
- Testing: Molecule tests for each role
- CI/CD: GitHub Actions to test playbook on multiple OS versions
