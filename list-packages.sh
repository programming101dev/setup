#!/bin/sh
# list-packages.sh — read packages.txt (the single source of truth for package
# names on every supported OS) and print what to install, one package per line.
# POSIX sh + awk only, so it works on a fresh machine before anything is set up.
set -eu

usage() {
  cat <<'USAGE'
Usage: list-packages.sh <os> [tool]
  os    ubuntu | fedora | manjaro | freebsd | macos
  tool  optional: print only this tool's package(s), from any group
Without a tool, prints every 'base'-group package for that OS (what
setup-<os>.sh installs). "-" cells print nothing. Exits 1 on an unknown tool
or a malformed table row.
USAGE
  exit "${1:-0}"
}
case " $* " in *" --help "*|*" -h "*) usage 0 ;; esac
[ $# -ge 1 ] || usage 2

dir=$(CDPATH='' CDPATH= cd -- "$(dirname -- "$0")" && pwd)
os="$1"; tool="${2:-}"
case "$os" in
  ubuntu) col=3 ;; fedora) col=4 ;; manjaro) col=5 ;; freebsd) col=6 ;; macos) col=7 ;;
  *) echo "Unknown OS: $os (want ubuntu|fedora|manjaro|freebsd|macos)" >&2; exit 2 ;;
esac
[ -f "$dir/packages.txt" ] || { echo "packages.txt not found in $dir" >&2; exit 1; }

awk -v col="$col" -v tool="$tool" '
  /^[[:space:]]*(#|$)/ { next }
  NF != 7 { printf "packages.txt:%d: expected 7 columns, got %d\n", NR, NF > "/dev/stderr"; bad=1; next }
  {
    if (tool != "") { if ($1 != tool) next }
    else if ($2 != "base") next
    found = 1
    if ($col != "-") { n = split($col, a, ","); for (i = 1; i <= n; i++) print a[i] }
  }
  END {
    if (bad) exit 1
    if (tool != "" && !found) { printf "unknown tool: %s\n", tool > "/dev/stderr"; exit 1 }
  }
' "$dir/packages.txt"
