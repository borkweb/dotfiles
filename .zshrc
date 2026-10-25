# ~/.zshrc — managed in https://github.com/borkweb/dotfiles
#
# Machine- or work-specific additions live outside this file:
#   ~/.zshrc-local    non-secret, environment-specific config (sourced last)
#   ~/.zshrc-secrets  API keys and tokens (sourced last, never committed)

# ---------------------------------------------------------------------------
# PATH
# ---------------------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"
[ -d /opt/homebrew/opt/python@3.14/libexec/bin ] && export PATH="/opt/homebrew/opt/python@3.14/libexec/bin:$PATH"
[ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"

# ---------------------------------------------------------------------------
# Oh My Zsh (prompt is handled by Starship, so no theme)
# ---------------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git)
source "$ZSH/oh-my-zsh.sh"

# ---------------------------------------------------------------------------
# Aliases
# ---------------------------------------------------------------------------
alias gor="git push origin HEAD"
alias gorf="git push origin HEAD --force-with-lease"
alias ls="eza"
alias gi="git"
alias vi="nvim"
alias vim="nvim"
alias ccusage="npx ccusage claude monthly"
alias h="herdr"

# ---------------------------------------------------------------------------
# Homebrew + Starship prompt
# ---------------------------------------------------------------------------
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv zsh)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv zsh)"
elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
fi

command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# zoxide: defines `z` (jump) and `zi` (interactive jump)
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# ---------------------------------------------------------------------------
# Completions (extra fpath entries, then a single compinit)
# ---------------------------------------------------------------------------
[ -d "$HOME/.docker/completions" ] && fpath=("$HOME/.docker/completions" $fpath)
[ -d "$HOME/.grok/completions/zsh" ] && fpath=("$HOME/.grok/completions/zsh" $fpath)
autoload -Uz compinit && compinit -C

# ---------------------------------------------------------------------------
# Language runtimes and version managers
# ---------------------------------------------------------------------------
# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# bun
export BUN_INSTALL="$HOME/.bun"
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# pnpm
if [ "$(uname -s)" = "Darwin" ]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
fi
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# rbenv — shims so ruby/gem/bundle resolve to the rbenv-selected version
command -v rbenv >/dev/null 2>&1 && eval "$(rbenv init - zsh)"

# Google Cloud SDK
if [ -f "$HOME/git/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/git/google-cloud-sdk/path.zsh.inc"; fi
if [ -f "$HOME/git/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/git/google-cloud-sdk/completion.zsh.inc"; fi

# ---------------------------------------------------------------------------
# Tool-specific PATH additions (each guarded so the file is portable)
# ---------------------------------------------------------------------------
[ -d "$HOME/.lando/bin" ] && export PATH="$HOME/.lando/bin:$PATH"
[ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"
[ -d "$HOME/.lmstudio/bin" ] && export PATH="$PATH:$HOME/.lmstudio/bin"
[ -d "$HOME/.kimi-code/bin" ] && export PATH="$HOME/.kimi-code/bin:$PATH"
[ -d "$HOME/.grok/bin" ] && export PATH="$HOME/.grok/bin:$PATH"

# ---------------------------------------------------------------------------
# Local overrides and secrets (kept out of this repo)
# ---------------------------------------------------------------------------
[ -f "$HOME/.zshrc-local" ] && source "$HOME/.zshrc-local"
[ -f "$HOME/.zshrc-secrets" ] && source "$HOME/.zshrc-secrets"
