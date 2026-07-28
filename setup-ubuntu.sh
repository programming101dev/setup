#!/usr/bin/env bash
set -euo pipefail

# --help / -h -> description, exit 0 (P101 uniform CLI help)
case " $* " in
  *" --help "*|*" -h "*)
    cat <<'P101_USAGE'
setup-ubuntu.sh — takes no command-line options; run with no arguments.
P101_USAGE
    exit 0 ;;
esac

target_user="${SUDO_USER:-$(id -un)}"

# Function to log and handle errors
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# Update and upgrade the system
sudo apt update || handle_error "Failed to update package lists."
sudo apt upgrade -y || handle_error "Failed to upgrade packages."

# List of packages to install
# Package names come from packages.txt (single source of truth for every OS)
# via list-packages.sh -- edit packages.txt, not this script, to change them.
packages=()
package_list="$("$(dirname -- "$0")/list-packages.sh" ubuntu)" || handle_error "failed to read packages.txt"
while IFS= read -r _p; do packages+=("$_p"); done <<< "$package_list"
[ "${#packages[@]}" -gt 0 ] || handle_error "no packages resolved from packages.txt"

# Install packages
for package in "${packages[@]}"; do
    echo "Installing $package..."
    sudo apt install -y "$package" || handle_error "Failed to install $package."
done

# libFuzzer/ASan runtime for clang (needed by fuzz.sh). The package is
# unversioned on newer Ubuntu; fall back to the default clang's version.
if ! sudo apt install -y libclang-rt-dev 2>/dev/null; then
    _cv="$(clang --version | grep -oE '[0-9]+' | head -1 || true)"
    sudo apt install -y "libclang-rt-${_cv}-dev" || handle_error "Failed to install the clang runtime (libclang-rt, needed for fuzzing/sanitizers)."
fi

# Additional setup for Wireshark
if dpkg -l | grep -q wireshark; then
    echo "Configuring Wireshark..."
    sudo usermod -a -G wireshark "$target_user" || handle_error "Failed to add user to Wireshark group."
else
    echo "Wireshark not installed. Skipping configuration."
fi

# Completion message
echo "All tools installed and configured successfully. Please log out and log back in for group changes to take effect."
