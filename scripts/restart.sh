#!/bin/bash
set -euo pipefail

# shellcheck source=scripts/lib.sh
source /opt/sfplus/lib.sh

if ! state=$(api QueryServerState 2>&1); then
    log "QueryServerState failed: $state"
    exit 1
fi

players=$(jq -r '.data.serverGameState.numConnectedPlayers' <<<"$state")
running=$(jq -r '.data.serverGameState.isGameRunning' <<<"$state")
if ! [[ "$players" =~ ^[0-9]+$ ]]; then
    log "unexpected QueryServerState response: $state"
    exit 1
fi

if (( players > 0 )) && [[ "${RESTART_IF_PLAYERS_ONLINE,,}" != "true" ]]; then
    log "$players player(s) online, skipping scheduled restart"
    exit 0
fi

if [[ "$running" == "true" ]] && ! /opt/sfplus/backup.sh; then
    log "backup before restart failed, not restarting"
    exit 1
fi

log "shutting down; the container restart policy starts the server again"
api Shutdown > /dev/null || true
