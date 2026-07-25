#!/usr/bin/env bash
# setup-lang-rust.sh — install Rust via rustup, plus the tools to be productive:
# clippy (lint), rustfmt (format), rust-analyzer (LSP). Testing is built into
# cargo (cargo test). Opt-in; not part of the base setup. Safe to re-run.
set -euo pipefail
case " $* " in *" --help "*|*" -h "*)
  printf '%s\n' "setup-lang-rust.sh — installs rustup + clippy/rustfmt/rust-analyzer. No options."; exit 0 ;;
esac
handle_error() { echo "Error: $1" >&2; exit 1; }

if command -v rustup >/dev/null 2>&1; then
  echo "rustup already installed; updating toolchain..."
  rustup update || handle_error "rustup update failed."
else
  command -v curl >/dev/null 2>&1 || handle_error "curl is required to install rustup."
  echo "Installing rustup (downloads from https://sh.rustup.rs) ..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    || handle_error "rustup install failed."
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
