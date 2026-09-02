#!/usr/bin/env bash
set -euo pipefail

# Pre-stage the SSSD auth profile so that a `realm join` at first boot
# just works instead of needing an authselect run afterwards.
authselect select sssd with-mkhomedir --force

# oddjobd creates the home directory on first domain login.
systemctl enable oddjobd.service || true

echo "authselect profile staged for sssd"
