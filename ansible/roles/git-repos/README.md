# Git Repos Role

Clones and manages git repositories into `~/git` directory.

## Features

- Ensures git is installed
- Creates `~/git` directory if missing
- Clones specified repositories only if missing
- Skips repositories that already exist (no updates)
- Supports custom branches/tags

## Configuration

Define repositories in `ansible/group_vars/all.yml`:

```yaml
git_repositories:
  - repo: https://github.com/username/repo1.git
    dest: repo1
    version: main  # optional, defaults to HEAD (default branch)

  - repo: https://github.com/username/repo2.git
    dest: my-custom-name
    update: false  # optional, skip updates if already cloned

  - repo: git@github.com:username/private-repo.git
    dest: private-repo
    version: v1.0.0  # optional, clone specific tag/branch
```

## Parameters

Each repository entry supports:

- `repo` (required): Git repository URL (HTTPS or SSH)
- `dest` (required): Directory name under `~/git/`
- `version` (optional): Branch, tag, or commit to checkout (default: HEAD)

**Note:** Repositories are only cloned if they don't already exist. Existing repositories are left untouched to preserve local changes.

## Usage

Run with specific tag:
```bash
ansible-playbook playbook.yml --tags git-repos
```

Or include in full playbook run.

## Examples

### Clone multiple repos
```yaml
git_repositories:
  - repo: https://github.com/neovim/neovim.git
    dest: neovim

  - repo: https://github.com/tmux/tmux.git
    dest: tmux
```

### Private repos (SSH)
```yaml
git_repositories:
  - repo: git@github.com:mycompany/internal-tool.git
    dest: internal-tool
    version: develop
```

Note: Ensure SSH keys are configured for private repositories.
