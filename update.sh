#!/usr/bin/env bash
# update-system.sh - unified updater for macOS, Linux distros, and FreeBSD

set -euo pipefail
IFS=$' \t\n'

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

update_macos() {
  echo "Detected macOS."

  if have_cmd brew; then
    echo "Updating Homebrew packages..."
    brew update
    brew upgrade
  else
    echo "Homebrew not found, skipping."
  fi

  echo "Running macOS Software Update..."
  as_root softwareupdate --install --all
}

update_apt_like() {
  echo "Updating with APT..."
  as_root apt-get update
  as_root apt-get -y dist-upgrade
}

update_dnf_like() {
  echo "Updating with DNF..."
  as_root dnf upgrade --refresh -y
}

update_pacman_like() {
  echo "Updating with Pacman..."
  as_root pacman -Syu --noconfirm
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
  echo "Detected traditional FreeBSD base."
  need_cmd freebsd-update

  echo "Updating FreeBSD base system with freebsd-update..."
  as_root freebsd-update fetch install

  if have_cmd pkg; then
    echo "Updating packages..."
    as_root pkg update
    as_root pkg upgrade -y
  else
    echo "pkg not found, skipping package updates."
  fi
}

update_freebsd_pkgbase() {
  echo "Detected FreeBSD pkgbase."

  need_cmd pkg

  echo "Updating pkg repositories..."
  as_root pkg update

  echo "Upgrading FreeBSD base packages and installed packages..."
  as_root pkg upgrade -y
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