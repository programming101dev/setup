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
    programs+=("gcovr" "strace" "wireshark" "iperf3" "valgrind" "gdb")
elif [ "$platform" = "FreeBSD" ]; then
    programs+=("ktrace" "valgrind" "gdb")
elif [ "$platform" = "Darwin" ]; then  # macOS
    programs+=("gcovr" "/Applications/Wireshark.app/Contents/MacOS/Wireshark")
fi

# Initialize a variable to count missing programs
missing=0

have_libclang_header() {
    local include_dir pattern

    if command -v llvm-config >/dev/null 2>&1; then
        include_dir="$(llvm-config --includedir 2>/dev/null || true)"
        if [ -n "$include_dir" ] && [ -f "$include_dir/clang-c/Index.h" ]; then
            return 0
        fi
    fi

    if command -v brew >/dev/null 2>&1; then
        include_dir="$(brew --prefix llvm 2>/dev/null || true)"
        if [ -n "$include_dir" ] && [ -f "$include_dir/include/clang-c/Index.h" ]; then
            return 0
        fi
    fi

    for pattern in \
        /usr/include/clang-c/Index.h \
        /usr/local/include/clang-c/Index.h \
        /usr/lib/llvm-*/include/clang-c/Index.h \
        /usr/local/llvm*/include/clang-c/Index.h \
        /opt/homebrew/opt/llvm/include/clang-c/Index.h \
        /usr/local/opt/llvm/include/clang-c/Index.h
    do
        if compgen -G "$pattern" >/dev/null; then
            return 0
        fi
    done
    return 1
}

# Check if each program exists
for prog in "${programs[@]}"; do
    if ! command -v "$prog" &> /dev/null; then
        echo "$prog is not installed."
        missing=$((missing + 1))
    fi
done

if ! have_libclang_header; then
    echo "clang-c/Index.h is not installed."
    case "$platform" in
        Linux) echo "Install it with: sudo apt install libclang-dev" ;;
        FreeBSD) echo "Install it with: pkg install llvm" ;;
        Darwin) echo "Install it with: brew install llvm" ;;
    esac
    missing=$((missing + 1))
fi

# Check if any programs are missing
if [ "$missing" -eq 0 ]; then
    echo "Everything is installed."
fi

# Exit with the count of missing programs (capped: exit codes wrap past 255)
[ "$missing" -gt 255 ] && missing=255
exit "$missing"
