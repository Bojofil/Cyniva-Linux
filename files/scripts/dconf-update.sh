#!/usr/bin/env bash
set -euo pipefail

# Ensure the local db is in the user profile, then compile it.
mkdir -p /etc/dconf/profile
cat > /etc/dconf/profile/user <<'EOF'
user-db:user
system-db:local
EOF

dconf update

echo "dconf defaults compiled"
