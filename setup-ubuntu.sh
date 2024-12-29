#!/bin/bash

# Function to log and handle errors
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# Update and upgrade the system
sudo apt update || handle_error "Failed to update package lists."
sudo apt upgrade -y || handle_error "Failed to upgrade packages."

# List of packages to install
packages=(
    pax
    ncompress
    net-tools
    traceroute
    curl
    libfuse2
    git
    gcc
    g++
    clang
    clang-tidy
    clang-format
    make
    cmake
    cppcheck
    graphviz
    obs-studio
    kdenlive
    wireshark
    libgdbm-dev
    libgdbm-compat-dev
    libbsd-dev
    pari-gp
)

# Install packages
for package in "${packages[@]}"; do
    echo "Installing $package..."
    sudo apt install -y "$package" || handle_error "Failed to install $package."
done

# Additional setup for Wireshark
if dpkg -l | grep -q wireshark; then
    echo "Configuring Wireshark..."
    echo "Yes" | sudo dpkg-reconfigure wireshark-common || handle_error "Failed to configure Wireshark."
    sudo usermod -a -G wireshark $(whoami) || handle_error "Failed to add user to Wireshark group."
else
    echo "Wireshark not installed. Skipping configuration."
fi

# Completion message
echo "All tools installed and configured successfully. Please log out and log back in for group changes to take effect."
