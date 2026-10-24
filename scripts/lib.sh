#!/bin/bash

ARCHIVE_DIR="/config/backups/archive"
API_URL="https://127.0.0.1:${SERVERGAMEPORT:-7777}/api/v1"

log() {
    printf '[sfplus] %s\n' "$*"
}

# api FUNCTION [DATA_JSON] [EXTRA_CURL_ARGS...]
# Unauthenticated: the entrypoint enables FG.DedicatedServer.AllowInsecureLocalAccess for loopback callers.
api() {
    local fn="$1" data="${2:-}"
    [[ -n "$data" ]] || data='{}'
    curl -sS -k --fail-with-body --max-time 120 -X POST "$API_URL" \
        -H 'Content-Type: application/json' \
        -d "{\"function\":\"${fn}\",\"data\":${data}}" \
        "${@:3}"
}

prune_archive() {
    if ! [[ "${BACKUP_KEEP_DAYS}" =~ ^[0-9]+$ ]]; then
        log "BACKUP_KEEP_DAYS is not a number (${BACKUP_KEEP_DAYS}), keeping all backups"
        return 1
    fi
    find "$ARCHIVE_DIR" -maxdepth 1 -type f \( -name 'saved-*.tar.gz' -o -name 'sfplus_*.sav' \) \
        -mtime "+${BACKUP_KEEP_DAYS}" -print -delete
}
