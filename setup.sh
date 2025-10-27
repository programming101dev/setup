#!/usr/bin/env bash
# setup.sh, unified OS/distro setup runner
# Calls per-OS scripts:
#   setup-{fedora,ubuntu,manjaro,freebsd,macos}.sh
# Optional flags:
#   --sshd  -> also call setup-*-sshd.sh
#   --apps  -> also call setup-*-apps.sh

set -euo pipefail
IFS=$' \t\n'

die() { printf "Error: %s\n" "$*" >&2; exit 1; }
note() { printf "%s\n" "$*"; }

usage() {
  cat <<'USAGE'
Usage: setup.sh [--sshd] [--apps]

Runs the base setup script for the detected platform, and optionally
the companion scripts for SSH daemon and app bundles.

Base scripts (must exist and be executable in the current directory):
  setup-fedora.sh
  setup-ubuntu.sh
  setup-manjaro.sh
  setup-freebsd.sh
  setup-macos.sh

Optional scripts (only invoked when corresponding flag is given):
  --sshd : setup-*-sshd.sh
  --apps : setup-*-apps.sh

Examples:
  ./setup.sh
  ./setup.sh --sshd
  ./setup.sh --apps --sshd
USAGE
  exit 1
}

# ----------------- flag parsing -----------------
want_sshd=false
want_apps=false

while (($#)); do
  case "$1" in
    --sshd) want_sshd=true ;;
    --apps) want_apps=true ;;
    -h|--help) usage ;;
    --) shift; break ;;
    -*) die "unknown option: $1" ;;
    *) die "unexpected positional argument: $1" ;;
  esac
  shift
done

# ----------------- helpers -----------------
must_exec() {
  local path="$1"
  [[ -x "$path" ]] || die "required script is missing or not executable: $path"
}

run_script() {
  local script="$1"
  must_exec "./$script"
  note "==> Running ./$script"
  "./$script"
}

maybe_run() {
  local script="$1"
  if [[ -x "./$script" ]]; then
    note "==> Running ./$script"
    "./$script"
  else
    die "expected script not found or not executable: ./$script"
  fi
}

pick_linux_family() {
  # Echo one of: ubuntu, fedora, manjaro
  # We route debian/kali to ubuntu, arch to manjaro, rhel/centos to fedora.
  [[ -f /etc/os-release ]] || die "cannot detect Linux distribution, /etc/os-release missing"
  # shellcheck disable=SC1091
  . /etc/os-release
  local id="${ID:-}" like="${ID_LIKE:-}"

  case "$id" in
    ubuntu|kali|debian) echo "ubuntu" ;;
    fedora)             echo "fedora" ;;
    manjaro)            echo "manjaro" ;;
    arch)               echo "manjaro" ;;
    *)  # fallback using ID_LIKE
      case "$like" in
        *debian*) echo "ubuntu" ;;
        *rhel*|*fedora*) echo "fedora" ;;
        *arch*) echo "manjaro" ;;
        *) die "unsupported Linux distribution: ${id:-unknown} (ID_LIKE='${like:-unset}')" ;;
      esac
      ;;
  esac
}

# ----------------- main dispatch -----------------
os="$(uname -s)"
case "$os" in
  Darwin)
    base="macos"
    ;;
  FreeBSD)
    base="freebsd"
    ;;
  Linux)
    base="$(pick_linux_family)"
    ;;
  *)
    die "unsupported operating system: $os"
    ;;
esac

# Base script
run_script "setup-${base}.sh"

# Optional sshd
if $want_sshd; then
  maybe_run "setup-${base}-sshd.sh"
fi

# Optional apps
if $want_apps; then
  maybe_run "setup-${base}-apps.sh"
fi

note "Setup completed for ${base}."
