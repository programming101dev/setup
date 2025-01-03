#!/usr/bin/env bash

# Function to log and handle errors
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# Update the system
sudo pacman -Syu --noconfirm || handle_error "Failed to update package lists."

# List of packages to install
packages=(
    pax
    ncompress
    gcc
    clang
    clang-tools-extra
    make
    cmake
    cppcheck
    obs-studio
    kdenlive
    wireshark-qt
    strace
    gdbm
    pari
    hping
    net-tools
    graphviz
    tcpdump
    traceroute
    lsof
    yay
    nmap
    tmux
)

# Install packages
for package in "${packages[@]}"; do
    echo "Installing $package..."
    sudo pacman -S --noconfirm "$package" || handle_error "Failed to install $package."
done

# Additional setup for Wireshark
if pacman -Qi wireshark-qt > /dev/null; then
    echo "Configuring Wireshark..."
    sudo usermod -a -G wireshark $(whoami) || handle_error "Failed to add user to Wireshark group."
else
    echo "Wireshark not installed. Skipping configuration."
fi

# Add /usr/local/lib64 to library path
echo "Adding /usr/local/lib64 to library path..."
echo "/usr/local/lib64" | sudo tee /etc/ld.so.conf.d/local-lib64.conf > /dev/null || handle_error "Failed to modify library path."
sudo ldconfig || handle_error "Failed to reload library configuration."

# Completion message
echo "All tools installed and configured successfully. Please log out and log back in for group changes to take effect."
