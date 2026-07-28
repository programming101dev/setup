#!/usr/bin/env bash
# setup-lang-node.sh — install Node.js via nvm (a per-user version manager) plus
# productive global tools: typescript, eslint, prettier. Node ships its own test
# runner (node --test). Opt-in; safe to re-run.
set -euo pipefail
case " $* " in *" --help "*|*" -h "*)
  printf '%s\n' "setup-lang-node.sh — installs nvm + LTS node/npm + typescript/eslint/prettier. No options."; exit 0 ;;
esac
handle_error() { echo "Error: $1" >&2; exit 1; }

script_dir="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=setup-common.sh
. "$script_dir/setup-common.sh" || handle_error "could not load setup-common.sh."

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  echo "Installing nvm (downloads from github.com/nvm-sh/nvm) ..."
  installer="$(mktemp "${TMPDIR:-/tmp}/p101-nvm-install.XXXXXX")" \
    || handle_error "could not create a temporary installer file."
  p101_download_https "https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh" "$installer" \
    || handle_error "could not download the nvm installer."
  bash "$installer" || handle_error "nvm install failed."
  rm -f -- "$installer" || handle_error "could not remove the nvm installer."
fi
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh" || handle_error "could not load nvm; open a new shell and re-run."

echo "Installing the latest LTS Node ..."
nvm install --lts || handle_error "node install failed."
nvm use --lts >/dev/null 2>&1 || handle_error "could not activate the LTS Node version."

echo "Installing global tools: typescript, eslint, prettier ..."
npm install -g typescript eslint prettier || handle_error "npm global install failed."

echo
echo "Node ready: node/npm, tsc (TypeScript), eslint (lint), prettier (format), 'node --test' (testing)."
echo "nvm loads per-shell from ~/.nvm (its installer added the lines to your shell profile)."
