#!/usr/bin/env bash

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
  clang
  clang-tidy
  clang-format
  cmake
  cppcheck
  curl
  gcc
  g++
  graphviz
  hping3
  kdenlive
  libbsd-dev
  libfuse2
  libgdbm-dev
  libgdbm-compat-dev
  ncat
  ncompress
  nmap
  make
  net-tools
  obs-studio
  pari-gp
  pax
  tmux
  traceroute
  wireshark
)

# Install packages
for package in "${packages[@]}"; do
    echo "Installing $package..."
    sudo apt install -y "$package" || handle_error "Failed to install $package."
done

# Additional setup for Wireshark
if dpkg -l | grep -q wireshark; then
    echo "Configuring Wireshark..."
    sudo usermod -a -G wireshark "$(whoami)" || handle_error "Failed to add user to Wireshark group."
else
    echo "Wireshark not installed. Skipping configuration."
fi

./setup-groups.sh

# Completion message
echo "All tools installed and configured successfully. Please log out and log back in for group changes to take effect."
