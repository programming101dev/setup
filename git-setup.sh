#!/usr/bin/env bash
# git-setup.sh — one-time personal git setup: your identity plus an SSH key for
# GitHub. UNIX-native (needs git + ssh-keygen, both installed by ./setup.sh).
# Safe to re-run: it updates the identity you give it and NEVER overwrites an
# existing SSH key.
set -euo pipefail

case " $* " in *" --help "*|*" -h "*)
  cat <<'USAGE'
Usage: git-setup.sh [-n "Your Name"] [-e you@example.com]
  Sets your global git user.name / user.email (prompts if not given), then, if
  you don't already have one, generates an ed25519 SSH key and prints the public
  key to add to GitHub. Re-runnable; never overwrites an existing key.
USAGE
  exit 0 ;;
esac

handle_error() { echo "Error: $1" >&2; exit 1; }

target_user="${SUDO_USER:-$(id -un)}"
if command -v getent >/dev/null 2>&1; then
  target_home="$(getent passwd "$target_user" | cut -d: -f6)"
else
  target_home="$(eval "printf %s \~$target_user")"
fi
[ -n "$target_home" ] || target_home="$HOME"

name=""; email=""
while getopts ":n:e:" opt; do
  case "$opt" in
    n) name="$OPTARG" ;;
    e) email="$OPTARG" ;;
    *) handle_error "usage: $0 [-n \"Your Name\"] [-e you@example.com]" ;;
  esac
done

command -v git       >/dev/null 2>&1 || handle_error "git is not installed (run ./setup.sh first)."
command -v ssh-keygen >/dev/null 2>&1 || handle_error "ssh-keygen is not installed."

# --- identity ---------------------------------------------------------------
[ -n "$name" ]  || { printf 'Your full name: ' >&2; IFS= read -r name; }
[ -n "$email" ] || { printf 'Your email:     ' >&2; IFS= read -r email; }
[ -n "$name" ]  || handle_error "a name is required."
[ -n "$email" ] || handle_error "an email is required."

HOME="$target_home" git config --global user.name  "$name"  || handle_error "failed to set git user.name."
HOME="$target_home" git config --global user.email "$email" || handle_error "failed to set git user.email."
HOME="$target_home" git config --global init.defaultBranch main >/dev/null 2>&1 || true
echo "git identity set: $name <$email>"

# --- SSH key for GitHub -----------------------------------------------------
key="$target_home/.ssh/id_ed25519"
if [ -f "$key" ]; then
  echo "An SSH key already exists at $key — leaving it untouched."
else
  echo "Generating an ed25519 SSH key at $key ..."
  mkdir -p "$target_home/.ssh" && chmod 700 "$target_home/.ssh"
  ssh-keygen -t ed25519 -C "$email" -f "$key" -N "" || handle_error "ssh-keygen failed."
  chown -R "$target_user" "$target_home/.ssh" || handle_error "failed to set SSH key ownership."
fi

echo
echo "Your PUBLIC key (safe to share) — add it to GitHub:"
echo "----------------------------------------------------------------------"
cat "$key.pub"
echo "----------------------------------------------------------------------"
echo "  1. Copy the line above."
echo "  2. Open https://github.com/settings/ssh/new"
echo "  3. Paste it as a new SSH key and save."
echo
echo "Then verify with:  ssh -T git@github.com"
