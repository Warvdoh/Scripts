#!/usr/bin/env bash
set -euo pipefail

USER_HOME="/home/$USER"
TARGET="$USER_HOME/update-x.sh"
BASHRC="$USER_HOME/.bashrc"
REPO_URL="https://github.com/Warvdoh/Scripts"
REPO_RAW_BASE="https://raw.githubusercontent.com/Warvdoh/Scripts/main"
VERSION="v1.0"

# ANSI colors
INFO="\033[1;36m[INFO]\033[0m"
WARN="\033[1;33m[WARN]\033[0m"
FAIL="\033[1;31m[FAIL]\033[0m"
OK="\033[1;32m[OK]\033[0m"

# Self‑install
if [[ "$BASH_SOURCE" != "$TARGET" ]]; then
  [[ ! -f "$TARGET" ]] && { echo -e "${INFO} Installing update-x"; cp "$BASH_SOURCE" "$TARGET"; chmod +x "$TARGET"; }
  if ! grep -qxF "# added by update-x" "$BASHRC"; then
    echo -e "${INFO} Adding alias to ~/.bashrc"
    { echo ""; echo "# added by update-x"; echo "alias update-x=\"$TARGET\""; } >> "$BASHRC"
  fi
  echo -e "${INFO} Reload shell or run 'source ~/.bashrc'"
  exit 0
fi

echo -e "${INFO} Running update-x ${VERSION} by Warvdoh"
echo "────────────────────────────────────────────────────"

# Flags
DRY=0
FORCE=0
INSTALL=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d) DRY=1 ;;
    -o) FORCE=1 ;;
    --install) INSTALL=1 ;;
  esac
  shift
done

# Clone/update repo
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
echo -e "${INFO} Cloning/updating repo…"
git clone -q --depth=1 "$REPO_URL" "$TMP/Scripts" 2>/dev/null || git -C "$TMP/Scripts" pull -q
REPO_DIR="$TMP/Scripts"

# Find local scripts
mapfile -t SCRIPTS < <(find "$USER_HOME" -maxdepth 1 -type f -name '*-x.sh' -printf '%f\n')

# Install mode skips table if no dry-run
if (( INSTALL && !DRY )); then
  mapfile -t GIT_SCRIPTS < <(find "$REPO_DIR" -type f -name '*-x.sh' -printf '%f\n')
  for name in "${GIT_SCRIPTS[@]}"; do
    local_path="$USER_HOME/$name"
    src="$REPO_DIR/Bash/$name"

    [[ -e "$local_path" ]] && { echo -e "${INFO} $name already exists locally, skipping."; continue; }
    (( DRY )) && { echo -e "${INFO} Would install $name → $local_path"; continue; }

    cp "$src" "$local_path"
    chmod +x "$local_path"

    base="${name%-x.sh}"
    if [[ "$name" != "update-x.sh" ]]; then
      if ! grep -q "alias $base=" "$BASHRC"; then
        echo "alias $base=\"$local_path\"" >> "$BASHRC"
        echo -e "${OK} Installed $name and added alias '$base'"
      else
        echo -e "${INFO} Alias '$base' already exists, skipping."
      fi
    else
      echo -e "${OK} Installed $name (no alias)"
    fi
  done

  echo -e "${INFO} --install complete. Reload shell or 'source ~/.bashrc'"
  exit 0
fi

# No local scripts?
[[ ${#SCRIPTS[@]} -eq 0 ]] && { echo -e "${WARN} No *-x.sh in $USER_HOME"; exit 0; }

# Print header
printf "[Local]          [ver]      [Git]            [ver]      [url]\n"

# Extract version from VERSION="v…"
get_ver(){
  grep -Eo '^VERSION="v[^"]+"' "$1" 2>/dev/null | head -1 | cut -d\" -f2 || echo "v?.?"
}

# Compare arbitrary-length dot versions
cmp_ver(){
  IFS='.' read -ra a <<< "${1#v}"; IFS='.' read -ra b <<< "${2#v}"
  local n=${#a[@]}; (( ${#b[@]}>n )) && n=${#b[@]}
  for ((i=0;i<n;i++)); do
    local x=${a[i]:-0} y=${b[i]:-0}
    (( x>y )) && return 1
    (( x<y )) && return 2
  done
  return 0
}

for name in "${SCRIPTS[@]}"; do
  local_file="$USER_HOME/$name"
  lver=$(get_ver "$local_file")

  git_file=$(find "$REPO_DIR" -type f -name "$name" | head -1 || true)
  if [[ -z "$git_file" ]]; then
    echo -e "${FAIL} $name not in repo"
    continue
  fi
  gver=$(get_ver "$git_file")
  url="$REPO_RAW_BASE/${git_file#$REPO_DIR/}"

  # Print table row
  printf "%-15s %-9s %-15s %-9s %s\n" \
    "$name" "$lver" "$name" "$gver" "$url"

  # Dry-run only prints
  (( DRY )) && continue

  # If force overwrite flag, skip all checks
  if (( FORCE )); then
    cp "$git_file" "$local_file"
    chmod +x "$local_file"
    echo -e "${OK} $name force‑overwritten from git version $gver. Dry run (-d) to see changes"
    continue
  fi

  # Skip unknown versions
  if [[ "$lver" == "v?.?" || "$gver" == "v?.?" ]]; then
    echo -e "${WARN} Cannot compare $name: local($lver) or git($gver) unknown"
    continue
  fi

  cmp_ver "$lver" "$gver"; res=$?
  if (( res == 1 )); then
    echo -e "${WARN} $name local($lver) > git($gver), skipping"
  else
    cp "$git_file" "$local_file"
    chmod +x "$local_file"
    if (( res == 0 )); then
      echo -e "${INFO} $name equal($lver), overwritten"
    else
      echo -e "${OK} $name updated $lver→$gver"
    fi
  fi
done

echo -e "${INFO} update-x complete."

# Licensed under Warvdoh's Personal Use License (WPUL) Version 1.2 © 2025 Warvdoh Mróz  
# https://warvdoh.github.io/Assets/LICENSE.md
