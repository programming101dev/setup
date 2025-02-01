#!/usr/bin/env bash
set -e

os=$(uname -s)

if [ "$os" = "Darwin" ]; then
    echo "Detected macOS."
    # Update Homebrew packages if Homebrew is installed.
    if command -v brew >/dev/null; then
        echo "Updating Homebrew packages..."
        brew update && brew upgrade
    else
        echo "Homebrew not found."
    fi
    # Run macOS Software Update.
    echo "Running macOS Software Update..."
    sudo softwareupdate --install --all

elif [ "$os" = "Linux" ]; then
    # Source distribution info from /etc/os-release.
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        distro=$ID
    else
        echo "Cannot detect Linux distribution."
        exit 1
    fi

    case "$distro" in
        ubuntu|kali)
            echo "Detected $distro. Updating using APT..."
            sudo apt update && sudo apt upgrade -y
            ;;
        fedora)
            echo "Detected Fedora. Updating using DNF..."
            sudo dnf upgrade --refresh -y
            ;;
        manjaro)
            echo "Detected Manjaro."
            echo "Updating system packages using Pacman..."
            sudo pacman -Syu --noconfirm
            if command -v yay >/dev/null; then
                echo "Updating AUR packages using yay..."
                yay -Syu --noconfirm
            fi
            ;;
        *)
            echo "Unsupported Linux distribution: $distro"
            exit 1
            ;;
    esac

elif [ "$os" = "FreeBSD" ]; then
    echo "Detected FreeBSD."
    # Update the FreeBSD base system.
    echo "Updating FreeBSD base system..."
    sudo freebsd-update fetch
    sudo freebsd-update install
    # Update installed packages.
    echo "Updating FreeBSD packages..."
    sudo pkg update && sudo pkg upgrade -y

else
    echo "Unsupported operating system: $os"
    exit 1
fi
