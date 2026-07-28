#!/usr/bin/env bash
# update.sh - unified updater for macOS, Linux distros, and FreeBSD

set -euo pipefail

# --help / -h -> description, exit 0 (P101 uniform CLI help)
case " $* " in
  *" --help "*|*" -h "*)
    cat <<'P101_USAGE'
update.sh - unified updater for macOS, Linux distros, and FreeBSD
Also installs any base packages newly added to packages.txt.
P101_USAGE
    exit 0 ;;
esac
IFS=$' \t\n'

# Directory of this script, so we can find list-packages.sh / packages.txt.
SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

die() { printf "Error: %s\n" "$*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  else
    need_cmd sudo
    sudo "$@"
  fi
}

# --- package sync -----------------------------------------------------------
# Install the base package set from packages.txt (the single source of truth),
# so a machine that ran setup.sh earlier picks up packages added since. Package
# managers no-op on already-installed packages, so this is safe every run.
install_pkgs_apt()    { local p; for p in "$@"; do as_root apt-get install -y "$p"; done; }
install_pkgs_dnf()    { local p; for p in "$@"; do as_root dnf install -y "$p"; done; }
install_pkgs_pacman() { as_root pacman -S --needed --noconfirm "$@"; }
install_pkgs_pkg()    { local p; for p in "$@"; do as_root pkg install -y "$p"; done; }
install_pkgs_brew()   { local p; for p in "$@"; do brew list --formula "$p" >/dev/null 2>&1 || brew install "$p"; done; }

sync_packages() {  # $1 = os key for list-packages.sh   $2 = installer function
  local oskey="$1" inst="$2" list="$SCRIPT_DIR/list-packages.sh" pkgs
  if [[ ! -x "$list" ]]; then
    die "package-list reader is missing or not executable: $list"
  fi
  echo "Syncing base packages from packages.txt ($oskey)..."
  pkgs="$("$list" "$oskey")" || die "could not read package list for $oskey"
  [[ -n "$pkgs" ]] || die "empty package list for $oskey"
  # shellcheck disable=SC2086  # word splitting intended: one package per line
  $inst $pkgs
}

update_macos() {
  echo "Detected macOS."

  if have_cmd brew; then
    echo "Updating Homebrew packages..."
    brew update
    brew upgrade
    sync_packages macos install_pkgs_brew
  else
    die "Homebrew not found; cannot update the declared macOS package set"
  fi

  echo "Running macOS Software Update..."
  as_root softwareupdate --install --all
}

update_apt_like() {
  echo "Updating with APT..."
  as_root apt-get update
  as_root apt-get -y dist-upgrade
  sync_packages ubuntu install_pkgs_apt
}

update_dnf_like() {
  echo "Updating with DNF..."
  as_root dnf upgrade --refresh -y
  sync_packages fedora install_pkgs_dnf
}

update_pacman_like() {
  echo "Updating with Pacman..."
  as_root pacman -Syu --noconfirm
  sync_packages manjaro install_pkgs_pacman
}

update_manjaro() {
  echo "Detected Manjaro."
  update_pacman_like

  if have_cmd yay; then
    echo "Updating AUR packages with yay..."
    yay -Syu --noconfirm
  fi
}

is_freebsd_pkgbase() {
  if ! have_cmd pkg; then
    return 1
  fi

  pkg info -e FreeBSD-runtime >/dev/null 2>&1 && return 0
  pkg info -e FreeBSD-kernel >/dev/null 2>&1 && return 0
  pkg info -e FreeBSD-clibs >/dev/null 2>&1 && return 0

  return 1
}

update_freebsd_classic() {
  local fetch_output

  echo "Detected traditional FreeBSD base."
  need_cmd freebsd-update

  echo "Checking FreeBSD base system updates..."
  fetch_output="$(as_root freebsd-update fetch 2>&1)" || die "freebsd-update fetch failed"
  printf '%s\n' "$fetch_output"

  if printf '%s\n' "$fetch_output" | grep -Fq "No updates needed"; then
    echo "FreeBSD base system is already up to date."
  else
    echo "Installing FreeBSD base system updates..."
    as_root freebsd-update install
  fi

  if have_cmd pkg; then
    echo "Updating packages..."
    as_root pkg update
    as_root pkg upgrade -y
    sync_packages freebsd install_pkgs_pkg
  else
    die "pkg not found; cannot update the declared FreeBSD package set"
  fi
}

update_freebsd_pkgbase() {
  echo "Detected FreeBSD pkgbase."
  need_cmd pkg

  echo "Updating pkg repositories..."
  as_root pkg update

  echo "Upgrading FreeBSD base packages and installed packages..."
  as_root pkg upgrade -y
  sync_packages freebsd install_pkgs_pkg
}

update_freebsd() {
  echo "Detected FreeBSD."

  if is_freebsd_pkgbase; then
    update_freebsd_pkgbase
    return
  fi

  if have_cmd freebsd-update; then
    update_freebsd_classic
    return
  fi

  if have_cmd pkg; then
    echo "Could not confirm traditional base or pkgbase explicitly."
    echo "Falling back to pkg upgrade."
    as_root pkg update
    as_root pkg upgrade -y
    sync_packages freebsd install_pkgs_pkg
    return
  fi

  die "could not determine how to update this FreeBSD system"
}

update_linux() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    . /etc/os-release
  else
    die "cannot detect Linux distribution, /etc/os-release missing"
  fi

  distro_id="${ID:-}"
  distro_like="${ID_LIKE:-}"

  case "$distro_id" in
    ubuntu|kali|debian)
      update_apt_like
      ;;
    fedora)
      update_dnf_like
      ;;
    manjaro)
      update_manjaro
      ;;
    arch)
      update_pacman_like
      ;;
    *)
      case "$distro_like" in
        *debian*)
          update_apt_like
          ;;
        *rhel*|*fedora*)
          update_dnf_like
          ;;
        *arch*)
          update_pacman_like
          ;;
        *)
          die "unsupported Linux distribution: ${distro_id:-unknown} (ID_LIKE='${distro_like:-unset}')"
          ;;
      esac
      ;;
  esac
}

main() {
  local os
  os="$(uname -s)"

  case "$os" in
    Darwin)
      update_macos
      ;;
    Linux)
      update_linux
      ;;
    FreeBSD)
      update_freebsd
      ;;
    *)
      die "unsupported operating system: $os"
      ;;
  esac
}

main "$@"
