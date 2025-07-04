#!/usr/bin/env bash
set -euo pipefail

USER_HOME="/home/$USER"
TARGET="$USER_HOME/ntest-x.sh"
BASHRC="$USER_HOME/.bashrc"

# ANSI colours
INFO="\033[1;36m[INFO]\033[0m"

# 1) Bootstrap: clone self to ~/ntest-x.sh if missing
if [[ "$BASH_SOURCE" != "$TARGET" ]]; then
  if [[ ! -f "$TARGET" ]]; then
    echo -e "${INFO} Installing ntest-x to $TARGET"
    cp "${BASH_SOURCE[0]}" "$TARGET"
    chmod +x "$TARGET"
  fi
  # 2) Ensure alias in ~/.bashrc
  if ! grep -qxF "# added by ntest-x"   "$BASHRC" \
      || ! grep -qxF "alias ntest=\"$TARGET\"" "$BASHRC"; then
    echo -e "${INFO} Adding alias to $BASHRC"
    {
      echo ""
      echo "# added by ntest-x"
      echo "alias ntest=\"$TARGET\""
    } >> "$BASHRC"
  fi
  echo -e "${INFO} Reload your shell or run 'source ~/.bashrc' to use 'ntest'"
  exit 0
fi

# From here on, we're running as ~/ntest-x.sh
echo -e "${INFO} Running ntest-x v0.1.9 by Warvdoh"
echo "──────────────────────────────────────────────"

# The rest is identical to v0.1.9 ping suite:

OK="\033[1;32m[OK]\033[0m"
FAIL="\033[1;31m[FAIL]\033[0m"
YEL="\033[1;33m"
RST="\033[0m"

# Tests: "Label IP"
mapfile -t TESTS < <(
  printf '%s\n' \
    "Cloudflare 1.1.1.1" \
    "GoogleDNS  8.8.8.8" \
    "DefaultGW  $(ip route | awk '/^default/ {print $3; exit}')"
)

ping_and_cleanup(){
  local label=$1 target=$2
  echo -e "${INFO} Pinging ${label} [${target}]..."

  local tmp; tmp=$(mktemp)
  stdbuf -oL ping -c4 "$target" 2>&1 | tee "$tmp"

  local cnt; cnt=$(wc -l <"$tmp")
  local loss
  loss=$(grep -oP '(\d+)% packet loss' "$tmp" | head -1 | grep -oP '\d+' || echo 100)

  if [[ $loss -eq 0 ]]; then
    for ((i=0; i<cnt; i++)); do
      echo -en "\033[1A\033[2K"
    done
    echo -e "    ${label} [${target}]: ${OK}"
  else
    echo -e "    ${label} [${target}]: ${FAIL} (${loss}% loss)"
  fi

  rm -f "$tmp"
  echo
}

for entry in "${TESTS[@]}"; do
  read -r label target <<<"$entry"
  ping_and_cleanup "$label" "$target"
done

echo -e "${INFO} Local LAN IPs:"
ip -o -4 addr show scope global \
  | awk -v Y="$YEL" -v R="$RST" '{printf "    " Y "%-10s" R " %s\n", $2, $4}'
ip -o -6 addr show scope global \
  | awk -v Y="$YEL" -v R="$RST" '{printf "    " Y "%-10s" R " %s\n", $2, $4}'

echo -e "\n${INFO} Network test complete."
# Licensed under Warvdoh's Personal Use License (WPUL) Version 1.2 Copyright (c) 2025 Warvdoh Mróz. https://warvdoh.github.io/Assets/LICENSE.md
