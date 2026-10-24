# satisfactory-server

[robtme/satisfactory-server](https://github.com/robtme/satisfactory-server) with scheduled backups and restarts.

Image: `ghcr.io/m0n7y5/satisfactory-server:latest` (linux/amd64)

All upstream settings, volumes and ports work unchanged. See the
[upstream README](https://github.com/robtme/satisfactory-server#readme). This image adds:

- **Start backup.** Before the server starts, `/config/saved` (saves, blueprints, server settings) is archived to
  `/config/backups/archive/saved-<timestamp>.tar.gz`. The server is not running yet, so the archive is consistent.
- **Scheduled backup.** The server saves the running session through its HTTPS API under a unique name. The finished
  file is downloaded with `DownloadSaveGame` to `/config/backups/archive/sfplus_<timestamp>.sav`, then removed from the
  server save list. No live directory is archived and players stay connected.
- **Scheduled restart.** Skipped while players are online. Otherwise the session is backed up first and the server is
  shut down through the API. Docker's restart policy starts it again, which also updates the game and makes a start
  backup.
- Backups older than `BACKUP_KEEP_DAYS` are deleted.

The scripts call the API on `127.0.0.1` without a token. For that the server runs with
`FG.DedicatedServer.AllowInsecureLocalAccess=1`, which only applies to loopback connections. With
`network_mode: host`, any local user on the host can reach the API without a token.

## Usage

```yaml
services:
  satisfactory-server:
    container_name: satisfactory-server
    hostname: satisfactory-server
    image: ghcr.io/m0n7y5/satisfactory-server:latest
    ports:
      - '7777:7777/tcp'
      - '7777:7777/udp'
      - '8888:8888/tcp'
    volumes:
      - './satisfactory-server:/config'
    environment:
      - MAXPLAYERS=4
      - PGID=1000
      - PUID=1000
      - TZ=Europe/Prague
      - BACKUP_CRON=0 */6 * * *
      - RESTART_CRON=0 5 * * *
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 10G
        reservations:
          memory: 6G
```

`restart` must be `unless-stopped` or `always`. A scheduled restart ends the container with exit code 0, which
`on-failure` does not restart.

## Environment variables

| Variable                    | Default       | Function                                                         |
|-----------------------------|---------------|------------------------------------------------------------------|
| `BACKUP_ON_START`           | `true`        | archive `/config/saved` before the server starts                 |
| `BACKUP_CRON`               | `0 */6 * * *` | schedule for API backups, empty disables                         |
| `BACKUP_KEEP_DAYS`          | `14`          | delete archived backups older than this many days                |
| `RESTART_CRON`              | empty         | schedule for restarts, empty disables                            |
| `RESTART_IF_PLAYERS_ONLINE` | `false`       | restart even when players are connected                          |
| `TZ`                        | `UTC`         | time zone for the schedules, e.g. `Europe/Prague`                |

Schedules use [supercronic](https://github.com/aptible/supercronic#crontab-format) syntax. Job output goes to
`docker logs`.

## Restore

Stop the container first.

- From a `.sav`: copy it to `./satisfactory-server/saved/server/`, start the container and load it in the in-game
  Server Manager.
- From a start backup: replace `./satisfactory-server/saved` with the `saved` directory from the archive.

## Updates

Dependabot opens a pull request when upstream publishes a new tag. Merging it builds and pushes a new `latest`.
