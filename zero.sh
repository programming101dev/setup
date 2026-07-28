#!/usr/bin/env bash
set -u  # not -e: dd is expected to stop when the disk fills

# --help / -h -> description, exit 0 (P101 uniform CLI help)
case " $* " in
  *" --help "*|*" -h "*)
    cat <<'P101_USAGE'
zero.sh [--force]

Zero free space on the root filesystem to make a VM image easier to compact.
This intentionally fills / with /zero.fill until the filesystem reports that
it is full, then removes /zero.fill and syncs.

Only run this in disposable lab VMs. Do not run it on a daily-driver machine.
P101_USAGE
    exit 0 ;;
esac

force=0
if [ "${1:-}" = "--force" ]; then
    force=1
    shift
fi
[ "$#" -eq 0 ] || { echo "Unknown option: $1" >&2; exit 2; }

if [ "$(uname -s)" != "Linux" ]; then
    echo "zero.sh is supported only on Linux lab VMs." >&2
    exit 2
fi

cleanup() {
    sudo rm -f /zero.fill
}
trap cleanup EXIT INT TERM

if [ "$force" -ne 1 ]; then
    echo
    echo "This will temporarily fill the root filesystem (/) with /zero.fill."
    echo "Running apps may fail while the disk is full."
    echo "Use this only in a disposable lab VM that you are about to compact."
    echo
    read -r -p "Continue? [y/N] " answer
    case "$answer" in
        y|Y|yes|YES) ;;
        *) echo "Aborted."; exit 0 ;;
    esac
fi

echo "Zeroing free space on / ..."

# Create a large zero-filled file until space runs out
sudo dd if=/dev/zero of=/zero.fill bs=1M status=progress
dd_rc=$?
case "$dd_rc" in
    0|1) ;;
    *) echo "dd failed unexpectedly with exit $dd_rc" >&2; exit "$dd_rc" ;;
esac

# Ensure all writes are flushed to disk
sync

echo "Zeroing complete."
