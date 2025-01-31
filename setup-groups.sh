#!/usr/bin/env bash

# Detect the operating system.
os=$(uname -s)

case "$os" in
    Linux)
        # Check if the group exists on Linux; if not, create it.
        if ! getent group devgroup > /dev/null 2>&1; then
            sudo groupadd devgroup
        fi
        # Add the current user to the group.
        sudo usermod -aG devgroup "$USER"
        ;;
    Darwin)
        # macOS
        # Check if the group exists; if not, create it using dseditgroup.
        if ! dscl . -list /Groups | grep -q "^devgroup$"; then
            sudo dseditgroup -o create devgroup
        fi
        # Add the current user to the group.
        sudo dseditgroup -o edit -a "$USER" -t user devgroup
        ;;
    FreeBSD)
        # FreeBSD
        # Check if the group exists by searching /etc/group; if not, create it.
        if ! grep -q '^devgroup:' /etc/group; then
            sudo pw groupadd devgroup
        fi
        # Add the current user to the group.
        sudo pw groupmod devgroup -m "$USER"
        ;;
    *)
        echo "Unsupported OS: $os"
        exit 1
        ;;
esac

# Process each directory only if it exists.
for dir in /usr/local/include /usr/local/lib /usr/local/lib64; do
    if [ -d "$dir" ]; then
        sudo chown -R root:devgroup "$dir"
        sudo chmod -R g+w "$dir"
        sudo chmod -R g+s "$dir"
    fi
done
