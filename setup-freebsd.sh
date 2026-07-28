#!/bin/sh
set -eu

# --help / -h -> description, exit 0 (P101 uniform CLI help)
case " $* " in
  *" --help "*|*" -h "*)
    cat <<'P101_USAGE'
Usage: setup-freebsd.sh [--lab-vm]

  --lab-vm  also grant password-protected sudo access to every local user.
            Use only on a disposable teaching VM.
P101_USAGE
    exit 0 ;;
esac

lab_vm=0
case "${1-}" in
  "") ;;
  --lab-vm) lab_vm=1 ;;
  *) echo "Unknown option: $1" >&2; exit 2 ;;
esac

# Function to log and handle errors
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# Update the system
pkg update || handle_error "Failed to update package lists."
pkg upgrade -y || handle_error "Failed to upgrade packages."

# List of packages (POSIX-compatible format)
# Package names come from packages.txt (single source of truth for every OS).
pkg_packages="$("$(dirname -- "$0")/list-packages.sh" freebsd)" || handle_error "failed to read packages.txt"

# Install packages with pkg
for package in $pkg_packages; do
    echo "Installing $package with pkg..."
    pkg install -y "$package" || handle_error "Failed to install $package with pkg."
done

# FreeBSD Python packages are flavor-versioned (for example py313-gcovr), and
# the available flavor changes with the repository's default Python version.
# Install it when a binary package is published, but do not make base setup
# depend on one exact Python flavor.
if ! command -v gcovr >/dev/null 2>&1; then
    echo "Looking for a FreeBSD gcovr package..."
    gcovr_pkg="$(pkg search -q -x '^py[0-9]+-gcovr$' | head -n 1 || true)"
    if [ -n "$gcovr_pkg" ]; then
        echo "Installing $gcovr_pkg with pkg..."
        pkg install -y "$gcovr_pkg" || handle_error "Failed to install $gcovr_pkg with pkg."
    else
        echo "No FreeBSD gcovr binary package found; skipping optional coverage reporter."
    fi
fi

# Fix cppcheck installation (if needed)
# Uncomment and modify this block if cppcheck issues arise again
# if ! command -v cppcheck > /dev/null 2>&1; then
#     echo "Fixing cppcheck installation..."
#     wget https://github.com/danmar/cppcheck/archive/2.13.0.zip || handle_error "Failed to download cppcheck source."
#     unzip 2.13.0.zip || handle_error "Failed to unzip cppcheck source."
#     cd cppcheck-2.13.0 || handle_error "Failed to change directory to cppcheck source."
#     cmake -S . -B build || handle_error "Failed to configure cppcheck build."
#     cmake --build build || handle_error "Failed to build cppcheck."
#     sudo cmake --install build || handle_error "Failed to install cppcheck."
#     cd .. && rm -rf cppcheck-2.13.0* || handle_error "Failed to clean up cppcheck source."
# fi

# Update /etc/rc.conf for ldconfig
sysrc -f /etc/rc.conf ldconfig_paths="/usr/local/lib /usr/local/lib64" || handle_error "Failed to update ldconfig paths in rc.conf."

# Reload ldconfig paths
ldconfig -m /usr/local/lib /usr/local/lib64 || handle_error "Failed to reload ldconfig paths."

if [ "$lab_vm" -eq 1 ]; then
    # Deliberate only for throwaway teaching VMs. Overwrite rather than append
    # so reruns do not duplicate the rule.
    echo "ALL ALL=(ALL) ALL" | sudo tee /usr/local/etc/sudoers.d/all-users > /dev/null || handle_error "Failed to write sudoers rule."
    sudo chmod 440 /usr/local/etc/sudoers.d/all-users || handle_error "Failed to set sudoers file permissions."
else
    echo "Not granting machine-wide sudo access (pass --lab-vm for a disposable lab VM)."
fi

# Completion message
echo "All tools installed and configured successfully."
