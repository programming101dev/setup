#!/bin/bash

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
sudo dnf install -y openssh-server
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
sudo systemctl status sshd | grep "Active:"
if [ $? -ne 0 ]; then
    echo "Error: sshd service is not active. Please check logs for details."
    exit 1
fi

# Success message
echo "OpenSSH setup completed successfully. You can now connect to your system using SSH."
