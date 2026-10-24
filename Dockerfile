FROM robtme/satisfactory-server:v1.9.11

ARG SUPERCRONIC_VERSION=v0.2.51
ARG SUPERCRONIC_SHA1SUM=1692066e350a88ff4d7d6474fe3c7a6c41ec5e89

RUN curl -fsSL -o /usr/local/bin/supercronic \
        "https://github.com/aptible/supercronic/releases/download/${SUPERCRONIC_VERSION}/supercronic-linux-amd64" \
 && echo "${SUPERCRONIC_SHA1SUM}  /usr/local/bin/supercronic" | sha1sum -c - \
 && chmod +x /usr/local/bin/supercronic

ENV BACKUP_ON_START="true" \
    BACKUP_CRON="0 */6 * * *" \
    BACKUP_KEEP_DAYS="14" \
    RESTART_CRON="" \
    RESTART_IF_PLAYERS_ONLINE="false"

COPY --chmod=755 scripts/ /opt/sfplus/

ENTRYPOINT ["/opt/sfplus/entrypoint.sh"]
