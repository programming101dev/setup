#!/bin/bash

# --help / -h -> description, exit 0 (P101 uniform CLI help)
case " $* " in
  *" --help "*|*" -h "*)
    cat <<'P101_USAGE'
zero.sh — takes no command-line options; run with no arguments.
P101_USAGE
    exit 0 ;;
esac

echo "Zeroing free space on / ..."

# Create a large zero-filled file until space runs out
sudo dd if=/dev/zero of=/zero.fill bs=1M status=progress || true

# Remove the zero-filled file
sudo rm -f /zero.fill

# Ensure all writes are flushed to disk
sync

echo "Zeroing complete."
