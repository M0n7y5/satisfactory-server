#!/bin/bash
set -euo pipefail

# shellcheck source=scripts/lib.sh
source /opt/sfplus/lib.sh

if [[ "${BACKUP_ON_START,,}" == "true" ]]; then
    /opt/sfplus/backup-offline.sh || log "WARNING: start backup failed, starting the server anyway"
fi

crontab=/tmp/sfplus.crontab
: > "$crontab"
if [[ -n "${BACKUP_CRON}" ]]; then
    echo "${BACKUP_CRON} /opt/sfplus/backup.sh" >> "$crontab"
fi
if [[ -n "${RESTART_CRON}" ]]; then
    echo "${RESTART_CRON} /opt/sfplus/restart.sh" >> "$crontab"
fi

if [[ -s "$crontab" ]]; then
    log "scheduled jobs:"
    cat "$crontab"
    if [[ "$(id -u)" -eq 0 ]]; then
        gosu "${PUID}:${PGID}" supercronic "$crontab" &
    else
        supercronic "$crontab" &
    fi
fi

exec /init.sh "-ini:Engine:[SystemSettings]:FG.DedicatedServer.AllowInsecureLocalAccess=1" "$@"
