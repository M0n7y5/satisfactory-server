#!/bin/bash
set -euo pipefail

# shellcheck source=scripts/lib.sh
source /opt/sfplus/lib.sh

if [[ ! -d /config/saved ]]; then
    log "no /config/saved yet, skipping start backup"
    exit 0
fi

mkdir -p "$ARCHIVE_DIR"
dest="$ARCHIVE_DIR/saved-$(date +%Y%m%d_%H%M%S).tar.gz"
trap 'rm -f "$dest.tmp"' EXIT

tar czf "$dest.tmp" -C /config saved
mv "$dest.tmp" "$dest"
log "start backup created: $dest"

prune_archive
