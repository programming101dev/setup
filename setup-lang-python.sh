#!/usr/bin/env bash
# setup-lang-python.sh — ensure Python 3 + pip, then install productive CLI tools
# in isolation via pipx: ruff (lint+format), mypy (types), pytest (test runner),
# ipython (REPL). Opt-in; safe to re-run. Per-project deps belong in a venv.
set -euo pipefail
case " $* " in *" --help "*|*" -h "*)
  printf '%s\n' "setup-lang-python.sh — ensures python3+pip, installs pipx + ruff/mypy/pytest/ipython. No options."; exit 0 ;;
esac
handle_error() { echo "Error: $1" >&2; exit 1; }

if ! command -v python3 >/dev/null 2>&1; then
  os="$(uname -s)"
  echo "Installing Python 3 for $os ..."
  case "$os" in
    Darwin)  command -v brew >/dev/null 2>&1 || handle_error "Homebrew required."
             brew install python || handle_error "brew install python failed." ;;
    FreeBSD) sudo pkg install -y python3 || handle_error "pkg install python3 failed." ;;
    Linux)
      if   command -v apt-get >/dev/null 2>&1; then
             sudo apt-get update || handle_error "apt update failed."
             sudo apt-get install -y python3 python3-pip python3-venv || handle_error "apt install python3 failed."
      elif command -v dnf >/dev/null 2>&1; then
             sudo dnf install -y python3 python3-pip || handle_error "dnf install python3 failed."
      elif command -v pacman >/dev/null 2>&1; then
             sudo pacman -S --noconfirm python python-pip || handle_error "pacman install python failed."
      else handle_error "no supported package manager found."; fi ;;
    *) handle_error "unsupported OS: $os" ;;
  esac
fi
command -v python3 >/dev/null 2>&1 || handle_error "python3 not on PATH."

# pipx keeps each CLI tool in its own venv so the system Python stays clean.
if ! command -v pipx >/dev/null 2>&1 && ! python3 -m pipx --version >/dev/null 2>&1; then
  echo "Installing pipx ..."
  python3 -m pip install --user pipx 2>/dev/null \
    || python3 -m pip install --user --break-system-packages pipx \
    || handle_error "pipx install failed (ensure pip is installed)."
  python3 -m pipx ensurepath || handle_error "pipx could not add its binary directory to PATH."
fi

for tool in ruff mypy pytest ipython; do
  echo "Ensuring $tool is installed and current ..."
  python3 -m pipx upgrade "$tool" 2>/dev/null ||
    python3 -m pipx install "$tool" ||
    handle_error "pipx install/upgrade $tool failed."
done

echo
echo "Python ready: ruff (lint+format), mypy (types), pytest (test), ipython (REPL)."
echo "For project dependencies use a venv:  python3 -m venv .venv && . .venv/bin/activate"
