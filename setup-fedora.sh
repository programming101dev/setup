#!/usr/bin/env bash
set -euo pipefail

# --help / -h -> description, exit 0 (P101 uniform CLI help)
case " $* " in
  *" --help "*|*" -h "*)
    cat <<'P101_USAGE'
setup-fedora.sh — takes no command-line options; run with no arguments.
P101_USAGE
    exit 0 ;;
esac

# Function to log and handle errors
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# Update the system
sudo dnf update -y || handle_error "Failed to update package lists."

# List of packages to install
# Package names come from packages.txt (single source of truth for every OS)
# via list-packages.sh -- edit packages.txt, not this script, to change them.
packages=()
while IFS= read -r _p; do packages+=("$_p"); done < <("$(dirname -- "$0")/list-packages.sh" fedora)
[ "${#packages[@]}" -gt 0 ] || handle_error "no packages resolved from packages.txt"

# Install packages
for package in "${packages[@]}"; do
    echo "Installing $package..."
    sudo dnf install -y "$package" || handle_error "Failed to install $package."
done

# Additional setup for Wireshark
if rpm -q wireshark > /dev/null; then
    echo "Configuring Wireshark..."
    sudo usermod -a -G wireshark "$(whoami)" || handle_error "Failed to add user to Wireshark group."
else
    echo "Wireshark not installed. Skipping configuration."
fi

# Add /usr/local/lib64 to library path
echo "Adding /usr/local/lib64 to library path..."
echo "/usr/local/lib64" | sudo tee /etc/ld.so.conf.d/local-lib64.conf > /dev/null || handle_error "Failed to modify library path."
sudo ldconfig || handle_error "Failed to reload library configuration."

# Completion message
echo "All tools installed and configured successfully. Please log out and log back in for group changes to take effect."
