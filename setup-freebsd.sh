#!/usr/bin/env bash

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
    sudo
    bash
    wget
    nano
    hping3
    git
    cmake
    gcc
    llvm
    cppcheck
)

# Install packages with pkg
for package in "${pkg_packages[@]}"; do
    echo "Installing $package with pkg..."
    sudo pkg install -y "$package" || handle_error "Failed to install $package with pkg."
done

# Install PARI/GP using the FreeBSD Ports system
PARI_PORT_DIR="/usr/ports/math/pari"
if [ -d "$PARI_PORT_DIR" ]; then
    echo "Installing PARI/GP from ports..."
    cd "$PARI_PORT_DIR" || handle_error "Failed to navigate to $PARI_PORT_DIR."
    sudo make install clean || handle_error "Failed to install PARI/GP from ports."
else
    handle_error "Ports directory for PARI/GP not found at $PARI_PORT_DIR. Ensure that the ports tree is up to date."
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
sudo bash -c 'echo "ldconfig_paths=\"/usr/local/lib64\"" >> /etc/rc.conf' || handle_error "Failed to update /etc/rc.conf."

# Reload ldconfig paths
sudo ldconfig -m /usr/local/lib64 || handle_error "Failed to reload ldconfig paths."

# Completion message
echo "All tools installed and configured successfully."
