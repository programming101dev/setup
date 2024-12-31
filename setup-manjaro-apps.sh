#!/usr/bin/env bash

# Function to log and handle errors
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# Update the system
echo "Updating system..."
sudo pacman -Syu --noconfirm || handle_error "Failed to update package lists."

# Update yay
if ! command -v yay &> /dev/null; then
    handle_error "yay is not installed. Please install yay first."
else
    echo "Updating yay..."
    yay -Syu --noconfirm || handle_error "Failed to update yay."
fi

# Ensure fakeroot is installed
if ! command -v fakeroot &> /dev/null; then
    echo "Installing fakeroot..."
    sudo pacman -S --noconfirm fakeroot || handle_error "Failed to install fakeroot."
fi

# Software options
declare -A software=(
    [jetbrains-toolbox]="JetBrains Toolbox"
    [github-desktop-bin]="GitHub Desktop"
    [discord]="Discord"
    [google-chrome]="Google Chrome"
    [1password]="1password"
)

# Prompt user for each software
selected_packages=()
for pkg in "${!software[@]}"; do
    read -p "Do you want to install ${software[$pkg]}? (y/N): " choice
    case "$choice" in
        [yY]*) selected_packages+=("$pkg") ;;
        *) echo "Skipping ${software[$pkg]}..." ;;
    esac
done

# Install selected packages
if [ ${#selected_packages[@]} -eq 0 ]; then
    echo "No software selected for installation. Exiting."
    exit 0
fi

echo "Installing selected packages: ${selected_packages[*]}"
for package in "${selected_packages[@]}"; do
    echo "Installing ${software[$package]}..."
    yay -S --noconfirm "$package" || handle_error "Failed to install ${software[$package]}"
done

# Completion message
echo "Selected software installed successfully."
