#!/usr/bin/env bash
set -uo pipefail  # inspect every available backend, then report all failures

# --help / -h -> description, exit 0 (P101 uniform CLI help)
case " $* " in
  *" --help "*|*" -h "*)
    cat <<'P101_USAGE'
disable-firewall.sh

Purpose:
Completely remove packet filtering from a Linux system so that all
traffic is accepted. This is useful for teaching labs where students
must return a machine to a known "no firewall" baseline.

What this script does:
1. Flushes nftables rules
2. Stops and disables common firewall managers
3. Resets legacy iptables and ip6tables policies to ACCEPT
4. Flushes all tables and user chains
5. Prints verification output

WARNING:
Running this script removes all firewall protection from the host.
It disables common firewall services persistently, so the change survives
reboot unless you re-enable a firewall manager yourself.
Only use in controlled environments such as teaching labs.

Before running it, consider saving the nftables ruleset:
  sudo nft list ruleset > firewall-before-p101.nft
P101_USAGE
    exit 0 ;;
esac

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
# It disables common firewall services persistently, so the change survives
# reboot unless you re-enable a firewall manager yourself.
# Only use in controlled environments such as teaching labs.

FORCE=0
failures=0
backends=0

if [[ "${1:-}" == "--force" ]]; then
    FORCE=1
fi

run_backend() {
    tool="$1"
    shift
    if ! command -v "$tool" >/dev/null 2>&1; then
        return 0
    fi
    backends=$((backends + 1))
    if ! sudo "$tool" "$@"; then
        echo "FAIL: $tool $*" >&2
        failures=$((failures + 1))
        return 1
    fi
}

disable_service_if_present() {
    service="$1"
    command -v systemctl >/dev/null 2>&1 || return 0
    if systemctl list-unit-files "$service.service" >/dev/null 2>&1; then
        if ! sudo systemctl disable --now "$service"; then
            echo "FAIL: could not disable $service" >&2
            failures=$((failures + 1))
        fi
    fi
}

if [[ "$(uname -s)" != "Linux" ]]; then
    echo "disable-firewall.sh is supported only on Linux." >&2
    exit 2
fi

if [[ "$FORCE" -ne 1 ]]; then
    echo
    echo "This script will disable nftables, iptables, and common firewall managers."
    echo "The system will accept all network traffic."
    echo "The service-disable steps are persistent and survive reboot."
    echo "Consider saving a backup first: sudo nft list ruleset > firewall-before-p101.nft"
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
run_backend nft flush ruleset || true

echo "[2/5] Disabling nftables service"
disable_service_if_present nftables

# ------------------------------------------------------------
# Other firewall managers
# ------------------------------------------------------------

echo
echo "[3/5] Disabling other firewall managers (if present)"

disable_service_if_present firewalld
disable_service_if_present ufw
disable_service_if_present netfilter-persistent

# ------------------------------------------------------------
# Legacy iptables IPv4
# ------------------------------------------------------------

echo
echo "[4/5] Resetting iptables (IPv4)"

run_backend iptables -P INPUT ACCEPT || true
run_backend iptables -P FORWARD ACCEPT || true
run_backend iptables -P OUTPUT ACCEPT || true
run_backend iptables -F || true
run_backend iptables -t nat -F || true
run_backend iptables -t mangle -F || true
run_backend iptables -t raw -F || true
run_backend iptables -t security -F || true
run_backend iptables -X || true

# ------------------------------------------------------------
# Legacy iptables IPv6
# ------------------------------------------------------------

echo
echo "[5/5] Resetting ip6tables (IPv6)"

run_backend ip6tables -P INPUT ACCEPT || true
run_backend ip6tables -P FORWARD ACCEPT || true
run_backend ip6tables -P OUTPUT ACCEPT || true
run_backend ip6tables -F || true
run_backend ip6tables -t nat -F || true
run_backend ip6tables -t mangle -F || true
run_backend ip6tables -t raw -F || true
run_backend ip6tables -t security -F || true
run_backend ip6tables -X || true

# ------------------------------------------------------------
# Verification
# ------------------------------------------------------------

echo
echo "------------------------------------------------------------"
echo "Verification"
echo "------------------------------------------------------------"

echo
echo "--- nftables ruleset ---"
if command -v nft >/dev/null 2>&1; then
    nft_rules="$(sudo nft list ruleset 2>/dev/null)" || {
        echo "FAIL: could not verify nftables ruleset" >&2
        failures=$((failures + 1))
        nft_rules=""
    }
    printf '%s\n' "$nft_rules"
    if [ -n "${nft_rules//[[:space:]]/}" ]; then
        echo "FAIL: nftables rules remain" >&2
        failures=$((failures + 1))
    fi
else
    echo "(nft not installed)"
fi

echo
echo "--- iptables (IPv4) ---"
if command -v iptables >/dev/null 2>&1; then
    sudo iptables -S || failures=$((failures + 1))
else
    echo "(iptables not installed)"
fi

echo
echo "--- ip6tables (IPv6) ---"
if command -v ip6tables >/dev/null 2>&1; then
    sudo ip6tables -S || failures=$((failures + 1))
else
    echo "(ip6tables not installed)"
fi

echo
echo "--- firewall services ---"
if command -v systemctl >/dev/null 2>&1; then
    for service in nftables firewalld ufw netfilter-persistent; do
        if systemctl list-unit-files "$service.service" >/dev/null 2>&1; then
            state="$(systemctl is-enabled "$service" 2>/dev/null || true)"
            printf '%s: %s\n' "$service" "${state:-unknown}"
            case "$state" in disabled|masked|not-found) ;; *)
                echo "FAIL: $service is not disabled" >&2
                failures=$((failures + 1)) ;;
            esac
        fi
    done
fi

echo
if [ "$backends" -eq 0 ]; then
    echo "No nftables/iptables backend was installed; nothing was changed."
elif [ "$failures" -ne 0 ]; then
    echo "Firewall reset incomplete: $failures problem(s)." >&2
    exit 1
else
    echo "Firewall disabled and available backends verified."
fi
