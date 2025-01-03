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
sudo apt update
check_status "Updating package lists"

# Install OpenSSH Server
echo "Installing OpenSSH server..."
sudo apt install -y openssh-server
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
sudo systemctl status ssh | grep "Active:"
if [ $? -ne 0 ]; then
    echo "Error: ssh service is not active. Please check logs for details."
    exit 1
fi

# Success message
echo "OpenSSH setup completed successfully. You can now connect to your system using SSH."
