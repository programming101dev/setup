#!/bin/bash

# Function to check the last command's status and exit if it failed
check_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting."
        exit 1
    fi
}

# Enable Remote Login (SSH)
echo "Enabling Remote Login (SSH)..."
sudo systemsetup -setremotelogin on
check_status "Enabling Remote Login"

# Verify SSH service status
echo "Verifying SSH service status..."
status=$(sudo systemsetup -getremotelogin)
if [[ "$status" == *"On"* ]]; then
    echo "SSH is successfully enabled."
else
    echo "Error: SSH is not enabled. Exiting."
    exit 1
fi

# Success message
echo "SSH setup completed successfully. You can now connect to your macOS system via SSH."
