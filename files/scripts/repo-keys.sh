#!/usr/bin/env bash
set -euo pipefail

# rpm-ostree/dnf5 can be fussy about importing repo GPG keys in a
# non-interactive build. Import them explicitly so `gpgcheck=1` stays on.

import_key() {
    local url="$1" name="$2"
    echo "==> Importing key for $name"
    if curl -fsSL "$url" -o "/tmp/${name}.asc"; then
        rpm --import "/tmp/${name}.asc"
        rm -f "/tmp/${name}.asc"
    else
        echo "WARNING: could not fetch key for $name from $url" >&2
        echo "         Build will likely fail at the install step." >&2
    fi
}

import_key "https://packages.microsoft.com/keys/microsoft.asc" microsoft

# Verify this URL matches what is in megasync.repo.
import_key "https://mega.nz/linux/repo/Fedora_44/repodata/repomd.xml.key" mega

echo "repo keys imported"
