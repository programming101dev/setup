#!/usr/bin/env bash

# Function to log and handle errors
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# List of packages to install with Homebrew
brew_packages=(
    cppcheck
    gcc
    gpg
    graphviz
    nmap
    pari
    tmux
    wget
)

# Install packages with Homebrew
for package in "${brew_packages[@]}"; do
    echo "Installing $package with Homebrew..."
    brew install "$package" || handle_error "Failed to install $package with Homebrew."
done

sudo bash -c 'echo "export MallocNanoZone=0" >> /etc/zshenv' || handle_error "Failed to add MallocNanoZone to /etc/zshenv."

./setup-groups.sh

# Completion message
echo "All tools installed and configured successfully. Please reboot your computer for changes to take effect."
