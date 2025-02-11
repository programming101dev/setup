#!/bin/sh

# Function to log and handle errors
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# Update the system
sudo pkg update || handle_error "Failed to update package lists."
sudo pkg upgrade -y || handle_error "Failed to upgrade packages."

# List of packages to install with pkg
pkg_packages=(
    bash
    wget
    nano
    hping3
    git
    cmake
    gcc
    llvm
    cppcheck
    pari
    python3
    lsof
    gnugp
    graphviz
)

# Install packages with pkg
for package in "${pkg_packages[@]}"; do
    echo "Installing $package with pkg..."
    sudo pkg install -y "$package" || handle_error "Failed to install $package with pkg."
done

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
sudo sysrc -f /etc/rc.conf ldconfig_paths="/usr/local/lib /usr/local/lib64"

# Reload ldconfig paths
sudo ldconfig -m /usr/local/lib /usr/local/lib64

./setup-groups.sh

# Completion message
echo "All tools installed and configured successfully."
