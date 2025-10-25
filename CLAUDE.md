# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository containing shell configurations, editor settings, and development utilities primarily focused on PHP/WordPress development with vim/neovim.

## Repository Structure

### Core Configuration Files

- **`.zshrc`**: Main zsh configuration with oh-my-zsh, powerlevel10k theme, and custom functions
- **`.tmux.conf`**: tmux configuration with custom prefix (`C-o`), vim-style navigation, and mouse support
- **`.vim/`**: Neovim configuration split across multiple files in `.vim/core/`:
  - `init.vim`: Main vim configuration entry point
  - `mappings.vim`: Custom key mappings (leader key is `,`)
  - `plugins.vim`: Plugin configuration
  - `autocmd.vim`: Auto commands
  - `vdebug.vim`: xdebug configuration
  - `filetypes.vim`: Filetype-specific settings

### Directories

- **`ideavim/`**: IdeaVim configuration for IntelliJ-based IDEs
  - `.ideavimrc`: Main configuration file
  - Setup requires symlinking to home directory

- **`wordpress/mu-plugins/`**: Must-use WordPress plugins for local development
  - `https-ssl-verify.php`: Disables SSL verification for local development
  - `lando-mailhog.php`: Configures PHPMailer to use Lando's MailHog
  - `show-plugin-directory-name.php`: Shows plugin directory names in WP admin

- **`bin/`**: Utility scripts
  - `gentags`: Generates ctags for PHP and JavaScript projects

## Shell Configuration

### Custom Git Worktree Functions

The `.zshrc` includes two important git worktree helper functions:

- **`gwa <branch-name>`**: Creates/checks out a git worktree and changes to it
  - Creates worktree in sibling directory with pattern: `../repo-name-branch-name`
  - Auto-detects if branch exists or needs to be created

- **`gwr [branch-name]`**: Removes a git worktree
  - Without args: removes current worktree and returns to main
  - With arg: removes specified worktree by branch name

### Key Aliases

- `pbcopy`: Maps to `~/bin/clip.sh` for clipboard operations
- `ls`: Aliased to `exa`
- `cat`: Aliased to `bat`
- `gsub`: `git submodule update --init --recursive --remote`
- `gwl`: `git worktree list`

### Environment Setup

- Uses oh-my-zsh with powerlevel10k theme
- Plugins: `ag`, `git`, `z`
- SSH agent auto-start configuration
- NVM for Node.js version management
- Conda for Python environment management
- PATH includes multiple custom directories in `~/git/`

## Vim/Neovim Configuration

### Key Plugins

Per README.md, the setup uses these vim plugins:

- **deoplete.nvim**: Auto-completion with phpactor support
- **fzf**: Fuzzy finder (mapped to `<C-p>`)
- **NERDTree**: File navigation (toggle: `<C-n>`)
- **tagbar**: File structure navigation (toggle: `<C-k><C-t>`)
- **vdebug**: Debugging/breakpoints using xdebug (`F2`-`F12` except `F8`)
- **undotree**: Visual undo tree (toggle: `F1`)
- **vim-tmux-navigator**: Seamless vim/tmux pane navigation (`<C-h/j/k/l>`)
- **vim-surround**: Surround text operations (e.g., `cs"'` changes `"` to `'`)
- **nerdcommenter**: Comment utility (`<leader>cc` comment, `<leader>cu` uncomment)

### Leader Key Mappings

Leader key is `,` (comma). Important mappings from `.vim/core/mappings.vim`:

- `<leader>b`: Go back to alternate buffer
- `<leader>L`: Toggle line numbers
- `<leader>t`: Open new tab
- `<leader>W`: Strip trailing whitespace
- `<leader><space>`: Clear search highlighting
- `<leader>d`: Jump to function definition
- `<Space>`: Toggle fold (normal mode) or create fold (visual mode)

### File Navigation

- Tags file locations: `./tags`, `tags`, `./.tags`, `.tags` (searches up directory tree)
- Generate tags using `~/bin/gentags` which excludes common directories (node_modules, vendor, tests)
- Split behavior: horizontal splits below, vertical splits right

## IdeaVim Configuration

The `.ideavimrc` file requires these IntelliJ plugins:
1. IdeaVim
2. IdeaVim-Quickscope
3. IdeaVim-EasyMotion
4. IdeaVimExtension
5. IdeaVimMulticursor
6. Which-Key

Setup on Windows requires symlinking via cmd.exe (as admin):
```
mklink C:\Users\<windows-user>\.ideavimrc \\wsl$\<wsl2-distro>\home\<linux-user>\git\dotfiles\ideavim\.ideavimrc
```

## WordPress Development

### Must-Use Plugins

The `wordpress/mu-plugins/` directory contains utilities for local WordPress development:

- **SSL verification bypass**: For working with self-signed certificates in local environments
- **MailHog integration**: Routes all emails to MailHog when using Lando
- **Plugin directory display**: Shows plugin folder names in admin (useful for debugging)

These files should be symlinked into a WordPress installation's `wp-content/mu-plugins/` directory for local development.

## tmux Configuration

### Key Changes from Defaults

- Prefix changed from `C-b` to `C-o`
- Split panes: `|` (vertical), `-` (horizontal)
- Reload config: `<prefix> r`
- Pane navigation: `C-h/j/k/l` (integrated with vim-tmux-navigator)
- Pane resizing:
  - Fine: `S-Left/Right/Down/Up` (Shift + arrows)
  - Coarse: `C-Left/Right/Down/Up` (Ctrl + arrows)
- Mouse support enabled
- Vi mode keybindings in copy mode
- New windows open in current pane's path

### Session Management

Per README.md, the author's terminal launch command creates/attaches to a `main` session:
```bash
/usr/bin/zsh -c "if ! tmux ls 2>/dev/null | grep -q -E '^main.*attached'; then tmux attach -t main || tmux new -s main; else /usr/bin/zsh; fi"
```

## Development Environment

This configuration is optimized for:
- PHP/WordPress development (phpactor, deoplete-phpactor, vdebug)
- WSL2 environment (X11 display forwarding, host IP for xdebug)
- Lando-based local WordPress development
- Go, Node.js, Python development (multiple language tools in PATH)

### Important Environment Variables

- `HOST_IP`: Auto-set for xdebug in WSL2 environments
- `DISPLAY`: Set for WSL2 GUI applications
- Editor: Set to `vim`
