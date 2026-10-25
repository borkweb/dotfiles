#!/usr/bin/env bash
# Mini Shai-Hulud / TanStack worm: disarm gh-token-monitor BEFORE rotating tokens.
# Order: kill processes -> tear down persistence -> remove files -> scan IOCs -> report.
# Exit code: 0 if no IOC hits remain after cleanup, 1 if hits found.
# Reference: https://socket.dev/blog/tanstack-npm-packages-compromised-mini-shai-hulud-supply-chain-attack
set +e

# ---- IOCs from the Socket advisory (2026-05-11+) -------------------------
BAD_HASHES=(
  "ab4fcadaec49c03278063dd269ea5eef82d24f2124a8e15d7b90f2fa8601266c"  # router_init.js / router_runtime.js
  "2ec78d556d696e208927cc503d48e4b5eb56b31abc2870c2ed2e98d6be27fc96"  # tanstack_runner.js
)
BAD_FILENAMES=(
  "router_init.js"
  "router_runtime.js"
  "tanstack_runner.js"
  "transformers.pyz"
)
BAD_STRINGS=(
  "filev2.getsession.org"
  "getsession.org"
  "git-tanstack.com"
)
# Generic-named drops: only treated as IOCs when found inside an AI config dir.
BAD_FILES_IN_AI_CONFIG=("setup.mjs")
BAD_NPM_VERSIONS=(
  "@opensearch-project/opensearch@3.5.3"
  "@opensearch-project/opensearch@3.6.2"
  "@opensearch-project/opensearch@3.7.0"
  "@opensearch-project/opensearch@3.8.0"
  "@squawk/mcp@0.9.5"
  "@squawk/weather@0.5.10"
  "@squawk/flightplan@0.5.6"
)
BAD_PYPI_VERSIONS=(
  "mistralai==2.4.6"
  "guardrails-ai==0.10.1"
)
SUSPICIOUS_SCOPES=("@tanstack" "@opensearch-project" "@squawk")

# AI/IDE config dirs that the worm targets for persistence-via-extension.
AI_DIRS=(
  "$HOME/.claude"
  "$HOME/.codex"
  "$HOME/.config/opencode"
  "$HOME/.cursor"
  "$HOME/Library/Application Support/Cursor"
  "$HOME/.vscode"
  "$HOME/Library/Application Support/Code"
  "$HOME/.vscode-insiders"
  "$HOME/.vscode-server"
  "$HOME/.windsurf"
)

# ---- portable sha256 -----------------------------------------------------
if command -v sha256sum >/dev/null 2>&1; then
  sha256() { sha256sum "$1" 2>/dev/null | awk '{print $1}'; }
elif command -v shasum >/dev/null 2>&1; then
  sha256() { shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'; }
else
  sha256() { echo ""; }  # no hash tool — hash checks gracefully no-op
fi

# ---- output helpers (color only on TTY) ----------------------------------
if [ -t 1 ]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YEL=$'\033[0;33m'; BOLD=$'\033[1m'; RST=$'\033[0m'
else
  RED=""; GREEN=""; YEL=""; BOLD=""; RST=""
fi
HIT_COUNT=0
WARN_COUNT=0
hit()  { echo "${RED}${BOLD}[HIT]${RST} $*"; HIT_COUNT=$((HIT_COUNT+1)); }
warn() { echo "${YEL}[warn]${RST} $*"; WARN_COUNT=$((WARN_COUNT+1)); }
ok()   { echo "${GREEN}[ ok ]${RST} $*"; }

# ---- per-dir IOC scanners ------------------------------------------------
scan_filenames_in() {
  local root="$1"
  while IFS= read -r -d '' f; do
    hit "malicious filename: $f"
  done < <(find "$root" -type f \
    \( -name router_init.js -o -name router_runtime.js \
       -o -name tanstack_runner.js -o -name transformers.pyz \) -print0 2>/dev/null)
}

scan_hashes_in() {
  # Hash JS files >= 500KB (payload is ~2.3 MB). Cheap and catches renames.
  local root="$1"
  while IFS= read -r -d '' f; do
    local h
    h=$(sha256 "$f")
    [ -z "$h" ] && continue
    for bad in "${BAD_HASHES[@]}"; do
      [ "$h" = "$bad" ] && hit "SHA256 match ($bad): $f"
    done
  done < <(find "$root" -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.cjs' \) -size +500k -print0 2>/dev/null)
}

scan_strings_in() {
  # IOC string sweep. Exclusions match scan-shai-hulud.sh — skip conversation
  # transcripts and runtime caches that legitimately quote IOCs verbatim.
  local root="$1"
  for pat in "${BAD_STRINGS[@]}"; do
    while IFS= read -r f; do
      [ -n "$f" ] && hit "IOC string '$pat' in: $f"
    done < <(grep -rlIs \
      --exclude-dir=.git \
      --exclude-dir=projects \
      --exclude-dir=sessions \
      --exclude-dir=chats \
      --exclude-dir=log --exclude-dir=logs \
      --exclude-dir=file-history \
      --exclude-dir=todos \
      --exclude-dir=telemetry \
      --exclude-dir=cache --exclude-dir=paste-cache \
      --exclude-dir=session-env \
      --exclude-dir=shell-snapshots \
      --exclude-dir=memory \
      --exclude=history.jsonl \
      --exclude='*.jsonl' \
      "$pat" "$root" 2>/dev/null | head -50)
  done
}

scan_config_drops_in() {
  # setup.mjs (and similar generic names) only count as IOCs inside an AI config
  # dir. Since this function is only called against AI_DIRS, any match is in scope.
  local root="$1"
  for name in "${BAD_FILES_IN_AI_CONFIG[@]}"; do
    while IFS= read -r -d '' f; do
      hit "config-dir drop: $f"
    done < <(find "$root" -type f -name "$name" -print0 2>/dev/null)
  done
}

# ---- destructive cleanup phase -------------------------------------------
echo "=== Killing running watchdog processes ==="
pkill -9 -f gh-token-monitor 2>/dev/null
pkill -9 -f tanstack_runner 2>/dev/null
pkill -9 -f router_init 2>/dev/null

if [ "$(uname)" = "Darwin" ]; then
  echo "=== macOS: unloading LaunchAgent ==="
  launchctl bootout "gui/$(id -u)/com.user.gh-token-monitor" 2>/dev/null
  launchctl unload ~/Library/LaunchAgents/com.user.gh-token-monitor.plist 2>/dev/null
  rm -fv ~/Library/LaunchAgents/com.user.gh-token-monitor.plist
  # Disarm any sibling plists that match the worm patterns
  find ~/Library/LaunchAgents /Library/LaunchAgents -maxdepth 1 \
    \( -iname '*gh-token-monitor*' -o -iname '*tanstack*' \) -print0 2>/dev/null |
    while IFS= read -r -d '' plist; do
      label="$(basename "$plist" .plist)"
      echo "  disarming sibling: $plist (label: $label)"
      launchctl bootout "gui/$(id -u)/$label" 2>/dev/null
      launchctl unload "$plist" 2>/dev/null
      rm -fv "$plist"
    done
  echo "=== Scanning /Library/LaunchDaemons (system-level, root-owned) ==="
  sys_matches=$(find /Library/LaunchDaemons -maxdepth 1 \
    \( -iname '*gh-token-monitor*' -o -iname '*tanstack*' \) 2>/dev/null)
  if [ -n "$sys_matches" ]; then
    echo "$sys_matches"
    warn "system-level launchd plists — remove manually with sudo launchctl bootout system/<label> && sudo rm"
  else
    echo "  (no system daemons matching patterns)"
  fi
else
  echo "=== Linux: stopping & disabling systemd user unit ==="
  systemctl --user stop    gh-token-monitor.service 2>/dev/null
  systemctl --user disable gh-token-monitor.service 2>/dev/null
  rm -fv ~/.config/systemd/user/gh-token-monitor.service
  systemctl --user daemon-reload 2>/dev/null
  echo "=== Scanning system-level systemd units ==="
  sys_matches=$(systemctl list-unit-files 2>/dev/null | grep -E 'gh-token-monitor|tanstack')
  if [ -n "$sys_matches" ]; then
    echo "$sys_matches"
    warn "system-level systemd units — remove manually with sudo systemctl stop/disable && sudo rm"
  else
    echo "  (no system units matching patterns)"
  fi
fi

echo "=== Removing daemon support files ==="
rm -fv  ~/.local/bin/gh-token-monitor.sh
rm -rfv ~/.config/gh-token-monitor

# ---- IOC scan of AI/IDE config dirs --------------------------------------
echo "=== Scanning AI/IDE config dirs for IOC payloads ==="
scanned=0
for d in "${AI_DIRS[@]}"; do
  [ -d "$d" ] || continue
  scanned=1
  echo "  scanning: $d"
  scan_filenames_in "$d"
  scan_hashes_in "$d"
  scan_strings_in "$d"
  scan_config_drops_in "$d"
done
[ "$scanned" -eq 0 ] && echo "  (no AI/IDE config dirs present)"

# ---- shell rc re-trigger audit -------------------------------------------
echo "=== Auditing shell rc files for re-trigger lines ==="
rc_matches=$(grep -lE 'gh-token-monitor|tanstack_runner|router_init|router_runtime|filev2\.getsession\.org|git-tanstack\.com' \
  ~/.bashrc ~/.zshrc ~/.profile ~/.bash_profile ~/.config/fish/config.fish \
  2>/dev/null)
if [ -n "$rc_matches" ]; then
  while IFS= read -r f; do
    hit "shell rc contains IOC pattern: $f"
  done <<< "$rc_matches"
  echo "  ^ inspect & remove suspicious lines manually"
else
  echo "  (no matches in shell rc files)"
fi

# ---- global npm installs -------------------------------------------------
echo "=== Scanning global npm installs ==="
if command -v npm >/dev/null 2>&1; then
  npm_root=$(npm root -g 2>/dev/null)
  if [ -n "$npm_root" ] && [ -d "$npm_root" ]; then
    found=0
    for scope in "${SUSPICIOUS_SCOPES[@]}"; do
      while IFS= read -r -d '' scopedir; do
        found=1
        for pj in "$scopedir"/*/package.json; do
          [ -f "$pj" ] || continue
          name=$(grep -m1 '"name"' "$pj" | sed -E 's/.*"name":[[:space:]]*"([^"]+)".*/\1/')
          version=$(grep -m1 '"version"' "$pj" | sed -E 's/.*"version":[[:space:]]*"([^"]+)".*/\1/')
          key="${name}@${version}"
          is_bad=0
          for bad in "${BAD_NPM_VERSIONS[@]}"; do
            [ "$key" = "$bad" ] && is_bad=1 && break
          done
          if [ "$is_bad" -eq 1 ]; then
            hit "compromised global install: $key  ($pj)"
          else
            warn "suspicious-scope global install: $key  ($pj)"
          fi
        done
      done < <(find "$npm_root" -maxdepth 2 -type d -name "$scope" -print0 2>/dev/null)
    done
    [ "$found" -eq 0 ] && echo "  (no globally-installed packages under ${SUSPICIOUS_SCOPES[*]})"
  else
    echo "  (npm root -g not found; skipping)"
  fi
else
  echo "  (npm not installed; skipping)"
fi

# ---- user/system pip installs --------------------------------------------
echo "=== Scanning user/system Python site-packages ==="
PY_ROOTS=()
[ -d "$HOME/.local/lib" ] && PY_ROOTS+=("$HOME/.local/lib")
for prefix in /opt/homebrew/lib /usr/local/lib /usr/lib; do
  [ -d "$prefix" ] && PY_ROOTS+=("$prefix")
done
if [ "${#PY_ROOTS[@]}" -eq 0 ]; then
  echo "  (no python site-packages roots found)"
else
  pyfound=0
  for bad in "${BAD_PYPI_VERSIONS[@]}"; do
    name="${bad%%==*}"; ver="${bad##*==}"
    name_us="${name//-/_}"
    for root in "${PY_ROOTS[@]}"; do
      while IFS= read -r d; do
        [ -n "$d" ] && hit "compromised Python install: $bad  ($d)" && pyfound=1
      done < <(find "$root" -type d \
        \( -name "${name}-${ver}.dist-info" -o -name "${name_us}-${ver}.dist-info" \) \
        2>/dev/null)
    done
  done
  [ "$pyfound" -eq 0 ] && echo "  (no compromised python installs in user/system site-packages)"
fi

# ---- final process verification ------------------------------------------
echo "=== Confirming nothing is still running ==="
pgrep -af gh-token-monitor || echo "  (no gh-token-monitor processes)"
pgrep -af tanstack_runner  || echo "  (no tanstack_runner processes)"
pgrep -af router_init      || echo "  (no router_init processes)"

# ---- summary -------------------------------------------------------------
echo
echo "${BOLD}== Summary ==${RST}"
if [ "$HIT_COUNT" -eq 0 ] && [ "$WARN_COUNT" -eq 0 ]; then
  ok "no IOCs found after cleanup"
  echo
  echo "Done. Watchdog disarmed. NOW safe to rotate: GitHub PATs, npm tokens,"
  echo "AWS/GCP/Azure keys, Kubernetes SA tokens, Vault tokens, SSH keys, ~/.npmrc."
  echo
  echo "For per-repo lockfile + node_modules + git-history scanning, run:"
  echo "  scan-shai-hulud.sh ~/path/to/your/repos"
  exit 0
elif [ "$HIT_COUNT" -eq 0 ]; then
  ok "no IOC hits — $WARN_COUNT warning(s) above to review"
  echo
  echo "Watchdog disarmed. Review warnings, then rotate: GitHub PATs, npm tokens,"
  echo "AWS/GCP/Azure keys, Kubernetes SA tokens, Vault tokens, SSH keys, ~/.npmrc."
  echo
  echo "For per-repo lockfile + node_modules + git-history scanning, run:"
  echo "  scan-shai-hulud.sh ~/path/to/your/repos"
  exit 0
else
  echo "${RED}${BOLD}$HIT_COUNT IOC hit(s) and $WARN_COUNT warning(s) after cleanup.${RST}"
  echo "  - inspect the [HIT] lines above; some payloads need manual removal"
  echo "  - treat this machine as compromised: rotate ALL credentials"
  echo "  - block .getsession.org and git-tanstack.com at your DNS resolver"
  echo "  - for per-repo scanning, run: scan-shai-hulud.sh ~/path/to/your/repos"
  exit 1
fi
