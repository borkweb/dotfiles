# dotfiles

My development environment, reproducible with Ansible. Primary platform is macOS
(Apple Silicon); Debian/Ubuntu and WSL2 are still supported.

Anything personal, work-specific or secret lives in a separate private repo,
[dotfiles-keys](https://github.com/borkweb/dotfiles-keys), and is linked in by the
`private-dotfiles` role. See [Private configuration](#private-configuration).

## What's in here

| Area | Files | Notes |
|------|-------|-------|
| Shell | `.zshrc` | zsh + oh-my-zsh (`git` plugin only), prompt by [Starship](https://starship.rs). Sources `~/.zshrc-local` and `~/.zshrc-secrets` if present. |
| Prompt | `.config/starship.toml` | Two-line prompt migrated from Powerlevel10k. |
| tmux | `.tmux.conf`, `.tmux/*.toml` | Prefix `C-Space`. Status bar rendered by [tmuxship](https://github.com/Yukaii/tmuxship) using the Starship configs in `.tmux/`. |
| Terminal | `.config/ghostty/config` | Ghostty; only change is `Cmd+K` → `M-k` so the tmux agent-ask binding fires. |
| Editors | `.config/nvim/`, `.vimrc` | Neovim with [lazy.nvim](https://github.com/folke/lazy.nvim) (lockfile committed). `.vimrc` mirrors it with Vundle for plain vim, which git still invokes. |
| Keyboard | `.config/karabiner/karabiner.json` | Caps Lock as Hyper/Escape, Hyper+C opens Claude Desktop, Alphabork characters. |
| Git | `.gitignore_global` | Global ignores. `.gitconfig` itself is private (identity + signing). |
| Scripts | `bin/` | See [bin scripts](#bin-scripts). |
| Claude Code | `.config/cship.toml` | [cship](https://cship.dev) statusline config. `settings.json` and `CLAUDE.md` are private. |
| launchd | `launchd/` | `com.borkweb.tc-handler` watches `~/bin/.tc-trigger` and opens a tmux + Claude session. |
| WordPress | `wordpress/mu-plugins/` | Local-dev must-use plugins (SSL bypass, Mailhog mailer, plugin dir names). Opt in with `wordpress_dev_path`. |

### bin scripts

| Script | Purpose |
|--------|---------|
| `t` | fzf picker over `~/projects`, `~/git`, `~/sites` (and Claude worktrees) that opens or switches to a tmux session. |
| `tc` / `tc-handler` | `tc <project>` opens a tmux session with a `claude` window; `tc-handler` is the launchd side of the URL handler. |
| `git-worktree-add` / `git-worktree-remove` | Create or remove a sibling worktree (`../repo-branch`). |
| `guild` | Start, stop, or tail the Guild Hall dev server. |
| `gentags` | ctags for PHP/JS projects. |

## Quick start

Fresh machine (installs Command Line Tools / Homebrew / apt prerequisites, then Ansible, then runs the playbook):

```bash
git clone https://github.com/borkweb/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles
./setup.sh
```

Already have Ansible:

```bash
cd ~/git/dotfiles/ansible
ansible-playbook playbook.yml
```

Requires the `community.general` and `ansible.posix` collections (`ansible-galaxy collection install community.general ansible.posix`).

### Selective runs

```bash
ansible-playbook playbook.yml --tags shell,tmux          # just those roles
ansible-playbook playbook.yml --tags configs             # symlinks only, no installs
ansible-playbook playbook.yml --skip-tags packages       # everything except package installs
ansible-playbook playbook.yml -e install_packages=false  # same, via variable
./test-playbook.sh                                       # syntax check + dry run
```

### Roles

| Role | Tags | Does |
|------|------|------|
| `common` | `common` | Directories, Homebrew taps/formulae/casks (macOS) or apt packages (Debian), nvm + Node, bun, WSL env. |
| `shell` | `shell` | oh-my-zsh, Starship (upstream installer on Debian), links `.zshrc` and `starship.toml`, sets zsh as login shell. |
| `tmux` | `tmux` | Links `.tmux.conf` and `.tmux/*.toml`, installs tmuxship with cargo when rust is present. |
| `editors` | `editors` | Links `.vimrc` and `~/.config/nvim`, clones Vundle, restores neovim plugins from the lockfile. |
| `git` | `git` | Links `.gitignore_global`. |
| `bin-utils` | `bin-utils` | Links everything in `bin/` into `~/bin`. |
| `claude-code` | `claude-code` | Installs Claude Code, links `cship.toml`. |
| `macos` | `macos` | Ghostty config, Karabiner config, tc-handler launch agent. macOS only. |
| `git-repos` | `git-repos` | Clones the repos in `git_repositories` into `~/git` if missing. |
| `private-dotfiles` | `private` | Links files from `~/git/dotfiles-keys` into place when they exist. |
| `wordpress` | `wordpress` | Links mu-plugins into `wordpress_dev_path`. Skipped unless set. |

Package lists live in `ansible/group_vars/darwin.yml` (Homebrew) and `ansible/group_vars/debian.yml` (apt); other knobs are in `ansible/group_vars/all.yml`.

## Private configuration

`.zshrc` deliberately ends by sourcing two files that are not in this repo:

- `~/.zshrc-local` for machine- or employer-specific config (aliases, env vars, proxies)
- `~/.zshrc-secrets` for API keys and tokens

Those, plus `~/.gitconfig`, `~/.ssh/config`, Claude Code's `settings.json` and `CLAUDE.md`,
and work-only scripts, are kept in the private `dotfiles-keys` repo. Secrets there are
encrypted with `ansible-vault`; its `vault.sh` handles import, encrypt and decrypt. The
`private-dotfiles` role symlinks whatever has been decrypted and tells you what hasn't.

## Not automated

- `cship` (Claude Code statusline): install from https://cship.dev.
- Vundle plugins for plain vim: run `vim +PluginInstall +qall` once.
- Karabiner-Elements and Ghostty are installed as casks but need to be launched once to grant permissions.
