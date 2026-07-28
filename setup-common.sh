#!/usr/bin/env bash
# Shared, side-effect-free helpers for setup entrypoints.

p101_user_home() {
    local user="$1"
    local home=""

    if command -v getent >/dev/null 2>&1; then
        home="$(getent passwd "$user" 2>/dev/null | awk -F: 'NR == 1 { print $6 }')"
    elif command -v dscl >/dev/null 2>&1; then
        home="$(dscl . -read "/Users/$user" NFSHomeDirectory 2>/dev/null | awk 'NR == 1 { print $2 }')"
    elif [[ "$user" == "$(id -un)" ]]; then
        home="${HOME:-}"
    fi

    [[ -n "$home" && "$home" == /* ]] || return 1
    printf '%s\n' "$home"
}

p101_download_https() {
    local url="$1"
    local destination="$2"

    [[ "$url" == https://* ]] || {
        printf 'Error: refusing non-HTTPS download: %s\n' "$url" >&2
        return 1
    }
    command -v curl >/dev/null 2>&1 || {
        echo "Error: curl is required for this download." >&2
        return 1
    }
    curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location \
        --output "$destination" "$url" || return 1
    [[ -s "$destination" ]] || {
        printf 'Error: download was empty: %s\n' "$url" >&2
        return 1
    }
}
