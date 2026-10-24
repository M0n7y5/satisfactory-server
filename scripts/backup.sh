#!/bin/bash
set -euo pipefail

# shellcheck source=scripts/lib.sh
source /opt/sfplus/lib.sh

name="sfplus_$(date +%Y%m%d_%H%M%S)"
dest="$ARCHIVE_DIR/$name.sav"
mkdir -p "$ARCHIVE_DIR"
trap 'rm -f "$dest.tmp"' EXIT

if ! out=$(api SaveGame "{\"SaveName\":\"$name\"}" 2>&1); then
    log "SaveGame failed: $out"
    exit 1
fi

downloaded=false
for _ in $(seq 30); do
    if api DownloadSaveGame "{\"SaveName\":\"$name\"}" -o "$dest.tmp" 2>/dev/null && [[ -s "$dest.tmp" ]]; then
        downloaded=true
        break
    fi
    sleep 2
done
if [[ "$downloaded" != true ]]; then
    log "DownloadSaveGame failed for $name: $(cat "$dest.tmp" 2>/dev/null)"
    exit 1
fi

mv "$dest.tmp" "$dest"
log "backup created: $dest"

if ! out=$(api DeleteSaveFile "{\"SaveName\":\"$name\"}" 2>&1); then
    log "WARNING: could not delete $name from the server save list: $out"
fi

prune_archive
