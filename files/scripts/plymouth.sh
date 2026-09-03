#!/usr/bin/env bash
set -euo pipefail

# Custom boot splash.
#
# Strategy: clone the stock `spinner` theme and swap its watermark, rather
# than authoring a theme from scratch. The stock theme's script and graphics
# also render the LUKS passphrase prompt and progress indicator -- a
# hand-written theme that omits them looks broken on an encrypted disk.
#
# Requires the `initramfs` module in the recipe AFTER this script. Plymouth
# runs before the root filesystem is mounted, so the theme has to be inside
# the initramfs; changing /usr/share alone does nothing.

THEME_NAME="cyniva"
BASE_THEME="spinner"
SRC="/usr/share/plymouth/themes/${BASE_THEME}"
DST="/usr/share/plymouth/themes/${THEME_NAME}"
# Bluefin's stock watermark is 149x43 -- a wide wordmark. A square mark needs
# more height than that to stay legible, so do not match it literally.
# Available square sizes: 48, 64, 96, 128, 256. Start at 128 and go down if it
# dominates the boot screen. Plymouth draws this at NATIVE size; it does not
# scale, same as GDM.
LOGO="/usr/share/icons/hicolor/128x128/apps/cyniva-logo.png"

echo "==> Available themes before:"
plymouth-set-default-theme --list 2>/dev/null || ls -1 /usr/share/plymouth/themes/

if [[ ! -d "$SRC" ]]; then
    echo "ERROR: base theme '$BASE_THEME' not found at $SRC" >&2
    echo "       Check what the base image ships and set BASE_THEME." >&2
    exit 1
fi

if [[ ! -f "$LOGO" ]]; then
    echo "ERROR: logo not found at $LOGO" >&2
    exit 1
fi

echo "==> Cloning $BASE_THEME -> $THEME_NAME"
rm -rf "$DST"
cp -r "$SRC" "$DST"

# The .plymouth file is named after the theme and holds absolute paths.
mv "${DST}/${BASE_THEME}.plymouth" "${DST}/${THEME_NAME}.plymouth"
sed -i \
    -e "s|^Name=.*|Name=Cyniva Linux|" \
    -e "s|^Description=.*|Description=Cyniva Linux boot splash|" \
    -e "s|${BASE_THEME}|${THEME_NAME}|g" \
    "${DST}/${THEME_NAME}.plymouth"

echo "==> Resulting theme config:"
cat "${DST}/${THEME_NAME}.plymouth"

# Replace the watermark. The stock spinner theme draws watermark.png near the
# bottom of the screen; keeping the filename means no script changes.
if [[ -f "${DST}/watermark.png" ]]; then
    echo "==> Replacing watermark.png"
else
    echo "==> No stock watermark.png; adding one"
fi
cp "$LOGO" "${DST}/watermark.png"

echo "==> Setting default theme"
plymouth-set-default-theme "$THEME_NAME"

echo "==> Default theme is now: $(plymouth-set-default-theme)"
