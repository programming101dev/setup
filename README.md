# Programming 101 — Machine Setup

This repository sets up a development machine for the Programming 101 courses
(C programming, plus cyber operations and security). Students run UNIX natively:
macOS, Linux (Ubuntu, Fedora, or Manjaro — with Debian/Kali, RHEL, and Arch
handled by family), or FreeBSD.

## Quick start

```bash
mkdir -p ~/work/programming101dev
git clone https://github.com/programming101dev/setup ~/work/programming101dev/setup
cd ~/work/programming101dev/setup

./setup.sh            # detect your OS and install the toolchain (then reboot)
./check-setup.sh      # verify everything is installed
./git-setup.sh        # set your git identity + a GitHub SSH key (one time)
./setup-libraries.sh  # fetch the p101 library build system (follow its output)
```

`setup.sh` picks the right per-OS installer automatically — you never call
`setup-ubuntu.sh`, `setup-macos.sh`, etc. directly. On a fresh Mac it also
installs Homebrew (and the Xcode Command Line Tools) for you.

## What gets installed

The package list lives in **`packages.txt`** — one row per tool, with the
package name for each OS. It is the single source of truth: edit it (not the
per-OS scripts) to change what gets installed. `./list-packages.sh <os>` prints
the resolved list for a platform.

FreeBSD includes `libxcrypt` in the package list because `lib_posix_xsi` wraps
`crypt()` as `p101_crypt()`, and the FreeBSD CI image links that interface
through the installed crypt library rather than only the base C library.

On FreeBSD teaching/lab VMs, `setup-freebsd.sh` also installs a sudoers rule
that lets every local user run `sudo` with their own password. This is
deliberate for disposable course machines; do not use that rule on a shared or
production FreeBSD host.

## Scripts

**Base setup**

- `setup.sh` — detect the OS and run the right installer. `--sshd` and `--apps`
  also run the SSH-server and GUI-app companions.
- `check-setup.sh` — verify all required tools are present.
- `update.sh` — update the OS **and** install any packages newly added to
  `packages.txt`, so an already-set-up machine stays current.

**One-time personal setup**

- `git-setup.sh` — set your git `user.name` / `user.email` and generate an
  SSH key to add to GitHub. Safe to re-run; never overwrites an existing key.
- `setup-libraries.sh` — clone the p101 `scripts` repo (the library/example
  build system) next to this one, then tells you how to build.

**Optional**

- `setup-lang.sh <rust|go|python|node>` — install another language toolchain
  with its lint/format/test tools. C needs nothing extra; these are opt-in.
- `setup-<os>-sshd.sh` — enable the SSH server (via `./setup.sh --sshd`).
- `setup-<os>-apps.sh` — install GUI apps like JetBrains Toolbox (via
  `./setup.sh --apps`). macOS and FreeBSD currently have no required GUI app
  bundle, so their companion scripts are explicit no-ops.
- `disable-firewall.sh` — drop all packet filtering to a known baseline
  (teaching/lab machines only).
- `ip-prompt.sh` — `source` it to show your current IP in the shell prompt.
- `zero.sh` — zero free space before imaging a VM.

Every script supports `--help`.

## Keeping current

Run `./update.sh` whenever you like. It updates your OS packages and pulls in
any tools added to `packages.txt` since you set up, keeping your machine in
lock-step with the course toolchain.

## Supported platforms

macOS, Ubuntu (and Debian/Kali), Fedora (and the RHEL family), Manjaro (and
Arch), and FreeBSD. Windows is not supported — install a UNIX natively or use a
Linux virtual machine.
