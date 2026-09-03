#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------
# Edit these
# ---------------------------------------------------------------------
BRAND_NAME="Cyniva Linux"
BRAND_URL_BASE="https://github.com/Bojofil/Cyniva-Linux"

# This script is shared by both images, so detect the desktop rather than
# hardcoding it. Keeps one script instead of two that drift apart.
if command -v plasmashell >/dev/null 2>&1; then
    BRAND_VARIANT="KDE Plasma"
    BRAND_VARIANT_ID="cyniva-kde"
elif command -v gnome-shell >/dev/null 2>&1; then
    BRAND_VARIANT="GNOME"
    BRAND_VARIANT_ID="cyniva-gnome"
else
    echo "ERROR: neither plasmashell nor gnome-shell found" >&2
    exit 1
fi
BRAND_PRETTY="${BRAND_NAME} (${BRAND_VARIANT})"
echo "==> Detected variant: ${BRAND_VARIANT}"
BRAND_URL="$BRAND_URL_BASE"
BRAND_LOGO="cyniva-logo"     # icon name, resolved from /usr/share/pixmaps

# ---------------------------------------------------------------------
# os-release
# ---------------------------------------------------------------------
# On Fedora, /etc/os-release is a symlink to /usr/lib/os-release, so we edit
# the real file. Shipping a replacement via the files module would clobber
# the symlink and confuse things.
#
# NOTE: ID is deliberately left as "fedora". A surprising amount of tooling
# branches on it -- distrobox, toolbox, some install scripts, package
# managers. Changing NAME/PRETTY_NAME/VARIANT gets you the cosmetics with
# none of the breakage.

OSR=/usr/lib/os-release

set_key() {
    local key="$1" val="$2"
    if grep -q "^${key}=" "$OSR"; then
        sed -i "s|^${key}=.*|${key}=\"${val}\"|" "$OSR"
    else
        echo "${key}=\"${val}\"" >> "$OSR"
    fi
}

set_key NAME          "$BRAND_NAME"
set_key PRETTY_NAME   "$BRAND_PRETTY"
set_key VARIANT       "$BRAND_VARIANT"
set_key VARIANT_ID    "$BRAND_VARIANT_ID"
set_key LOGO          "$BRAND_LOGO"
set_key HOME_URL      "$BRAND_URL"
set_key DOCUMENTATION_URL "$BRAND_URL"
set_key SUPPORT_URL   "$BRAND_URL"
set_key BUG_REPORT_URL "${BRAND_URL}/issues"

echo "==> os-release now reads:"
grep -E '^(NAME|PRETTY_NAME|VARIANT|LOGO|ID)=' "$OSR"

# ---------------------------------------------------------------------
# Logo
# ---------------------------------------------------------------------
# Drop your own artwork at:
#   files/system/usr/share/pixmaps/cyniva-logo.svg
# An SVG is best; PNG works. The name must match BRAND_LOGO above.
# Artwork ships via the files module at:
#   /usr/share/icons/hicolor/<size>/apps/cyniva-logo.png   (icon theme)
#   /usr/share/pixmaps/cyniva-logo.png                     (fallback)
#
# LOGO= in os-release is an ICON NAME, not a path, so it resolves through the
# icon theme. That is why the hicolor sizes matter -- a lone pixmap will work
# for some tools and silently fail for others.
if [[ -f "/usr/share/pixmaps/${BRAND_LOGO}.png" ]]; then
    echo "==> Logo present"
else
    echo "WARNING: /usr/share/pixmaps/${BRAND_LOGO}.png missing." >&2
    echo "         Tools will fall back to the Fedora logo." >&2
fi

# Rebuild the icon cache so the new hicolor entries are found.
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f /usr/share/icons/hicolor >/dev/null 2>&1 \
        && echo "==> hicolor icon cache rebuilt" \
        || echo "WARNING: icon cache rebuild failed (non-fatal)" >&2
fi

echo "branding applied"
