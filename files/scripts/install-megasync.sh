#!/usr/bin/env bash
set -euo pipefail

# MEGA's %post scriptlet calls `rpm --import` from inside a running rpm
# transaction, which deadlocks on the transaction lock, and calls sysctl,
# which a build container cannot do. Both make the whole rpm-ostree
# transaction fail with "Error -1 running transaction".
#
# Neither action is needed for the app to work:
#   - the GPG key import only affects rpm's own keyring
#   - the inotify limit is handled by /etc/sysctl.d/99-megasync-inotify.conf
#
# So install it on its own with scriptlets disabled.

echo "==> Installing megasync (scriptlets disabled)"
dnf -y install --setopt=tsflags=noscripts megasync

echo "==> Verifying"
if rpm -q megasync >/dev/null 2>&1; then
    rpm -q megasync
    command -v megasync >/dev/null 2>&1 \
        && echo "    binary present: $(command -v megasync)" \
        || echo "    WARNING: megasync binary not on PATH" >&2
else
    echo "ERROR: megasync did not install" >&2
    exit 1
fi

dnf clean all
