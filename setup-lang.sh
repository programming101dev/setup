#!/usr/bin/env bash
# setup-lang.sh — optional per-language dev environment installer.
#
# These are NOT part of the base setup (setup.sh). C is the only language the
# courses require; students are free to use others, and this installs a
# productive toolchain (compiler/runtime + lint, format, test, LSP) for whichever
# they pick. Each language script can also be run directly (./setup-lang-rust.sh).
set -euo pipefail
CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

usage() {
  cat <<'USAGE'
Usage: setup-lang.sh <rust|go|python|node>
  Installs the chosen language toolchain plus productive tools:
    rust   -> rustup (rustc/cargo) + clippy, rustfmt, rust-analyzer
    go     -> go + gopls, staticcheck, delve
    python -> python3/pip + pipx: ruff, mypy, pytest, ipython
    node   -> nvm + latest LTS node/npm + typescript, eslint, prettier
  Each installs from the language's own upstream and is safe to re-run.
USAGE
  exit "${1:-1}"
}
case " $* " in *" --help "*|*" -h "*) usage 0 ;; esac
[ "$#" -eq 1 ] || usage 1

case "$1" in
  rust|go|python|node) exec "./setup-lang-$1.sh" ;;
  *) echo "Unknown language: $1 (want rust|go|python|node)" >&2; usage 1 ;;
esac
