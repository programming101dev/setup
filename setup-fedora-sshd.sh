#!/usr/bin/env bash
set -u  # not -e: each step is followed by check_status with a clear message

# --help / -h -> description, exit 0 (P101 uniform CLI help)
case " $* " in
  *" --help "*|*" -h "*)
    cat <<'P101_USAGE'
setup-fedora-sshd.sh — takes no command-line options; run with no arguments.
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
sudo dnf check-update
check_status "Updating package lists"

# Install OpenSSH Server
echo "Installing OpenSSH server..."
ssh_pkgs=$("$(dirname -- "$0")/list-packages.sh" fedora ssh)
check_status "Resolving the ssh package from packages.txt"
[ -n "$ssh_pkgs" ] || { echo "Error: no ssh package listed for fedora in packages.txt. Exiting."; exit 1; }
# shellcheck disable=SC2086  # word splitting intended: the cell may hold several packages
sudo dnf install -y $ssh_pkgs
check_status "Installing OpenSSH server"

# Start the SSH daemon
echo "Starting sshd service..."
sudo systemctl start sshd
check_status "Starting sshd service"

# Enable SSH daemon to start on boot
echo "Enabling sshd service to start on boot..."
sudo systemctl enable sshd
check_status "Enabling sshd service"

# Verify the SSH service status
echo "Verifying sshd service status..."
if ! sudo systemctl status sshd | grep "Active:"; then
    echo "Error: sshd service is not active. Please check logs for details."
    exit 1
fi

# Success message
echo "OpenSSH setup completed successfully. You can now connect to your system using SSH."
