#!/usr/bin/env bash
set -euo pipefail

# --help / -h -> description, exit 0 (P101 uniform CLI help)
case " $* " in
  *" --help "*|*" -h "*)
    cat <<'P101_USAGE'
setup-macos.sh — takes no command-line options; run with no arguments.
P101_USAGE
    exit 0 ;;
esac

# Function to log and handle errors
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

script_dir="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=setup-common.sh
. "$script_dir/setup-common.sh" || handle_error "could not load setup-common.sh."

# --- Homebrew bootstrap -----------------------------------------------------
# This script is built on Homebrew. Install it if missing (its installer also
# pulls the Xcode Command Line Tools), then load it into THIS shell and persist
# its environment in /etc/zshenv so future shells find it. All guarded so
# re-running never duplicates anything.
if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found; installing (this also installs the Xcode Command Line Tools)..."
    installer="$(mktemp "${TMPDIR:-/tmp}/p101-homebrew-install.XXXXXX")" \
        || handle_error "could not create a temporary installer file."
    p101_download_https "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" "$installer" \
        || handle_error "could not download the Homebrew installer."
    /bin/bash "$installer" || handle_error "Homebrew installation failed."
    rm -f -- "$installer" || handle_error "could not remove the Homebrew installer."
fi

# Locate brew (Apple Silicon /opt/homebrew, Intel /usr/local) and load it now.
BREW=""
for _b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$_b" ] && { BREW="$_b"; break; }
done
[ -n "$BREW" ] || BREW="$(command -v brew || true)"
[ -n "$BREW" ] || handle_error "Homebrew installed but 'brew' not found on PATH."
eval "$("$BREW" shellenv)"

# Persist brew's environment for future login shells (idempotent).
if ! grep -qsF "$BREW shellenv" /etc/zshenv; then
    echo "eval \"\$($BREW shellenv)\"" | sudo tee -a /etc/zshenv >/dev/null \
        || handle_error "Failed to add brew shellenv to /etc/zshenv."
fi
# ---------------------------------------------------------------------------

# List of packages to install with Homebrew
# Package names come from packages.txt (single source of truth for every OS)
# via list-packages.sh -- edit packages.txt, not this script, to change them.
brew_packages=()
brew_package_list="$("$(dirname -- "$0")/list-packages.sh" macos)" || handle_error "failed to read packages.txt"
while IFS= read -r _p; do brew_packages+=("$_p"); done <<< "$brew_package_list"
[ "${#brew_packages[@]}" -gt 0 ] || handle_error "no packages resolved from packages.txt"

# Install packages with Homebrew
for package in "${brew_packages[@]}"; do
    echo "Installing $package with Homebrew..."
    brew install "$package" || handle_error "Failed to install $package with Homebrew."
done

# Disable the nano malloc zone (interferes with the sanitizers). Guarded so
# re-running setup never duplicates the line.
if ! grep -qs 'MallocNanoZone=0' /etc/zshenv; then
    sudo bash -c 'echo "export MallocNanoZone=0" >> /etc/zshenv' || handle_error "Failed to add MallocNanoZone to /etc/zshenv."
fi

# brew's llvm is keg-only; put its bin on PATH so the p101 clang tools (clang-tidy,
# clang-format) and the fuzzer-capable clang resolve. Persisted, idempotent.
_llvm_bin="$("$BREW" --prefix llvm 2>/dev/null)/bin"
if [ -d "$_llvm_bin" ] && ! grep -qsF "$_llvm_bin" /etc/zshenv; then
    echo "export PATH=\"$_llvm_bin:\$PATH\"" | sudo tee -a /etc/zshenv >/dev/null \
        || handle_error "Failed to add llvm to PATH in /etc/zshenv."
fi

# Completion message
echo "All tools installed and configured successfully. Please reboot your computer for changes to take effect."
