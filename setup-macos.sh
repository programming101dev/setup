#!/usr/bin/env bash

# Function to log and handle errors
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# Install Xcode command line tools
if ! xcode-select -p > /dev/null 2>&1; then
    echo "Installing Xcode command line tools..."
    xcode-select --install || handle_error "Failed to install Xcode command line tools."
fi

# Agree to Xcode license
sudo xcodebuild -license accept || handle_error "Failed to accept Xcode license."

# Install Homebrew
if ! command -v brew > /dev/null 2>&1; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || handle_error "Failed to install Homebrew."
fi

# Install MacPorts
if ! command -v port > /dev/null 2>&1; then
    echo "Installing MacPorts..."
    curl -O https://distfiles.macports.org/MacPorts/MacPorts-2.8.1.tar.bz2 || handle_error "Failed to download MacPorts."
    tar xf MacPorts-2.8.1.tar.bz2
    cd MacPorts-2.8.1 && ./configure && make && sudo make install || handle_error "Failed to install MacPorts."
    cd .. && rm -rf MacPorts-2.8.1*
fi

# List of packages to install with Homebrew
brew_packages=(
    llvm
    gcc
    cppcheck
    pari
    wget
    zenmap
    graphviz
    tmux
    cmake
    obs
    kdenlive
    wireshark
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

# Configure Wireshark
if [ -d "/Applications/Wireshark.app" ]; then
    echo "Configuring Wireshark..."
    sudo installer -pkg "/Applications/Wireshark.app/Contents/Resources/ChmodBPF.pkg" -target / || handle_error "Failed to install ChmodBPF."
else
    echo "Wireshark not installed. Skipping configuration."
fi

# Completion message
echo "All tools installed and configured successfully. Please reboot your computer for changes to take effect."
