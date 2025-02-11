#!/bin/sh

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
sudo pkg install -y openssh-portable
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
sudo service sshd status | grep "is running"
if [ $? -ne 0 ]; then
    echo "Error: sshd service is not active. Please check logs for details."
    exit 1
fi

# Success message
echo "OpenSSH setup completed successfully. You can now connect to your system using SSH."
