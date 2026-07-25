#!/bin/sh
set -u  # not -e: each step is followed by check_status with a clear message

# --help / -h -> description, exit 0 (P101 uniform CLI help)
case " $* " in
  *" --help "*|*" -h "*)
    cat <<'P101_USAGE'
setup-freebsd-sshd.sh — takes no command-line options; run with no arguments.
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
sudo pkg update
check_status "Updating package lists"

# Install OpenSSH Server (OpenSSH is part of FreeBSD base system, but installing the package ensures it's available)
echo "Installing OpenSSH server..."
ssh_pkgs=$("$(dirname -- "$0")/list-packages.sh" freebsd ssh)
check_status "Resolving the ssh package from packages.txt"
[ -n "$ssh_pkgs" ] || { echo "Error: no ssh package listed for freebsd in packages.txt. Exiting."; exit 1; }
# shellcheck disable=SC2086  # word splitting intended: the cell may hold several packages
sudo pkg install -y $ssh_pkgs
check_status "Installing OpenSSH server"

# Enable SSH daemon to start on boot
echo "Enabling sshd service to start on boot..."
sudo sysrc sshd_enable="YES"
check_status "Enabling sshd service"

# Start the SSH daemon
echo "Starting sshd service..."
sudo service sshd start
check_status "Starting sshd service"

# Verify the SSH service status
echo "Verifying sshd service status..."
if ! sudo service sshd status | grep "is running"; then
    echo "Error: sshd service is not active. Please check logs for details."
    exit 1
fi

# Success message
echo "OpenSSH setup completed successfully. You can now connect to your system using SSH."
