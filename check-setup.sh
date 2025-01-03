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
  "lsof"
  "make"
  "nano"
  "nmap"
  "ping"
  "pax"
  "python3"
  "ssh"
  "sudo"
  "tcpdump"
  "tmux"
  "traceroute"
  "wget"
)

# Get the system's platform using uname
platform=$(uname)

# Adjust programs list based on platform
if [ "$platform" = "Linux" ]; then
    programs+=("strace" "wireshark")
elif [ "$platform" = "FreeBSD" ]; then
    programs+=("ktrace")
elif [ "$platform" = "Darwin" ]; then  # macOS
    programs+=("/Applications/Wireshark.app/Contents/MacOS/Wireshark")
fi

# Initialize a variable to count missing programs
missing=0

# Check if each program exists
for prog in "${programs[@]}"; do
    if ! command -v "$prog" &> /dev/null; then
        echo "$prog is not installed."
        ((missing++))
    fi
done

# Check if any programs are missing
if [ "$missing" -eq 0 ]; then
    echo "Everything is installed."
fi

# Exit with the count of missing programs
exit "$missing"
