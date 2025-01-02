#!/usr/bin/env bash

# Function to log and handle errors
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# List of packages to install with Homebrew
brew_packages=(
    cmake
    cppcheck
    gcc
    gpg
    graphviz
    llvm
    pari
    tmux
    wget
)

# Install packages with Homebrew
for package in "${brew_packages[@]}"; do
    echo "Installing $package with Homebrew..."
    if [[ "$package" == "wireshark" || "$package" == "obs" || "$package" == "kdenlive" ]]; then
        brew install --cask "$package" || handle_error "Failed to install $package with Homebrew."
    else
        brew install "$package" || handle_error "Failed to install $package with Homebrew."
    fi

done

# Additional setup for llvm
llvm_path=$(brew --prefix llvm)/bin
if ! grep -q "$llvm_path" ~/.zshrc; then
    echo "Adding LLVM to PATH in ~/.zshrc..."
    echo "export PATH=\"$llvm_path:\$PATH\"" >> ~/.zshrc || handle_error "Failed to update PATH for LLVM."
fi

# Install hping3 with MacPorts
sudo port install hping3 || handle_error "Failed to install hping3 with MacPorts."

# Additional setup for /etc/zshenv
sudo bash -c 'echo "export PATH=\"$PATH:/usr/local/opt/gcc/bin:/Applications/CMake.app/Contents/bin\"" >> /etc/zshenv' || handle_error "Failed to update /etc/zshenv."
sudo bash -c 'echo "export MallocNanoZone=0" >> /etc/zshenv' || handle_error "Failed to add MallocNanoZone to /etc/zshenv."

# Completion message
echo "All tools installed and configured successfully. Please reboot your computer for changes to take effect."
