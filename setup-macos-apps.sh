#!/usr/bin/env bash
set -euo pipefail

# macOS app setup hook. There is no required GUI bundle for the core p101
# toolchain yet; keep this script present so `./setup.sh --apps` is a valid
# cross-platform command.

echo "No required macOS app bundle is defined for p101 yet; skipping app setup."
