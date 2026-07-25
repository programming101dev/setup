#!/usr/bin/env bash
# setup-lang-go.sh — install Go (via your OS package manager) plus productive
# tools: gopls (LSP), staticcheck (lint/analysis), delve (dlv debugger). Testing
# and formatting are built in (go test, gofmt). Opt-in; safe to re-run.
set -euo pipefail
case " $* " in *" --help "*|*" -h "*)
  printf '%s\n' "setup-lang-go.sh — installs Go + gopls/staticcheck/delve. No options."; exit 0 ;;
esac
handle_error() { echo "Error: $1" >&2; exit 1; }

if command -v go >/dev/null 2>&1; then
  echo "Go already installed: $(go version)"
else
  os="$(uname -s)"
  echo "Installing Go for $os ..."
  case "$os" in
    Darwin)  command -v brew >/dev/null 2>&1 || handle_error "Homebrew required (see the macOS install doc)."
             brew install go || handle_error "brew install go failed." ;;
    FreeBSD) sudo pkg install -y go || handle_error "pkg install go failed." ;;
    Linux)
      if   command -v apt-get >/dev/null 2>&1; then
             sudo apt-get update || handle_error "apt update failed."
             sudo apt-get install -y golang || handle_error "apt install golang failed."
      elif command -v dnf >/dev/null 2>&1; then
             sudo dnf install -y golang || handle_error "dnf install golang failed."
      elif command -v pacman >/dev/null 2>&1; then
             sudo pacman -S --noconfirm go || handle_error "pacman install go failed."
      else handle_error "no supported package manager (apt/dnf/pacman) found."; fi ;;
    *) handle_error "unsupported OS: $os" ;;
  esac
fi
command -v go >/dev/null 2>&1 || handle_error "go not on PATH after install."

echo "Installing Go tools into $(go env GOPATH)/bin ..."
go install golang.org/x/tools/gopls@latest           || handle_error "gopls install failed."
go install honnef.co/go/tools/cmd/staticcheck@latest || handle_error "staticcheck install failed."
go install github.com/go-delve/delve/cmd/dlv@latest  || handle_error "delve install failed."

echo
echo "Go ready: go (build/test/fmt), gopls (LSP), staticcheck (lint), dlv (debug)."
echo "Add \$(go env GOPATH)/bin (usually ~/go/bin) to your PATH to run the installed tools."
