# Prometheus Snapshot Tools

Simple Bash scripts to create and restore Prometheus snapshots cleanly and reliably using the Prometheus Admin API and Docker. I use it for my personal needs, perhaps anybody else finds it helpful. No warranties - use at your own risk!

## Overview

- `prom-snapshot.sh` creates a snapshot using the Prometheus HTTP API and archives it to a `.tar.gz` file.
- `prom-snapshot-restore.sh` stops a running Prometheus Docker container, restores a `.tar.gz` snapshot into the TSDB directory, and restarts the container.

These tools are designed for Dockerized Prometheus environments, with route prefixes and optional Basic Auth in mind.

## Features

- Supports both internal (`http://localhost:9090`) and external URLs (`https://prometheus.example.com/prometheus`)
- Optional HTTP Basic Authentication (`--basic-auth=user:pass`)
- Compatible with Docker Compose setups with bind-mount volumes
- Minimal dependencies: `bash`, `curl`, `grep`, `tar`

## Usage

### Create Snapshot

```bash
./prom-snapshot.sh \
  --url="https://host.domain/prometheus" \
  --snapshot-dir="/srv/prometheus/data/snapshots" \
  --basic-auth="admin:secret" \
  --target-file="/srv/backups/prometheus-2025-04-16.tar.gz"
```

Arguments:
- `--url`: Base URL of your Prometheus instance
- `--snapshot-dir`: Local path to the Prometheus snapshot output directory (as mounted on the host)
- `--basic-auth`: (Optional) Prometheus Basic Auth credentials
- `--target-file`: (Optional) Full output path for the `.tar.gz` archive

### Restore Snapshot

```bash
./prom-snapshot-restore.sh \
  --container=prometheus \
  --data-dir=/srv/prometheus/data \
  /srv/backups/prometheus-2025-04-16.tar.gz
```

Arguments:
- `--container`: Docker container name
- `--data-dir`: Host directory mounted to Prometheus (e.g., TSDB path)
- `SNAPSHOTFILE`: Path to your backup archive

## Why Basic Auth?

If your Prometheus instance is exposed via Traefik or any reverse proxy with Basic Auth enabled, snapshot API access requires authentication.  
These scripts support optional Basic Auth via the `--basic-auth=user:password` flag.

## License

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**.  
See `LICENSE` file or [https://www.gnu.org/licenses/gpl-3.0.html](https://www.gnu.org/licenses/gpl-3.0.html)

## Contributing

Contributions welcome! Please open issues or PRs to improve the tooling.

- Add retry/backoff?
- Add snapshot listing?
- Docker image for self-contained backup tool?

---

Happy Monitoring!
