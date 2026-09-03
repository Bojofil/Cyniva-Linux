#!/usr/bin/env bash
set -euo pipefail

PROFILE=/etc/dconf/profile/user
mkdir -p /etc/dconf/profile

# Do NOT blindly overwrite the profile. Bluefin may list databases of its own,
# and clobbering the file would silently drop them. Only add what is missing.
if [[ -f "$PROFILE" ]]; then
    echo "==> Existing dconf profile:"
    cat "$PROFILE"
    grep -q '^system-db:local$' "$PROFILE" || echo 'system-db:local' >> "$PROFILE"
else
    printf 'user-db:user\nsystem-db:local\n' > "$PROFILE"
fi

echo "==> Final dconf profile:"
cat "$PROFILE"

# Compiles every database under /etc/dconf/db/*.d -- picks up `local`
# (user defaults, extensions, wallpaper) and `gdm` (login screen branding).
dconf update

echo "==> Compiled databases:"
ls -1 /etc/dconf/db/ 2>/dev/null || true
