#!/usr/bin/env bash

# Function to log and handle errors
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# Update the system
sudo dnf update -y || handle_error "Failed to update package lists."

# List of packages to install
packages=(
    pax
    ncompress
    gcc
    g++
    clang
    clang-tools-extra
    make
    cmake
    cppcheck
    libasan
    libubsan
    obs-studio
    kdenlive
    wireshark
    strace
    gdbm-devel
    pari-gp
    hping3
)

# Install packages
for package in "${packages[@]}"; do
    echo "Installing $package..."
    sudo dnf install -y "$package" || handle_error "Failed to install $package."
done

# Additional setup for Wireshark
if rpm -q wireshark > /dev/null; then
    echo "Configuring Wireshark..."
    sudo usermod -a -G wireshark $(whoami) || handle_error "Failed to add user to Wireshark group."
else
    echo "Wireshark not installed. Skipping configuration."
fi

# Install Zenmap via Flatpak
echo "Installing Zenmap via Flatpak..."
flatpak install -y org.nmap.Zenmap || handle_error "Failed to install Zenmap."

# Add /usr/local/lib64 to library path
echo "Adding /usr/local/lib64 to library path..."
echo "/usr/local/lib64" | sudo tee /etc/ld.so.conf.d/local-lib64.conf > /dev/null || handle_error "Failed to modify library path."
sudo ldconfig || handle_error "Failed to reload library configuration."

# Completion message
echo "All tools installed and configured successfully. Please log out and log back in for group changes to take effect."
