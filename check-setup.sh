#!/usr/bin/env bash
set -u

# --help / -h -> description, exit 0 (P101 uniform CLI help)
case " $* " in
  *" --help "*|*" -h "*)
    cat <<'P101_USAGE'
check-setup.sh — takes no command-line options; run with no arguments.
P101_USAGE
    exit 0 ;;
esac

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
  "gcovr"
  "git"
  "gpg"
  "gp"
  "hping3"
  "lsof"
  "make"
  "nano"
  "ncat"
  "nmap"
  "ping"
  "pax"
  "python3"
  "shellcheck"
  "socat"
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
    programs+=("strace" "wireshark" "iperf3" "valgrind" "gdb")
elif [ "$platform" = "FreeBSD" ]; then
    programs+=("ktrace" "valgrind" "gdb")
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

# Exit with the count of missing programs (capped: exit codes wrap past 255)
[ "$missing" -gt 255 ] && missing=255
exit "$missing"
