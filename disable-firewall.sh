#!/bin/sh
# disable_all_firewalls.sh
# Ensures no firewall rules are active now, and disables firewall services at boot.
# Optional flag: --persist-empty-nft writes an empty /etc/nftables.conf and keeps nftables.service enabled.
# Usage: sudo ./disable0firewalls.sh [--persist-empty-nft]

set -eu

PERSIST_EMPTY_NFT=0
if [ "${1-}" = "--persist-empty-nft" ]; then
  PERSIST_EMPTY_NFT=1
fi

# Re-exec as root if needed
if [ "${EUID-$(id -u)}" != "0" ]; then
  exec sudo "$0" "$@"
fi

have() { command -v "$1" >/dev/null 2>&1; }

say() { printf '%s\n' "$*"; }

# 1) Clear nftables completely
if have nft; then
  say "[nft] Flushing ruleset"
  nft flush ruleset 2>/dev/null || true
else
  say "[nft] nft not found, skipping"
fi

# 2) Stop and disable nftables service
if have systemctl; then
  say "[systemd] Disabling nftables service"
  systemctl disable --now nftables 2>/dev/null || true
else
  say "[systemd] systemctl not found, skipping service management"
fi

# 3) Stop and disable other common firewall managers
if have systemctl; then
  say "[systemd] Disabling firewalld, ufw, netfilter-persistent if present"
  systemctl disable --now firewalld 2>/dev/null || true
  systemctl disable --now ufw       2>/dev/null || true
  systemctl disable --now netfilter-persistent 2>/dev/null || true
fi

# 4) Set permissive policies and flush legacy iptables (IPv4)
if have iptables; then
  say "[iptables] Setting ACCEPT policies and flushing"
  iptables -P INPUT   ACCEPT 2>/dev/null || true
  iptables -P FORWARD ACCEPT 2>/dev/null || true
  iptables -P OUTPUT  ACCEPT 2>/dev/null || true
  iptables -F 2>/dev/null || true
  iptables -t nat    -F 2>/dev/null || true
  iptables -t mangle -F 2>/dev/null || true
  iptables -X 2>/dev/null || true
else
  say "[iptables] iptables not found, skipping"
fi

# 5) Same for IPv6
if have ip6tables; then
  say "[ip6tables] Setting ACCEPT policies and flushing"
  ip6tables -P INPUT   ACCEPT 2>/dev/null || true
  ip6tables -P FORWARD ACCEPT 2>/dev/null || true
  ip6tables -P OUTPUT  ACCEPT 2>/dev/null || true
  ip6tables -F 2>/dev/null || true
  ip6tables -t nat    -F 2>/dev/null || true   # nat may not exist
  ip6tables -t mangle -F 2>/dev/null || true
  ip6tables -X 2>/dev/null || true
else
  say "[ip6tables] ip6tables not found, skipping"
fi

# 6) Optional: persist an empty nftables config but keep the service enabled
if [ "$PERSIST_EMPTY_NFT" -eq 1 ]; then
  if have nft; then
    say "[nft] Writing empty /etc/nftables.conf and enabling nftables service"
    umask 022
    # Single-quoted heredoc avoids shell expansion in all common shells
    tee /etc/nftables.conf >/dev/null <<'EOF'
flush ruleset
EOF
    if have systemctl; then
      systemctl enable --now nftables
      nft -f /etc/nftables.conf || true
    fi
  else
    say "[nft] nft not found, cannot persist empty config"
  fi
fi

# 7) Verification summary
say ""
say "=== Verification ==="
if have nft; then
  say "[nft] Current ruleset (should be empty):"
  nft list ruleset || true
fi

if have iptables; then
  say "[iptables] Policies and rules:"
  iptables -S || true
fi

if have ip6tables; then
  say "[ip6tables] Policies and rules:"
  ip6tables -S || true
fi

if have systemctl; then
  say "[systemd] Service enablement state:"
  for svc in nftables firewalld ufw netfilter-persistent; do
    state="$(systemctl is-enabled "$svc" 2>/dev/null || true || true)"
    [ -z "$state" ] && state="not-installed-or-static"
    printf '%-24s %s\n' "$svc:" "$state"
  done
fi

say ""
say "Done. If nft output is empty and iptables policies are ACCEPT with no -A rules, no firewall is active."
say "Use 'ss -lntup' to see which services are now exposed."
