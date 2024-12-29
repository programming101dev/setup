#!/usr/bin/env bash

# List of programs to check
programs=(
  "arp"
  "bash"
  "cmake"
  "clang"
  "clang++"
  "clang-format"
  "clang-tidy"
  "compress"
  "cppcheck"
  "curl"
  "dot"
  "g++"
  "gcc"
  "git"
  "gpg"
  "gp"
  "make"
  "nano"
  "ping"
  "pax"
  "ssh"
  "sudo"
  "tcpdump"
  "traceroute"
  "wget"
)

# Initialize a variable to count missing programs
missing=0

# Get the system's platform using uname
platform=$(uname)

# Check if each program exists
for prog in "${programs[@]}"; do
    if ! command -v "$prog" &> /dev/null; then
        # Exclude "strace" check on platforms other than Linux
        if [ "$platform" != "Linux" ] || [ "$prog" != "strace" ]; then
            echo "$prog is not installed."
            ((missing++))
        fi
    fi
done

# Check if any programs are missing
if [ "$missing" -eq 0 ]; then
    echo "Everything is installed."
fi

# Exit with the count of missing programs
exit "$missing"
