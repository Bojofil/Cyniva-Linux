#!/usr/bin/env bash
set -euo pipefail

# The BlueBuild files module does not reliably preserve modes, so set them
# explicitly for anything that cares.

# The per-machine AD setup helper needs to be executable.
chmod 0755 /usr/libexec/ad-setup

# sssd.conf is NOT baked into this image -- it is installed per-machine by
# ad-setup, which sets 0600 itself. We only prepare the directory here.
mkdir -p /etc/sssd/conf.d
chown -R root:root /etc/sssd
chmod 0700 /etc/sssd/conf.d

echo "permissions set"
