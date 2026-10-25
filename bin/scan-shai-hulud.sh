#!/usr/bin/env bash
# scan-shai-hulud.sh
#
# Local scanner for the "Mini Shai-Hulud" supply-chain campaign
# (Socket, 2026-05-11+). Looks for the known IOCs from that advisory:
#   - filenames:    router_init.js, router_runtime.js, tanstack_runner.js,
#                   transformers.pyz; plus setup.mjs when found in .claude/
#                   or .vscode/ (config-dir drop)
#   - SHA256:       ab4fcad... (router_init/runtime), 2ec78d5... (tanstack_runner)
#   - strings:      filev2.getsession.org, git-tanstack.com
#   - npm pins:     @opensearch-project/opensearch @ 3.5.3/3.6.2/3.7.0/3.8.0,
#                   @squawk/mcp@0.9.5, @squawk/weather@0.5.10,
#                   @squawk/flightplan@0.5.6
#   - PyPI pins:    mistralai==2.4.6, guardrails-ai==0.10.1
#   - scope warns:  any installed @tanstack/*, @opensearch-project/*, @squawk/*
#                   (verify version against advisory)
#   - git authors:  claude@users.noreply.github.com, voicproducoes
#
# What it scans:
#   - AI-assistant config dirs (persistence targets):
#       ~/.claude, ~/.codex, ~/.config/opencode, ~/.cursor (+ user-data),
#       ~/.vscode (+ user-data, Insiders, Server), ~/.windsurf
#   - Any git-repo paths you supply: same IOC checks, plus npm/yarn/pnpm/bun
#     lockfile + node_modules inventory, Python lockfile + site-packages
#     inventory, and `git log` against attacker identities.
#
# Usage:
#   ./scan-shai-hulud.sh                          # prompts for repo paths
#   ./scan-shai-hulud.sh ~/Documents/GitHub ~/src # scans the supplied paths
#
# Reference: https://socket.dev/blog/tanstack-npm-packages-compromised-mini-shai-hulud-supply-chain-attack
#
# Safe to run: read-only, no network, no modifications. macOS + Linux.
# Exit code: 0 if clean, 1 if any IOC hit.

set -u

# ---- IOCs from the Socket advisory ---------------------------------------
BAD_HASHES=(
  "ab4fcadaec49c03278063dd269ea5eef82d24f2124a8e15d7b90f2fa8601266c"  # router_init.js / router_runtime.js
  "2ec78d556d696e208927cc503d48e4b5eb56b31abc2870c2ed2e98d6be27fc96"  # tanstack_runner.js
)
BAD_FILENAMES=(
  "router_init.js"
  "router_runtime.js"
  "tanstack_runner.js"
  "transformers.pyz"      # payload hosted on git-tanstack.com
)
BAD_STRINGS=(
  "filev2.getsession.org"
  "getsession.org"
  "git-tanstack.com"
  "router_init.js"
  "router_runtime.js"
  "tanstack_runner.js"
  "transformers.pyz"
)
# Files dropped specifically into .claude/ or .vscode/ that have generic names —
# only treated as IOCs when found inside those dirs (else false-positive-prone).
BAD_FILES_IN_AI_CONFIG=("setup.mjs")
BAD_GIT_IDENTITIES=(
  "claude@users.noreply.github.com"   # commit author spoof
  "voicproducoes"                     # GitHub account used by attacker
)
ATTACK_DATE="2026-05-10"  # one day before earliest reported compromise

# Known-compromised npm package@version combos. Add more as the advisory grows.
BAD_NPM_VERSIONS=(
  "@opensearch-project/opensearch@3.5.3"
  "@opensearch-project/opensearch@3.6.2"
  "@opensearch-project/opensearch@3.7.0"
  "@opensearch-project/opensearch@3.8.0"
  "@squawk/mcp@0.9.5"
  "@squawk/weather@0.5.10"
  "@squawk/flightplan@0.5.6"
)

# Known-compromised PyPI package==version combos.
BAD_PYPI_VERSIONS=(
  "mistralai==2.4.6"
  "guardrails-ai==0.10.1"
)

# npm package scopes flagged by the advisory. Any installed copy is warn-level
# so the user can verify the exact version against the advisory.
SUSPICIOUS_SCOPES=("@tanstack" "@opensearch-project" "@squawk")

# ---- portable sha256 -----------------------------------------------------
if command -v sha256sum >/dev/null 2>&1; then
  sha256() { sha256sum "$1" 2>/dev/null | awk '{print $1}'; }
elif command -v shasum >/dev/null 2>&1; then
  sha256() { shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'; }
else
  echo "ERROR: need sha256sum or shasum installed." >&2
  exit 2
fi

# ---- output helpers ------------------------------------------------------
RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YEL=$'\033[0;33m'; BOLD=$'\033[1m'; RST=$'\033[0m'
HIT_COUNT=0
WARN_COUNT=0
hit()  { echo "${RED}${BOLD}[HIT]${RST} $*"; HIT_COUNT=$((HIT_COUNT+1)); }
warn() { echo "${YEL}[warn]${RST} $*"; WARN_COUNT=$((WARN_COUNT+1)); }
ok()   { echo "${GREEN}[ ok ]${RST} $*"; }
info() { echo "[info] $*"; }
section() { echo; echo "${BOLD}== $* ==${RST}"; }

# ---- per-path scans ------------------------------------------------------
scan_filenames() {
  local root="$1"
  while IFS= read -r -d '' f; do
    hit "malicious filename: $f"
  done < <(find "$root" -type f \( -name "router_init.js" -o -name "tanstack_runner.js" \) -print0 2>/dev/null)
}

scan_hashes() {
  # Hash JS files >= 500KB (payload is ~2.3 MB). Cheap and catches renames.
  local root="$1"
  while IFS= read -r -d '' f; do
    local h
    h=$(sha256 "$f")
    [ -z "$h" ] && continue
    for bad in "${BAD_HASHES[@]}"; do
      if [ "$h" = "$bad" ]; then
        hit "SHA256 match ($bad): $f"
      fi
    done
  done < <(find "$root" -type f \( -name "*.js" -o -name "*.mjs" -o -name "*.cjs" \) -size +500k -print0 2>/dev/null)
}

scan_strings() {
  # Grep -l for exfil domain + telltale filenames in any text file under root.
  # -I skips binaries; -s suppresses unreadable-file warnings.
  # Exclusions avoid false positives in AI-assistant conversation transcripts
  # (which often quote IOCs verbatim) and in irrelevant runtime caches.
  local root="$1"
  for pat in "${BAD_STRINGS[@]}"; do
    while IFS= read -r f; do
      [ -n "$f" ] && hit "IOC string '$pat' in: $f"
    done < <(grep -rlIs \
      --exclude-dir=.git \
      --exclude-dir=projects \
      --exclude-dir=sessions \
      --exclude-dir=chats \
      --exclude-dir=log \
      --exclude-dir=logs \
      --exclude-dir=file-history \
      --exclude-dir=todos \
      --exclude-dir=telemetry \
      --exclude-dir=cache \
      --exclude-dir=paste-cache \
      --exclude-dir=session-env \
      --exclude-dir=shell-snapshots \
      --exclude-dir=memory \
      --exclude=history.jsonl \
      --exclude='*.jsonl' \
      "$pat" "$root" 2>/dev/null | head -50)
  done
}

scan_suspicious_installs() {
  # Walk node_modules for any package under SUSPICIOUS_SCOPES, then:
  #   - HIT  if name@version matches BAD_NPM_VERSIONS (known-compromised)
  #   - warn otherwise (advisory implicates the scope; user verifies version)
  local root="$1"
  local found=0
  for scope in "${SUSPICIOUS_SCOPES[@]}"; do
    while IFS= read -r -d '' scopedir; do
      found=1
      for pj in "$scopedir"/*/package.json; do
        [ -f "$pj" ] || continue
        local name version key
        name=$(grep -m1 '"name"' "$pj" | sed -E 's/.*"name":[[:space:]]*"([^"]+)".*/\1/')
        version=$(grep -m1 '"version"' "$pj" | sed -E 's/.*"version":[[:space:]]*"([^"]+)".*/\1/')
        key="${name}@${version}"
        local is_bad=0
        for bad in "${BAD_NPM_VERSIONS[@]}"; do
          [ "$key" = "$bad" ] && is_bad=1 && break
        done
        if [ "$is_bad" -eq 1 ]; then
          hit "compromised install: $key  ($pj)"
        else
          warn "suspicious-scope install: $key  ($pj)"
        fi
      done
    done < <(find "$root" -type d -name "$scope" -print0 2>/dev/null)
  done
  [ "$found" -eq 0 ] && info "no installs under suspicious scopes (${SUSPICIOUS_SCOPES[*]}) in $root"
}

scan_pypi_installs() {
  # pip writes <name>-<version>.dist-info dirs into site-packages. Hyphens in
  # the package name are normalized to underscores in the dist-info dir name.
  local root="$1"
  for bad in "${BAD_PYPI_VERSIONS[@]}"; do
    local name="${bad%%==*}" ver="${bad##*==}"
    local name_us="${name//-/_}"
    while IFS= read -r d; do
      [ -n "$d" ] && hit "compromised Python install: $bad  ($d)"
    done < <(find "$root" -type d \( -name "${name}-${ver}.dist-info" -o -name "${name_us}-${ver}.dist-info" \) 2>/dev/null)
  done
}

scan_lockfiles() {
  # Look for known-bad package@version pins inside lockfiles, before install
  # would even materialize them. Covers npm/yarn/pnpm/bun and Python tooling.
  local root="$1"

  # ---- npm-family lockfiles ----
  for bad in "${BAD_NPM_VERSIONS[@]}"; do
    # Literal "name@version" form (yarn.lock, pnpm-lock.yaml, bun.lock).
    while IFS= read -r lf; do
      [ -n "$lf" ] && hit "lockfile pins $bad: $lf"
    done < <(grep -rlIs \
      --include=package-lock.json \
      --include=npm-shrinkwrap.json \
      --include=yarn.lock \
      --include=pnpm-lock.yaml \
      --include=bun.lock \
      --exclude-dir=.git \
      --exclude-dir=node_modules \
      -F "$bad" "$root" 2>/dev/null)

    # npm package-lock.json format: path on one line, "version": "X.Y.Z" within
    # a few lines after. Catches the case the literal grep above misses.
    local pkg="${bad%@*}" ver="${bad##*@}"
    while IFS= read -r -d '' lf; do
      if awk -v pkg="$pkg" -v ver="$ver" '
        BEGIN { in_block=0 }
        $0 ~ "\"node_modules/" pkg "\"" { in_block=1; near=NR; next }
        in_block && NR-near<6 && /"version":/ {
          if ($0 ~ "\"" ver "\"") { found=1; exit }
        }
        in_block && /^[[:space:]]*\}/ { in_block=0 }
        END { exit (found?0:1) }
      ' "$lf" 2>/dev/null; then
        hit "lockfile pins ${pkg}@${ver} (npm format): $lf"
      fi
    done < <(find "$root" -type f \( -name package-lock.json -o -name npm-shrinkwrap.json \) -not -path "*/node_modules/*" -print0 2>/dev/null)
  done

  # ---- Python lockfiles / requirements ----
  for bad in "${BAD_PYPI_VERSIONS[@]}"; do
    while IFS= read -r lf; do
      [ -n "$lf" ] && hit "Python lockfile pins $bad: $lf"
    done < <(grep -rlIs \
      --include='requirements*.txt' \
      --include=Pipfile.lock \
      --include=poetry.lock \
      --include=uv.lock \
      --include=pyproject.toml \
      --exclude-dir=.git \
      --exclude-dir=node_modules \
      --exclude-dir=.venv \
      --exclude-dir=venv \
      -F "$bad" "$root" 2>/dev/null)
  done
}

scan_config_drops() {
  # Files dropped into .claude/ or .vscode/ that have generic names — restrict
  # the match to those parent dirs so we don't false-positive on legitimate
  # setup.mjs files elsewhere in the tree.
  local root="$1"
  for name in "${BAD_FILES_IN_AI_CONFIG[@]}"; do
    while IFS= read -r -d '' f; do
      case "$f" in
        */.claude/*|*/.vscode/*) hit "config-dir drop: $f" ;;
      esac
    done < <(find "$root" -type f -name "$name" -print0 2>/dev/null)
  done
}

scan_git_repo() {
  # Look for commits matching any spoofed attacker identity (author email or
  # author/committer name).
  local repo="$1"
  if [ -d "$repo/.git" ] || git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
    for bad in "${BAD_GIT_IDENTITIES[@]}"; do
      local matches
      matches=$(git -C "$repo" log --all --format="%H %ae %an %ce %cn %s" 2>/dev/null | grep -F "$bad" || true)
      if [ -n "$matches" ]; then
        hit "git history matches identity '$bad' in $repo:"
        echo "$matches" | sed 's/^/       /'
      fi
    done
  fi
}

scan_root() {
  local label="$1" root="$2"
  if [ ! -d "$root" ]; then
    info "skip $label (not present): $root"
    return
  fi
  section "$label  →  $root"
  scan_filenames "$root"
  scan_hashes "$root"
  scan_strings "$root"
  scan_config_drops "$root"
  scan_lockfiles "$root"
  scan_suspicious_installs "$root"
  scan_pypi_installs "$root"
}

# ---- the run -------------------------------------------------------------
echo "${BOLD}Mini Shai-Hulud local scanner${RST}"
echo "Read-only. No network. Reference:"
echo "  https://socket.dev/blog/tanstack-npm-packages-compromised-mini-shai-hulud-supply-chain-attack"

# Default config-dir targets (the malware persists into these).
scan_root "~/.claude"             "$HOME/.claude"
scan_root "~/.codex"              "$HOME/.codex"
scan_root "opencode (~/.config/opencode)" "$HOME/.config/opencode"
scan_root "VS Code (~/.vscode)"   "$HOME/.vscode"
scan_root "VS Code (user data)"   "$HOME/Library/Application Support/Code"
scan_root "VS Code Insiders"      "$HOME/.vscode-insiders"
scan_root "VS Code Server"        "$HOME/.vscode-server"
scan_root "Cursor (~/.cursor)"    "$HOME/.cursor"
scan_root "Cursor (user data)"    "$HOME/Library/Application Support/Cursor"
scan_root "Windsurf (~/.windsurf)" "$HOME/.windsurf"

# Repo locations: accept as CLI args, else prompt interactively.
section "Git repo locations"
REPO_ROOTS=()
if [ "$#" -gt 0 ]; then
  for arg in "$@"; do
    expanded="${arg/#\~/$HOME}"
    if [ ! -d "$expanded" ]; then
      echo "  (not a directory, skipping: $expanded)"
      continue
    fi
    REPO_ROOTS+=("$expanded")
  done
else
  echo "Enter paths to scan (one per line). Common examples:"
  echo "  ~/Documents/GitHub"
  echo "  ~/src"
  echo "  ~/code"
  echo "Leave blank and press Enter when done."
  while true; do
    printf "  path> "
    IFS= read -r line || break
    [ -z "$line" ] && break
    expanded="${line/#\~/$HOME}"
    if [ ! -d "$expanded" ]; then
      echo "    (not a directory, skipping: $expanded)"
      continue
    fi
    REPO_ROOTS+=("$expanded")
  done
fi

if [ "${#REPO_ROOTS[@]}" -eq 0 ]; then
  info "no repo paths supplied — skipping git/node_modules scans"
else
  for root in "${REPO_ROOTS[@]}"; do
    section "Repo root: $root"
    scan_filenames "$root"
    scan_hashes "$root"
    scan_config_drops "$root"
    scan_lockfiles "$root"
    scan_suspicious_installs "$root"
    scan_pypi_installs "$root"
    # Git history: walk down looking for .git dirs (covers nested repos /
    # monorepos with submodules).
    while IFS= read -r -d '' g; do
      scan_git_repo "$(dirname "$g")"
    done < <(find "$root" -maxdepth 6 -type d \( -name node_modules -o -name vendor \) -prune -o -type d -name ".git" -print0 2>/dev/null)
  done
fi

# ---- summary -------------------------------------------------------------
section "Summary"
if [ "$HIT_COUNT" -eq 0 ] && [ "$WARN_COUNT" -eq 0 ]; then
  ok "no indicators of compromise found"
elif [ "$HIT_COUNT" -eq 0 ]; then
  ok "no IOC hits, but $WARN_COUNT warning(s) above — review @tanstack versions against:"
  echo "       https://socket.dev/blog/tanstack-npm-packages-compromised-mini-shai-hulud-supply-chain-attack"
else
  echo "${RED}${BOLD}$HIT_COUNT IOC hit(s) and $WARN_COUNT warning(s).${RST}"
  echo "If any HIT lines appear above, treat the affected machine as compromised:"
  echo "  - rotate npm tokens, GitHub PATs, AWS creds, OIDC federation grants"
  echo "  - audit ~/.claude/ and ~/.vscode/ for unexpected files"
  echo "  - review git history for commits matching: ${BAD_GIT_IDENTITIES[*]}"
  echo "  - block .getsession.org and git-tanstack.com at your DNS resolver"
  exit 1
fi
