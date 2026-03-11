#!/usr/bin/env bash

# disable-firewall.sh
#
# Purpose:
# Completely remove packet filtering from a Linux system so that all
# traffic is accepted. This is useful for teaching labs where students
# must return a machine to a known "no firewall" baseline.
#
# What this script does:
# 1. Flushes nftables rules
# 2. Stops and disables common firewall managers
# 3. Resets legacy iptables and ip6tables policies to ACCEPT
# 4. Flushes all tables and user chains
# 5. Prints verification output
#
# WARNING:
# Running this script removes all firewall protection from the host.
# Only use in controlled environments such as teaching labs.

FORCE=0

if [[ "${1:-}" == "--force" ]]; then
    FORCE=1
fi

if [[ "$FORCE" -ne 1 ]]; then
    echo
    echo "This script will disable nftables, iptables, and common firewall managers."
    echo "The system will accept all network traffic."
    echo
    read -r -p "Continue? [y/N] " answer

    case "$answer" in
        y|Y|yes|YES)
            ;;
        *)
            echo "Aborted."
            exit 0
            ;;
    esac
fi

# ------------------------------------------------------------
# nftables
# ------------------------------------------------------------

echo
echo "[1/5] Flushing nftables ruleset"
sudo nft flush ruleset

echo "[2/5] Disabling nftables service"
sudo systemctl disable --now nftables 2>/dev/null || true

# ------------------------------------------------------------
# Other firewall managers
# ------------------------------------------------------------

echo
echo "[3/5] Disabling other firewall managers (if present)"

sudo systemctl disable --now firewalld 2>/dev/null || true
sudo systemctl disable --now ufw 2>/dev/null || true
sudo systemctl disable --now netfilter-persistent 2>/dev/null || true

# ------------------------------------------------------------
# Legacy iptables IPv4
# ------------------------------------------------------------

echo
echo "[4/5] Resetting iptables (IPv4)"

sudo iptables -P INPUT ACCEPT 2>/dev/null || true
sudo iptables -P FORWARD ACCEPT 2>/dev/null || true
sudo iptables -P OUTPUT ACCEPT 2>/dev/null || true

sudo iptables -F 2>/dev/null || true
sudo iptables -t nat -F 2>/dev/null || true
sudo iptables -t mangle -F 2>/dev/null || true
sudo iptables -t raw -F 2>/dev/null || true
sudo iptables -t security -F 2>/dev/null || true

sudo iptables -X 2>/dev/null || true

# ------------------------------------------------------------
# Legacy iptables IPv6
# ------------------------------------------------------------

echo
echo "[5/5] Resetting ip6tables (IPv6)"

sudo ip6tables -P INPUT ACCEPT 2>/dev/null || true
sudo ip6tables -P FORWARD ACCEPT 2>/dev/null || true
sudo ip6tables -P OUTPUT ACCEPT 2>/dev/null || true

sudo ip6tables -F 2>/dev/null || true
sudo ip6tables -t nat -F 2>/dev/null || true
sudo ip6tables -t mangle -F 2>/dev/null || true
sudo ip6tables -t raw -F 2>/dev/null || true
sudo ip6tables -t security -F 2>/dev/null || true

sudo ip6tables -X 2>/dev/null || true

# ------------------------------------------------------------
# Verification
# ------------------------------------------------------------

echo
echo "------------------------------------------------------------"
echo "Verification"
echo "------------------------------------------------------------"

echo
echo "--- nftables ruleset ---"
sudo nft list ruleset || true

echo
echo "--- iptables (IPv4) ---"
sudo iptables -S || true

echo
echo "--- ip6tables (IPv6) ---"
sudo ip6tables -S || true

echo
echo "--- firewall services ---"
systemctl is-enabled nftables 2>/dev/null || true
systemctl is-enabled firewalld 2>/dev/null || true
systemctl is-enabled ufw 2>/dev/null || true
systemctl is-enabled netfilter-persistent 2>/dev/null || true

echo
echo "Firewall disabled. The system should now accept all traffic."
