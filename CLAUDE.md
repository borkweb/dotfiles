# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this repo is

Public dotfiles for a macOS-first (Debian/WSL2 secondary) development environment,
applied with Ansible. Files mirror their location under `$HOME` where practical
(`.zshrc`, `.tmux.conf`, `.config/nvim/`, ...). Private or work-specific material
is **not** here; it lives in the sibling private repo `../dotfiles-keys` and is
linked in by the `private-dotfiles` role. When adding something, ask first whether it
belongs in the public repo at all.

## Layout

- `.zshrc` — zsh + oh-my-zsh (`git` plugin), Starship prompt, guarded PATH additions, version managers (nvm, bun, pnpm, rbenv). Ends by sourcing `~/.zshrc-local` then `~/.zshrc-secrets` if present. Keep it portable: `$HOME`, not `/Users/matt`; guard anything platform-specific.
- `.config/starship.toml` — prompt. `.config/cship.toml` — Claude Code statusline.
- `.tmux.conf` + `.tmux/{starship,.right,.center}.toml` — tmux with prefix `C-Space`; the status bar is rendered by `tmuxship` (cargo) from those three Starship configs.
- `.config/ghostty/config` — Ghostty terminal (only non-default settings).
- `.config/nvim/init.lua` + `lazy-lock.json` — Neovim (lazy.nvim). `.vimrc` — the same settings for plain vim via Vundle; git's `core.editor` is still `vim`.
- `.config/karabiner/karabiner.json` — Karabiner-Elements (Hyper key on Caps Lock, Alphabork layer). The whole directory is symlinked, so Karabiner's `automatic_backups/` and `assets/` are gitignored.
- `.gitignore_global` — global git excludes. `.gitconfig` is private.
- `bin/` — utility scripts symlinked into `~/bin`. `t`/`tc`/`tc-handler` (tmux session pickers and the launchd URL handler), `git-worktree-*`, `guild` (Guild Hall dev server), `gentags`. The role links whatever exists here and never removes stale entries from `~/bin`.
- `launchd/com.borkweb.tc-handler.plist.j2` — launch agent template for `tc-handler`.
- `wordpress/mu-plugins/` — local-dev must-use plugins; only linked when `wordpress_dev_path` is set.
- `ansible/` — see below. `setup.sh`, `setup/setup-{mac,ubuntu}.sh` — bootstrap Ansible on a fresh machine. `test-playbook.sh` — syntax check + dry run.

## Ansible

```bash
cd ansible && ansible-playbook playbook.yml            # everything
ansible-playbook playbook.yml --tags configs            # symlinks only
ansible-playbook playbook.yml -e install_packages=false
```

- `playbook.yml` detects macOS/WSL in `pre_tasks` and `include_vars` the matching `group_vars/{darwin,debian}.yml`. The inventory only has `localhost`, so group files are loaded explicitly rather than by group name.
- `group_vars/all.yml` — paths, `git_repositories`, `nvm_version`, `node_default_version`, `wordpress_dev_path` (empty = skip).
- `group_vars/darwin.yml` — `homebrew_taps`, `homebrew_packages` (mirrors `brew leaves`), `homebrew_cask_packages` (installed with `accept_external_apps` so manually installed apps don't fail the run).
- `group_vars/debian.yml` — `apt_packages`.
- Roles: `common` (dirs, packages, nvm/bun), `shell`, `tmux`, `editors`, `git`, `bin-utils`, `claude-code`, `macos` (Ghostty, Karabiner, launchd; `when: is_macos`), `git-repos`, `private-dotfiles`, `wordpress`.
- Symlink pattern: `file: state=link force=true` from `{{ repo_root }}`. When a *directory* is symlinked (`~/.config/nvim`, `~/.config/karabiner`) the role first moves an unmanaged real directory to `*.bak.<epoch>` because `file` refuses to replace a directory with a link.
- `private-dotfiles` stats each entry in `private_dotfiles` under `~/git/dotfiles-keys` and links only those that exist, then reports which vaulted files still need `./vault.sh decrypt`.

## Conventions

- Prefer `$HOME`/`{{ ansible_env.HOME }}` over absolute user paths.
- Guard optional tooling (`command -v`, `[ -d ... ]`) so `.zshrc` works on a machine missing it.
- Package lists should reflect what is actually installed; check `brew leaves` / `brew list --cask` before editing `darwin.yml`.
- Never add secrets, internal hostnames, tokens or employer-specific config here. Put them in `../dotfiles-keys` and, if the shell needs them, in `~/.zshrc-local` / `~/.zshrc-secrets`.
- Run `./test-playbook.sh` (or at least `ansible-playbook playbook.yml --syntax-check`) after touching `ansible/`.
