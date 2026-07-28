#!/usr/bin/env bash
# setup-lang-rust.sh — install Rust via rustup, plus the tools to be productive:
# clippy (lint), rustfmt (format), rust-analyzer (LSP). Testing is built into
# cargo (cargo test). Opt-in; not part of the base setup. Safe to re-run.
set -euo pipefail
case " $* " in *" --help "*|*" -h "*)
  printf '%s\n' "setup-lang-rust.sh — installs rustup + clippy/rustfmt/rust-analyzer. No options."; exit 0 ;;
esac
handle_error() { echo "Error: $1" >&2; exit 1; }

script_dir="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=setup-common.sh
. "$script_dir/setup-common.sh" || handle_error "could not load setup-common.sh."

if command -v rustup >/dev/null 2>&1; then
  echo "rustup already installed; updating toolchain..."
  rustup update || handle_error "rustup update failed."
else
  echo "Installing rustup (downloads from https://sh.rustup.rs) ..."
  installer="$(mktemp "${TMPDIR:-/tmp}/p101-rustup-install.XXXXXX")" \
    || handle_error "could not create a temporary installer file."
  p101_download_https "https://sh.rustup.rs" "$installer" \
    || handle_error "could not download the rustup installer."
  sh "$installer" -y || handle_error "rustup install failed."
  rm -f -- "$installer" || handle_error "could not remove the rustup installer."
fi

# Load cargo/rustup into THIS shell so the component step works immediately.
# shellcheck disable=SC1091
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
command -v rustup >/dev/null 2>&1 || handle_error "rustup not on PATH; open a new shell and re-run."

echo "Adding components: clippy, rustfmt, rust-analyzer ..."
rustup component add clippy rustfmt rust-analyzer || handle_error "failed to add rust components."

echo
echo "Rust ready: cargo (build/test), clippy (lint), rustfmt (format), rust-analyzer (LSP)."
echo "New shells pick up ~/.cargo/bin automatically (rustup edited your shell profile)."
