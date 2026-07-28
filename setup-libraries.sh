#!/usr/bin/env bash
# setup-libraries.sh — clone (or update) the programming101dev "scripts" repo,
# the p101 library/example build system, into place next to this "setup" repo.
#
# It does NOT build anything: after this finishes, run scripts/setup.sh with the
# compilers you want to clone + build + install the libraries and examples. Run
# this AFTER ./setup.sh, which installs git and the compilers/tools.
set -euo pipefail
CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

case " $* " in *" --help "*|*" -h "*)
  cat <<'USAGE'
setup-libraries.sh — clone (or update) the p101 "scripts" repo next to setup/.
Takes no options. When it finishes, build the libraries with your compilers:
  cd ../scripts && ./setup.sh -c <c-compiler> -x <c++-compiler>
USAGE
  exit 0 ;;
esac

handle_error() { echo "Error: $1" >&2; exit 1; }

REPO_URL="https://github.com/programming101dev/scripts.git"
workspace="$(cd -- .. && pwd)"      # parent of the setup repo (…/programming101dev)
dest="$workspace/scripts"

command -v git >/dev/null 2>&1 || handle_error "git is required; run ./setup.sh first."

if [ -e "$dest" ] && [ ! -d "$dest/.git" ]; then
  handle_error "$dest exists but is not a git checkout; move it aside and re-run."
fi

if [ -d "$dest/.git" ]; then
  echo "Updating the existing scripts repo in $dest ..."
  git -C "$dest" pull --ff-only || handle_error "git pull failed in $dest."
else
  echo "Cloning $REPO_URL into $dest ..."
  git clone "$REPO_URL" "$dest" || handle_error "git clone failed."
fi

echo
echo "Done. The p101 build system is in: $dest"
echo "Next, build and install the libraries with your compilers, for example:"
echo "  cd \"$dest\" && ./setup.sh -c clang -x clang++"
echo "(run ./check-compilers.sh in that repo to see the compilers detected here)"
