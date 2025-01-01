#!/usr/bin/env bash

# Function to log and handle errors
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# Update the system
echo "Updating system..."
sudo dnf update -y || handle_error "Failed to update package lists."

# Ensure wget and curl are installed
if ! command -v wget &> /dev/null || ! command -v curl &> /dev/null; then
    echo "Installing wget and curl..."
    sudo dnf install -y wget curl || handle_error "Failed to install wget or curl."
fi

# Software options
declare -A software=(
    [jetbrains-toolbox]="JetBrains Toolbox"
    [github-desktop]="GitHub Desktop"
    [discord]="Discord"
    [google-chrome]="Google Chrome"
    [1password]="1Password"
)

# Functions to install each application
install_jetbrains_toolbox() {
    echo "Installing JetBrains Toolbox..."

    # Ensure jq is installed
    if ! command -v jq &> /dev/null; then
        echo "jq is not installed. Installing jq..."
        sudo dnf install -y jq || handle_error "Failed to install jq."
    fi

    # Fetch the latest JetBrains Toolbox download URL
    json_data=$(curl -s https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release)
    latest_url=$(echo "$json_data" | jq -r '.TBA[0].downloads.linux.link')

    if [[ -z "$latest_url" || ! "$latest_url" =~ ^https:// ]]; then
        echo "Debug: JSON data received: $json_data" >&2
        handle_error "Failed to fetch a valid JetBrains Toolbox URL."
    fi

    echo "Latest JetBrains Toolbox URL: $latest_url"
    wget -O /tmp/jetbrains-toolbox.tar.gz "$latest_url" || handle_error "Failed to download JetBrains Toolbox."
    tar -xvf /tmp/jetbrains-toolbox.tar.gz -C /tmp || handle_error "Failed to extract JetBrains Toolbox."
    mkdir -p ~/.local/bin || handle_error "Failed to create local bin directory."
    mv /tmp/jetbrains-toolbox-*/jetbrains-toolbox ~/.local/bin/ || handle_error "Failed to move JetBrains Toolbox to local bin."
    rm -rf /tmp/jetbrains-toolbox* || handle_error "Failed to clean up JetBrains Toolbox temporary files."
    echo "JetBrains Toolbox installed. You can run it from ~/.local/bin/jetbrains-toolbox."
}

install_github_desktop() {
    echo "Installing GitHub Desktop..."

    # Fetch the latest GitHub Desktop release `.rpm` URL from the API
    latest_url=$(curl -s https://api.github.com/repos/shiftkey/desktop/releases/latest | \
                 jq -r '.assets[] | select(.name | test("x86_64.*\\.rpm$")) | .browser_download_url')

    if [[ -z "$latest_url" || ! "$latest_url" =~ ^https:// ]]; then
        handle_error "Failed to fetch a valid GitHub Desktop .rpm URL."
    fi

    echo "Latest GitHub Desktop RPM URL: $latest_url"
    wget -O /tmp/github-desktop.rpm "$latest_url" || handle_error "Failed to download GitHub Desktop."
    sudo dnf install -y /tmp/github-desktop.rpm || handle_error "Failed to install GitHub Desktop."
    rm -f /tmp/github-desktop.rpm || handle_error "Failed to clean up GitHub Desktop temporary files."
    echo "GitHub Desktop installed successfully."
}

install_discord() {
    echo "Installing Discord..."

    # Fetch the latest Discord tar.gz URL
    discord_url=$(curl -s -L -I -w '%{url_effective}' -o /dev/null "https://discord.com/api/download?platform=linux&format=tar.gz")

    if [[ -z "$discord_url" || ! "$discord_url" =~ ^https:// ]]; then
        handle_error "Failed to fetch a valid Discord tar.gz URL."
    fi

    echo "Discord tar.gz URL: $discord_url"
    curl -o /tmp/discord.tar.gz -L "$discord_url" || handle_error "Failed to download Discord."
    
    # Use sudo to create the installation directory
    sudo mkdir -p /opt/discord || handle_error "Failed to create Discord installation directory."
    sudo tar -xvf /tmp/discord.tar.gz -C /opt/discord --strip-components=1 || handle_error "Failed to extract Discord."

    # Create symbolic link to make Discord accessible from anywhere
    sudo ln -sf /opt/discord/Discord /usr/local/bin/discord || handle_error "Failed to create symbolic link for Discord."
    rm -f /tmp/discord.tar.gz || handle_error "Failed to clean up Discord temporary files."
    echo "Discord installed successfully. You can run it using 'discord'."
}

install_google_chrome() {
    echo "Installing Google Chrome..."

    # Add the Google Chrome repository
    sudo bash -c 'cat > /etc/yum.repos.d/google-chrome.repo' <<EOF || handle_error "Failed to add Google Chrome repository."
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF

    # Install Google Chrome
    sudo dnf install -y google-chrome-stable || handle_error "Failed to install Google Chrome."
}

install_1password() {
    echo "Installing 1Password..."
    wget -O /tmp/1password.rpm "https://downloads.1password.com/linux/rpm/stable/x86_64/1password-latest.rpm" || handle_error "Failed to download 1Password."
    sudo dnf install -y /tmp/1password.rpm || handle_error "Failed to install 1Password."
    rm -f /tmp/1password.rpm || handle_error "Failed to clean up 1Password temporary files."
}

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
    case "$package" in
        jetbrains-toolbox) install_jetbrains_toolbox ;;
        github-desktop) install_github_desktop ;;
        discord) install_discord ;;
        google-chrome) install_google_chrome ;;
        1password) install_1password ;;
        *) echo "Unknown package: $package. Skipping." ;;
    esac
done

# Completion message
echo "Selected software installed successfully."
