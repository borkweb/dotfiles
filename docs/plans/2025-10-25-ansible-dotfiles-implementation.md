# Ansible Dotfiles Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Convert dotfiles repository to Ansible-based automation for macOS and WSL2 environments

**Architecture:** Role-based Ansible structure with 7 specialized roles (common, shell, tmux, neovim, ideavim, bin-utils, wordpress). OS detection via facts, conditional execution based on platform. Hybrid file structure keeps simple dotfiles in root, complex configs in role templates.

**Tech Stack:** Ansible 2.9+, oh-my-zsh, powerlevel10k, neovim, tmux, zsh

---

## Task 1: Initial Ansible Configuration

**Files:**
- Create: `ansible.cfg`
- Create: `inventory/hosts`
- Create: `.gitignore` (modify)

**Step 1: Create Ansible configuration**

Create `ansible.cfg`:

```ini
[defaults]
inventory = inventory/hosts
roles_path = roles
host_key_checking = False
retry_files_enabled = False
display_skipped_hosts = False
callbacks_enabled = ansible.posix.profile_tasks

[privilege_escalation]
become_ask_pass = True
```

**Step 2: Create inventory file**

Create directory and file:

```bash
mkdir -p inventory
```

Create `inventory/hosts`:

```ini
[local]
localhost ansible_connection=local
```

**Step 3: Update .gitignore**

Add to `.gitignore`:

```
# Ansible
*.retry
.ansible/
```

**Step 4: Verify Ansible setup**

Run:

```bash
ansible --version
ansible-inventory --list
```

Expected: Ansible version info, inventory shows localhost

**Step 5: Commit**

```bash
git add ansible.cfg inventory/ .gitignore
git commit -m "feat: add initial Ansible configuration and inventory"
```

---

## Task 2: Group Variables Setup

**Files:**
- Create: `group_vars/all.yml`
- Create: `group_vars/darwin.yml`
- Create: `group_vars/wsl.yml`

**Step 1: Create common variables**

Create directory:

```bash
mkdir -p group_vars
```

Create `group_vars/all.yml`:

```yaml
---
# User-customizable settings
wordpress_dev_path: "{{ ansible_env.HOME }}/wordpress-dev"
install_packages: true
neovim_install_plugins: true
default_shell: /bin/zsh

# Directory paths
bin_dir: "{{ ansible_env.HOME }}/bin"
vim_dir: "{{ ansible_env.HOME }}/.vim"
dotfiles_dir: "{{ playbook_dir }}"

# Oh-my-zsh configuration
oh_my_zsh_dir: "{{ ansible_env.HOME }}/.oh-my-zsh"
oh_my_zsh_custom: "{{ oh_my_zsh_dir }}/custom"
```

**Step 2: Create macOS-specific variables**

Create `group_vars/darwin.yml`:

```yaml
---
package_manager: homebrew

homebrew_packages:
  - neovim
  - tmux
  - zsh
  - exa
  - bat
  - the_silver_searcher
  - fzf
  - ctags-exuberant

homebrew_taps:
  - homebrew/cask-fonts

homebrew_cask_packages:
  - font-meslo-lg-nerd-font
```

**Step 3: Create WSL-specific variables**

Create `group_vars/wsl.yml`:

```yaml
---
package_manager: apt

apt_packages:
  - neovim
  - tmux
  - zsh
  - bat
  - silversearcher-ag
  - fzf
  - exuberant-ctags
  - python3-pip

# WSL-specific environment detection
wsl_detect_command: "grep -qi microsoft /proc/version && echo true || echo false"
```

**Step 4: Verify variable files syntax**

Run:

```bash
ansible-playbook --syntax-check playbook.yml 2>&1 || echo "Playbook doesn't exist yet - variables OK"
```

Expected: No syntax errors in YAML files

**Step 5: Commit**

```bash
git add group_vars/
git commit -m "feat: add Ansible group variables for all, darwin, and wsl"
```

---

## Task 3: Main Playbook Structure

**Files:**
- Create: `playbook.yml`

**Step 1: Create main playbook**

Create `playbook.yml`:

```yaml
---
- name: Configure dotfiles
  hosts: local
  gather_facts: true

  pre_tasks:
    - name: Detect WSL environment
      set_fact:
        is_wsl: "{{ lookup('file', '/proc/version', errors='ignore') | regex_search('microsoft|WSL', ignorecase=True) | bool }}"
      tags: always

    - name: Detect macOS
      set_fact:
        is_macos: "{{ ansible_os_family == 'Darwin' }}"
      tags: always

    - name: Display detected OS
      debug:
        msg: "Detected OS - macOS: {{ is_macos }}, WSL: {{ is_wsl }}"
      tags: always

  roles:
    - role: common
      tags: [common, always]

    - role: shell
      tags: [shell, packages, configs]

    - role: tmux
      tags: [tmux, configs]

    - role: neovim
      tags: [neovim, editor, configs]

    - role: ideavim
      tags: [ideavim, configs]

    - role: bin-utils
      tags: [bin-utils, utils]

    - role: wordpress
      tags: [wordpress]
      when: wordpress_dev_path is defined and wordpress_dev_path != ""
```

**Step 2: Verify playbook syntax**

Run:

```bash
ansible-playbook playbook.yml --syntax-check
```

Expected: "playbook: playbook.yml" (no errors, but roles don't exist yet)

**Step 3: Test dry run**

Run:

```bash
ansible-playbook playbook.yml --check --diff 2>&1 | head -20
```

Expected: Errors about missing roles (expected at this stage)

**Step 4: Commit**

```bash
git add playbook.yml
git commit -m "feat: add main Ansible playbook with role structure"
```

---

## Task 4: Common Role - Directory Structure

**Files:**
- Create: `roles/common/tasks/main.yml`
- Create: `roles/common/vars/main.yml`
- Create: `roles/common/tasks/directories.yml`

**Step 1: Create role directory structure**

```bash
mkdir -p roles/common/{tasks,vars,handlers}
```

**Step 2: Create role variables**

Create `roles/common/vars/main.yml`:

```yaml
---
required_directories:
  - "{{ vim_dir }}"
  - "{{ vim_dir }}/pack"
  - "{{ vim_dir }}/core"
  - "{{ bin_dir }}"
  - "{{ ansible_env.HOME }}/.config"
```

**Step 3: Create directory tasks**

Create `roles/common/tasks/directories.yml`:

```yaml
---
- name: Create required directories
  file:
    path: "{{ item }}"
    state: directory
    mode: "0755"
  loop: "{{ required_directories }}"
```

**Step 4: Create main tasks file**

Create `roles/common/tasks/main.yml`:

```yaml
---
- name: Include directory creation tasks
  include_tasks: directories.yml

- name: Display environment info
  debug:
    msg:
      - "Home: {{ ansible_env.HOME }}"
      - "User: {{ ansible_env.USER }}"
      - "OS Family: {{ ansible_os_family }}"
      - "Is WSL: {{ is_wsl | default(false) }}"
      - "Is macOS: {{ is_macos | default(false) }}"
```

**Step 5: Test common role**

Run:

```bash
ansible-playbook playbook.yml --tags common --check --diff
```

Expected: Shows directory creation tasks

**Step 6: Commit**

```bash
git add roles/common/
git commit -m "feat: add common role with directory structure"
```

---

## Task 5: Common Role - Package Installation

**Files:**
- Create: `roles/common/tasks/packages-debian.yml`
- Create: `roles/common/tasks/packages-darwin.yml`
- Modify: `roles/common/tasks/main.yml`

**Step 1: Create Debian package tasks**

Create `roles/common/tasks/packages-debian.yml`:

```yaml
---
- name: Update apt cache
  apt:
    update_cache: true
    cache_valid_time: 3600
  become: true
  when: install_packages | bool

- name: Install base packages (Debian/Ubuntu)
  apt:
    name:
      - git
      - curl
      - wget
      - tree
      - build-essential
    state: present
  become: true
  when: install_packages | bool
```

**Step 2: Create macOS package tasks**

Create `roles/common/tasks/packages-darwin.yml`:

```yaml
---
- name: Check if Homebrew is installed
  stat:
    path: /opt/homebrew/bin/brew
  register: homebrew_check
  when: install_packages | bool

- name: Install Homebrew
  shell: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  when:
    - install_packages | bool
    - not homebrew_check.stat.exists

- name: Install base packages (macOS)
  homebrew:
    name:
      - git
      - curl
      - wget
      - tree
    state: present
  when: install_packages | bool
```

**Step 3: Update main tasks to include package installation**

Modify `roles/common/tasks/main.yml` to add before the debug task:

```yaml
- name: Include Debian package tasks
  include_tasks: packages-debian.yml
  when: ansible_os_family == "Debian"

- name: Include macOS package tasks
  include_tasks: packages-darwin.yml
  when: is_macos | default(false)
```

**Step 4: Test package installation tasks**

Run:

```bash
ansible-playbook playbook.yml --tags common --check --diff
```

Expected: Shows package installation tasks for current OS

**Step 5: Commit**

```bash
git add roles/common/
git commit -m "feat: add package installation to common role"
```

---

## Task 6: Common Role - WSL Configuration

**Files:**
- Create: `roles/common/tasks/wsl-config.yml`
- Modify: `roles/common/tasks/main.yml`

**Step 1: Create WSL configuration tasks**

Create `roles/common/tasks/wsl-config.yml`:

```yaml
---
- name: Detect WSL host IP
  shell: ip route | grep default | awk '{print $3}'
  register: wsl_host_ip_result
  changed_when: false
  when: is_wsl | default(false)

- name: Set WSL host IP fact
  set_fact:
    wsl_host_ip: "{{ wsl_host_ip_result.stdout }}"
  when:
    - is_wsl | default(false)
    - wsl_host_ip_result.stdout is defined

- name: Set WSL display fact
  set_fact:
    wsl_display: "{{ wsl_host_ip }}:0"
  when:
    - is_wsl | default(false)
    - wsl_host_ip is defined

- name: Display WSL configuration
  debug:
    msg:
      - "WSL Host IP: {{ wsl_host_ip | default('N/A') }}"
      - "WSL Display: {{ wsl_display | default('N/A') }}"
  when: is_wsl | default(false)
```

**Step 2: Add WSL config to main tasks**

Add to `roles/common/tasks/main.yml` after package tasks:

```yaml
- name: Configure WSL environment
  include_tasks: wsl-config.yml
  when: is_wsl | default(false)
```

**Step 3: Test WSL configuration (if on WSL)**

Run:

```bash
ansible-playbook playbook.yml --tags common --check --diff
```

Expected: WSL tasks run only on WSL systems

**Step 4: Commit**

```bash
git add roles/common/
git commit -m "feat: add WSL-specific configuration to common role"
```

---

## Task 7: Shell Role - Directory Structure

**Files:**
- Create: `roles/shell/tasks/main.yml`
- Create: `roles/shell/vars/main.yml`
- Create: `roles/shell/tasks/install-packages.yml`

**Step 1: Create role directory structure**

```bash
mkdir -p roles/shell/{tasks,vars,templates,files}
```

**Step 2: Create role variables**

Create `roles/shell/vars/main.yml`:

```yaml
---
oh_my_zsh_install_script: "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
powerlevel10k_repo: "https://github.com/romkatv/powerlevel10k.git"
powerlevel10k_dest: "{{ oh_my_zsh_custom }}/themes/powerlevel10k"

zsh_plugins:
  - git
  - ag
  - z

debian_packages:
  - zsh
  - exa
  - bat
  - silversearcher-ag
  - fzf

darwin_packages:
  - zsh
  - exa
  - bat
  - the_silver_searcher
  - fzf
```

**Step 3: Create package installation tasks**

Create `roles/shell/tasks/install-packages.yml`:

```yaml
---
- name: Install shell packages (Debian/Ubuntu)
  apt:
    name: "{{ debian_packages }}"
    state: present
  become: true
  when:
    - install_packages | bool
    - ansible_os_family == "Debian"

- name: Install shell packages (macOS)
  homebrew:
    name: "{{ darwin_packages }}"
    state: present
  when:
    - install_packages | bool
    - is_macos | default(false)
```

**Step 4: Create main tasks file**

Create `roles/shell/tasks/main.yml`:

```yaml
---
- name: Install shell packages
  include_tasks: install-packages.yml
  tags: packages
```

**Step 5: Test shell role**

Run:

```bash
ansible-playbook playbook.yml --tags shell --check --diff
```

Expected: Shows package installation tasks

**Step 6: Commit**

```bash
git add roles/shell/
git commit -m "feat: add shell role with package installation"
```

---

## Task 8: Shell Role - Oh-My-Zsh Installation

**Files:**
- Create: `roles/shell/tasks/oh-my-zsh.yml`
- Modify: `roles/shell/tasks/main.yml`

**Step 1: Create oh-my-zsh installation tasks**

Create `roles/shell/tasks/oh-my-zsh.yml`:

```yaml
---
- name: Check if oh-my-zsh is installed
  stat:
    path: "{{ oh_my_zsh_dir }}"
  register: oh_my_zsh_stat

- name: Download oh-my-zsh installer
  get_url:
    url: "{{ oh_my_zsh_install_script }}"
    dest: /tmp/install-oh-my-zsh.sh
    mode: "0755"
  when: not oh_my_zsh_stat.stat.exists

- name: Install oh-my-zsh
  shell: sh /tmp/install-oh-my-zsh.sh --unattended
  args:
    creates: "{{ oh_my_zsh_dir }}"
  environment:
    RUNZSH: "no"
    CHSH: "no"

- name: Remove oh-my-zsh installer
  file:
    path: /tmp/install-oh-my-zsh.sh
    state: absent

- name: Check if powerlevel10k is installed
  stat:
    path: "{{ powerlevel10k_dest }}"
  register: p10k_stat

- name: Clone powerlevel10k theme
  git:
    repo: "{{ powerlevel10k_repo }}"
    dest: "{{ powerlevel10k_dest }}"
    depth: 1
  when: not p10k_stat.stat.exists
```

**Step 2: Add oh-my-zsh to main tasks**

Add to `roles/shell/tasks/main.yml`:

```yaml
- name: Install and configure oh-my-zsh
  include_tasks: oh-my-zsh.yml
```

**Step 3: Test oh-my-zsh installation**

Run:

```bash
ansible-playbook playbook.yml --tags shell --check --diff
```

Expected: Shows oh-my-zsh installation tasks

**Step 4: Commit**

```bash
git add roles/shell/
git commit -m "feat: add oh-my-zsh and powerlevel10k installation"
```

---

## Task 9: Shell Role - Zsh Configuration

**Files:**
- Create: `roles/shell/tasks/configure-zsh.yml`
- Modify: `roles/shell/tasks/main.yml`

**Step 1: Create zsh configuration tasks**

Create `roles/shell/tasks/configure-zsh.yml`:

```yaml
---
- name: Symlink .zshrc
  file:
    src: "{{ dotfiles_dir }}/.zshrc"
    dest: "{{ ansible_env.HOME }}/.zshrc"
    state: link
    force: true

- name: Check current shell
  shell: echo $SHELL
  register: current_shell
  changed_when: false

- name: Get zsh path
  shell: which zsh
  register: zsh_path
  changed_when: false

- name: Change default shell to zsh
  shell: chsh -s {{ zsh_path.stdout }}
  when: default_shell in zsh_path.stdout and current_shell.stdout != zsh_path.stdout
  become: true
```

**Step 2: Add zsh configuration to main tasks**

Add to `roles/shell/tasks/main.yml`:

```yaml
- name: Configure zsh
  include_tasks: configure-zsh.yml
  tags: configs
```

**Step 3: Test zsh configuration**

Run:

```bash
ansible-playbook playbook.yml --tags shell --check --diff
```

Expected: Shows symlink and shell change tasks

**Step 4: Commit**

```bash
git add roles/shell/
git commit -m "feat: add zsh configuration and symlinking"
```

---

## Task 10: Tmux Role

**Files:**
- Create: `roles/tmux/tasks/main.yml`
- Create: `roles/tmux/vars/main.yml`

**Step 1: Create role directory structure**

```bash
mkdir -p roles/tmux/{tasks,vars}
```

**Step 2: Create role variables**

Create `roles/tmux/vars/main.yml`:

```yaml
---
tmux_package_debian: tmux
tmux_package_darwin: tmux
```

**Step 3: Create main tasks**

Create `roles/tmux/tasks/main.yml`:

```yaml
---
- name: Install tmux (Debian/Ubuntu)
  apt:
    name: "{{ tmux_package_debian }}"
    state: present
  become: true
  when:
    - install_packages | bool
    - ansible_os_family == "Debian"
  tags: packages

- name: Install tmux (macOS)
  homebrew:
    name: "{{ tmux_package_darwin }}"
    state: present
  when:
    - install_packages | bool
    - is_macos | default(false)
  tags: packages

- name: Symlink .tmux.conf
  file:
    src: "{{ dotfiles_dir }}/.tmux.conf"
    dest: "{{ ansible_env.HOME }}/.tmux.conf"
    state: link
    force: true
  tags: configs

- name: Verify tmux installation
  command: tmux -V
  register: tmux_version
  changed_when: false
  failed_when: false

- name: Display tmux version
  debug:
    msg: "Tmux version: {{ tmux_version.stdout }}"
  when: tmux_version.rc == 0
```

**Step 4: Test tmux role**

Run:

```bash
ansible-playbook playbook.yml --tags tmux --check --diff
```

Expected: Shows tmux installation and configuration tasks

**Step 5: Commit**

```bash
git add roles/tmux/
git commit -m "feat: add tmux role with installation and configuration"
```

---

## Task 11: Neovim Role - Package Installation

**Files:**
- Create: `roles/neovim/tasks/main.yml`
- Create: `roles/neovim/tasks/install-packages.yml`
- Create: `roles/neovim/vars/main.yml`

**Step 1: Create role directory structure**

```bash
mkdir -p roles/neovim/{tasks,vars,files}
```

**Step 2: Create role variables**

Create `roles/neovim/vars/main.yml`:

```yaml
---
vim_plug_url: "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
vim_plug_dest: "{{ ansible_env.HOME }}/.local/share/nvim/site/autoload/plug.vim"

debian_packages:
  - neovim
  - python3-pip
  - exuberant-ctags

darwin_packages:
  - neovim
  - ctags-exuberant

python_packages:
  - pynvim
  - neovim
```

**Step 3: Create package installation tasks**

Create `roles/neovim/tasks/install-packages.yml`:

```yaml
---
- name: Install neovim packages (Debian/Ubuntu)
  apt:
    name: "{{ debian_packages }}"
    state: present
  become: true
  when:
    - install_packages | bool
    - ansible_os_family == "Debian"

- name: Install neovim packages (macOS)
  homebrew:
    name: "{{ darwin_packages }}"
    state: present
  when:
    - install_packages | bool
    - is_macos | default(false)

- name: Install Python packages for neovim
  pip:
    name: "{{ python_packages }}"
    state: present
    extra_args: --user
  when: install_packages | bool
```

**Step 4: Create main tasks**

Create `roles/neovim/tasks/main.yml`:

```yaml
---
- name: Install neovim and dependencies
  include_tasks: install-packages.yml
  tags: packages
```

**Step 5: Test neovim package installation**

Run:

```bash
ansible-playbook playbook.yml --tags neovim --check --diff
```

Expected: Shows neovim package installation tasks

**Step 6: Commit**

```bash
git add roles/neovim/
git commit -m "feat: add neovim role with package installation"
```

---

## Task 12: Neovim Role - Configuration

**Files:**
- Create: `roles/neovim/tasks/configure-vim.yml`
- Modify: `roles/neovim/tasks/main.yml`

**Step 1: Create vim configuration tasks**

Create `roles/neovim/tasks/configure-vim.yml`:

```yaml
---
- name: Create vim-plug directory
  file:
    path: "{{ vim_plug_dest | dirname }}"
    state: directory
    mode: "0755"

- name: Download vim-plug
  get_url:
    url: "{{ vim_plug_url }}"
    dest: "{{ vim_plug_dest }}"
    mode: "0644"

- name: Sync .vim directory
  synchronize:
    src: "{{ dotfiles_dir }}/.vim/"
    dest: "{{ vim_dir }}/"
    delete: false
    recursive: true
  delegate_to: localhost

- name: Ensure .vim/core directory exists
  file:
    path: "{{ vim_dir }}/core"
    state: directory
    mode: "0755"

- name: Install vim plugins
  shell: nvim --headless +PlugInstall +qall
  args:
    creates: "{{ vim_dir }}/plugged"
  when: neovim_install_plugins | bool
  failed_when: false
  register: plug_install_result

- name: Display plugin installation result
  debug:
    msg: "Vim plugins installation: {{ 'Success' if plug_install_result.rc == 0 else 'Manual run may be needed' }}"
  when: neovim_install_plugins | bool
```

**Step 2: Add configuration to main tasks**

Add to `roles/neovim/tasks/main.yml`:

```yaml
- name: Configure neovim
  include_tasks: configure-vim.yml
  tags: configs
```

**Step 3: Test neovim configuration**

Run:

```bash
ansible-playbook playbook.yml --tags neovim --check --diff
```

Expected: Shows vim configuration tasks

**Step 4: Commit**

```bash
git add roles/neovim/
git commit -m "feat: add neovim configuration and plugin installation"
```

---

## Task 13: IdeaVim Role

**Files:**
- Create: `roles/ideavim/tasks/main.yml`
- Create: `roles/ideavim/vars/main.yml`

**Step 1: Create role directory structure**

```bash
mkdir -p roles/ideavim/{tasks,vars}
```

**Step 2: Create role variables**

Create `roles/ideavim/vars/main.yml`:

```yaml
---
ideavimrc_source: "{{ dotfiles_dir }}/ideavim/.ideavimrc"
ideavimrc_dest: "{{ ansible_env.HOME }}/.ideavimrc"

required_plugins:
  - IdeaVim
  - IdeaVim-Quickscope
  - IdeaVim-EasyMotion
  - IdeaVimExtension
  - IdeaVimMulticursor
  - Which-Key
```

**Step 3: Create main tasks**

Create `roles/ideavim/tasks/main.yml`:

```yaml
---
- name: Symlink .ideavimrc
  file:
    src: "{{ ideavimrc_source }}"
    dest: "{{ ideavimrc_dest }}"
    state: link
    force: true

- name: Display WSL Windows symlink instructions
  debug:
    msg:
      - "WSL MANUAL STEP REQUIRED:"
      - "To use IdeaVim config in Windows IntelliJ from WSL, run this command in Windows cmd.exe (as Administrator):"
      - "mklink C:\\Users\\<windows-user>\\.ideavimrc \\\\wsl$\\<wsl2-distro>{{ ideavimrc_dest }}"
      - ""
      - "Required IntelliJ Plugins:"
      - "{{ required_plugins | join(', ') }}"
  when: is_wsl | default(false)

- name: Display required plugins (macOS)
  debug:
    msg:
      - "Required IntelliJ Plugins:"
      - "{{ required_plugins | join(', ') }}"
  when: is_macos | default(false)
```

**Step 4: Test ideavim role**

Run:

```bash
ansible-playbook playbook.yml --tags ideavim --check --diff
```

Expected: Shows symlink task and plugin instructions

**Step 5: Commit**

```bash
git add roles/ideavim/
git commit -m "feat: add ideavim role with configuration symlinking"
```

---

## Task 14: Bin-Utils Role

**Files:**
- Create: `roles/bin-utils/tasks/main.yml`
- Create: `roles/bin-utils/vars/main.yml`

**Step 1: Create role directory structure**

```bash
mkdir -p roles/bin-utils/{tasks,vars}
```

**Step 2: Create role variables**

Create `roles/bin-utils/vars/main.yml`:

```yaml
---
bin_scripts_source: "{{ dotfiles_dir }}/bin"
bin_scripts_dest: "{{ bin_dir }}"
```

**Step 3: Create main tasks**

Create `roles/bin-utils/tasks/main.yml`:

```yaml
---
- name: Ensure bin directory exists
  file:
    path: "{{ bin_scripts_dest }}"
    state: directory
    mode: "0755"

- name: Find all bin scripts
  find:
    paths: "{{ bin_scripts_source }}"
    file_type: file
  register: bin_scripts
  delegate_to: localhost

- name: Symlink bin scripts
  file:
    src: "{{ item.path }}"
    dest: "{{ bin_scripts_dest }}/{{ item.path | basename }}"
    state: link
    force: true
  loop: "{{ bin_scripts.files }}"

- name: Make bin scripts executable
  file:
    path: "{{ bin_scripts_dest }}/{{ item.path | basename }}"
    mode: "0755"
  loop: "{{ bin_scripts.files }}"

- name: Verify bin directory in PATH
  shell: echo $PATH | grep -q "{{ bin_scripts_dest }}"
  register: path_check
  changed_when: false
  failed_when: false

- name: Display PATH warning if needed
  debug:
    msg:
      - "WARNING: {{ bin_scripts_dest }} is not in PATH"
      - "Add this to your shell configuration:"
      - "export PATH=\"{{ bin_scripts_dest }}:$PATH\""
  when: path_check.rc != 0
```

**Step 4: Test bin-utils role**

Run:

```bash
ansible-playbook playbook.yml --tags bin-utils --check --diff
```

Expected: Shows bin script symlinking tasks

**Step 5: Commit**

```bash
git add roles/bin-utils/
git commit -m "feat: add bin-utils role for custom script management"
```

---

## Task 15: WordPress Role

**Files:**
- Create: `roles/wordpress/tasks/main.yml`
- Create: `roles/wordpress/vars/main.yml`

**Step 1: Create role directory structure**

```bash
mkdir -p roles/wordpress/{tasks,vars}
```

**Step 2: Create role variables**

Create `roles/wordpress/vars/main.yml`:

```yaml
---
mu_plugins_source: "{{ dotfiles_dir }}/wordpress/mu-plugins"
mu_plugins_dest: "{{ wordpress_dev_path }}/mu-plugins"
```

**Step 3: Create main tasks**

Create `roles/wordpress/tasks/main.yml`:

```yaml
---
- name: Check if WordPress dev path is configured
  debug:
    msg: "WordPress dev path: {{ wordpress_dev_path }}"

- name: Ensure WordPress mu-plugins directory exists
  file:
    path: "{{ mu_plugins_dest }}"
    state: directory
    mode: "0755"
  when:
    - wordpress_dev_path is defined
    - wordpress_dev_path != ""

- name: Find mu-plugins
  find:
    paths: "{{ mu_plugins_source }}"
    patterns: "*.php"
  register: mu_plugins
  delegate_to: localhost
  when:
    - wordpress_dev_path is defined
    - wordpress_dev_path != ""

- name: Symlink mu-plugins
  file:
    src: "{{ item.path }}"
    dest: "{{ mu_plugins_dest }}/{{ item.path | basename }}"
    state: link
    force: true
  loop: "{{ mu_plugins.files }}"
  when:
    - wordpress_dev_path is defined
    - wordpress_dev_path != ""
    - mu_plugins.files is defined

- name: Display mu-plugins installed
  debug:
    msg: "Installed {{ mu_plugins.files | length }} mu-plugins to {{ mu_plugins_dest }}"
  when:
    - wordpress_dev_path is defined
    - wordpress_dev_path != ""
    - mu_plugins.files is defined
```

**Step 4: Test wordpress role**

Run:

```bash
ansible-playbook playbook.yml --tags wordpress --check --diff
```

Expected: Shows WordPress mu-plugin tasks (or skips if path not set)

**Step 5: Commit**

```bash
git add roles/wordpress/
git commit -m "feat: add wordpress role for mu-plugins management"
```

---

## Task 16: README Documentation

**Files:**
- Modify: `README.md`

**Step 1: Add Ansible installation section**

Add to `README.md` after the existing overview:

```markdown
## Quick Start (Ansible)

### Prerequisites

- Ansible 2.9 or higher
- Git
- sudo access (for package installation)

### Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. Run the Ansible playbook:
   ```bash
   ansible-playbook playbook.yml
   ```

3. For WSL users: Manually create Windows symlink for IdeaVim (see output for command)

### Selective Installation

Install only specific components using tags:

```bash
# Only shell configuration
ansible-playbook playbook.yml --tags shell

# Shell and tmux
ansible-playbook playbook.yml --tags shell,tmux

# Everything except WordPress
ansible-playbook playbook.yml --skip-tags wordpress

# Config files only (no packages)
ansible-playbook playbook.yml --skip-tags packages
```

### Customization

Edit variables in `group_vars/all.yml`:

```yaml
wordpress_dev_path: "{{ ansible_env.HOME }}/wordpress-dev"  # Or "" to skip
install_packages: true           # Set false for config-only
neovim_install_plugins: true    # Auto-run :PlugInstall
default_shell: /bin/zsh
```

## Manual Installation (Legacy)

<existing manual installation documentation>
```

**Step 2: Verify README syntax**

Run:

```bash
cat README.md | head -100
```

Expected: No markdown syntax errors

**Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add Ansible installation instructions to README"
```

---

## Task 17: Testing and Verification

**Files:**
- Create: `test-playbook.sh`

**Step 1: Create test script**

Create `test-playbook.sh`:

```bash
#!/usr/bin/env bash

set -e

echo "=== Ansible Dotfiles Test Suite ==="
echo

echo "1. Syntax check..."
ansible-playbook playbook.yml --syntax-check
echo "✓ Syntax OK"
echo

echo "2. Dry run (check mode)..."
ansible-playbook playbook.yml --check --diff | tee /tmp/ansible-check.log
echo "✓ Dry run complete"
echo

echo "3. Verify role structure..."
for role in common shell tmux neovim ideavim bin-utils wordpress; do
  if [ -d "roles/$role/tasks" ]; then
    echo "✓ Role $role exists"
  else
    echo "✗ Role $role missing"
    exit 1
  fi
done
echo

echo "4. Verify group_vars..."
for varfile in all darwin wsl; do
  if [ -f "group_vars/${varfile}.yml" ]; then
    echo "✓ group_vars/${varfile}.yml exists"
  else
    echo "✗ group_vars/${varfile}.yml missing"
    exit 1
  fi
done
echo

echo "=== All tests passed ==="
```

**Step 2: Make script executable**

```bash
chmod +x test-playbook.sh
```

**Step 3: Run test script**

```bash
./test-playbook.sh
```

Expected: All tests pass

**Step 4: Add to .gitignore**

Add to `.gitignore`:

```
# Test logs
/tmp/ansible-*.log
```

**Step 5: Commit**

```bash
git add test-playbook.sh .gitignore
git commit -m "test: add playbook testing script"
```

---

## Task 18: Final Integration Test

**Files:**
- None (testing only)

**Step 1: Run full playbook in check mode**

Run:

```bash
ansible-playbook playbook.yml --check --diff 2>&1 | tee /tmp/full-check.log
```

Expected: No errors, shows all tasks that would run

**Step 2: Verify all roles are included**

```bash
grep -E "TASK \[" /tmp/full-check.log | grep -oE "\[(.*?)\]" | sort -u
```

Expected: Shows all 7 roles (common, shell, tmux, neovim, ideavim, bin-utils, wordpress)

**Step 3: Test tag filtering**

```bash
ansible-playbook playbook.yml --tags configs --list-tasks
```

Expected: Shows only config-related tasks

**Step 4: Verify OS detection**

```bash
ansible-playbook playbook.yml --tags always -v | grep "Detected OS"
```

Expected: Shows correct OS detection

**Step 5: Document successful test**

Create note in commit message describing test results

---

## Task 19: Final Commit and Cleanup

**Files:**
- None (git operations only)

**Step 1: Review all changes**

```bash
git status
git log --oneline --graph --all -10
```

Expected: Clean working tree, logical commit history

**Step 2: Verify no uncommitted files**

```bash
git status --short
```

Expected: Empty output or only untracked files that should be ignored

**Step 3: Create final summary commit if needed**

If there are any remaining changes:

```bash
git add -A
git commit -m "chore: final cleanup and verification"
```

**Step 4: Tag the release**

```bash
git tag -a v1.0.0-ansible -m "Ansible automation complete - initial release"
```

**Step 5: Display summary**

```bash
echo "=== Ansible Dotfiles Implementation Complete ==="
echo
echo "Commits:"
git log --oneline ansible ^main
echo
echo "To use:"
echo "  ansible-playbook playbook.yml"
echo
echo "To test:"
echo "  ./test-playbook.sh"
```

---

## Post-Implementation Testing Checklist

After implementing all tasks, verify:

- [ ] Playbook runs without errors on WSL2
- [ ] Playbook runs without errors on macOS
- [ ] All symlinks point to correct source files
- [ ] Oh-my-zsh and powerlevel10k installed correctly
- [ ] Neovim plugins can be installed
- [ ] Tmux configuration loads without errors
- [ ] Bin scripts are executable and accessible
- [ ] WordPress mu-plugins symlinked (if path configured)
- [ ] IdeaVim config accessible
- [ ] Tag filtering works correctly
- [ ] Idempotency - second run shows no changes
- [ ] README documentation accurate

## Known Limitations

1. **IdeaVim Windows symlink**: Cannot be automated from WSL2, requires manual Windows command
2. **Shell change**: May require logout/login to take effect
3. **Vim plugins**: First-time installation may show warnings, but should succeed
4. **Homebrew**: macOS installation may require password input
5. **WSL X11**: Requires X server running on Windows host

## Future Enhancements

- Add Molecule tests for each role
- Create CI/CD pipeline with GitHub Actions
- Add backup role to preserve existing dotfiles
- Template-based dotfiles with variable substitution
- Support for additional Linux distributions (Fedora, Arch)
- Git global configuration role
- Python environment setup (pyenv, virtualenv)
