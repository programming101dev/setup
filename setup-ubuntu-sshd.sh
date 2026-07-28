#!/usr/bin/env bash
set -u  # not -e: each step is followed by check_status with a clear message

# --help / -h -> description, exit 0 (P101 uniform CLI help)
case " $* " in
  *" --help "*|*" -h "*)
    cat <<'P101_USAGE'
setup-ubuntu-sshd.sh — takes no command-line options; run with no arguments.
P101_USAGE
    exit 0 ;;
esac

# Function to check the last command's status and exit if it failed
check_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting."
        exit 1
    fi
}

# Update package lists
echo "Updating package lists..."
sudo apt update
check_status "Updating package lists"

# Install OpenSSH Server
echo "Installing OpenSSH server..."
ssh_pkgs=$("$(dirname -- "$0")/list-packages.sh" ubuntu ssh)
check_status "Resolving the ssh package from packages.txt"
[ -n "$ssh_pkgs" ] || { echo "Error: no ssh package listed for ubuntu in packages.txt. Exiting."; exit 1; }
# shellcheck disable=SC2086  # word splitting intended: the cell may hold several packages
sudo apt install -y $ssh_pkgs
check_status "Installing OpenSSH server"

# Start the SSH service
echo "Starting ssh service..."
sudo systemctl start ssh
check_status "Starting ssh service"

# Enable SSH service to start on boot
echo "Enabling ssh service to start on boot..."
sudo systemctl enable ssh
check_status "Enabling ssh service"

# Verify the SSH service status
echo "Verifying ssh service status..."
if ! sudo systemctl status ssh | grep "Active:"; then
    echo "Error: ssh service is not active. Please check logs for details."
    exit 1
fi

# Success message
echo "OpenSSH setup completed successfully. You can now connect to your system using SSH."
