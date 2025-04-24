#!/bin/bash

# prom-snapshot-restore.sh
# Restore a Prometheus snapshot from a .tar.gz archive to a running Docker container
# Licensed under the GPLv3 (see: https://www.gnu.org/licenses/gpl-3.0.txt)

# Required arguments:
#   --container=       : Docker container name
#   --data-dir=        : Prometheus TSDB path on the host
#   SNAPSHOTFILE       : Path to the .tar.gz snapshot archive

CONTAINER=""
DATA_DIR=""
SNAPSHOT_FILE=""

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --container=*) CONTAINER="${1#*=}" ;;
    --data-dir=*) DATA_DIR="${1#*=}" ;;
    *)
      if [[ -z "$SNAPSHOT_FILE" ]]; then
        SNAPSHOT_FILE="$1"
      else
        echo "Unexpected parameter: $1"
        exit 1
      fi
      ;;
  esac
  shift
done

if [[ -z "$CONTAINER" || -z "$DATA_DIR" || -z "$SNAPSHOT_FILE" ]]; then
  echo "Error: --container=, --data-dir=, and snapshot filename are required."
  exit 1
fi

if [[ ! -f "$SNAPSHOT_FILE" ]]; then
  echo "Snapshot archive not found: $SNAPSHOT_FILE"
  exit 1
fi

if [[ ! -d "$DATA_DIR" ]]; then
  echo "Data directory does not exist: $DATA_DIR"
  exit 1
fi

echo "Checking Docker container: $CONTAINER"
IS_RUNNING=$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null)
if [[ "$IS_RUNNING" == "true" ]]; then
  echo "Stopping running container..."
  docker stop "$CONTAINER"
  SHOULD_RESTART=true
elif [[ "$IS_RUNNING" == "false" ]]; then
  echo "Container is stopped."
  SHOULD_RESTART=true
else
  echo "Docker container '$CONTAINER' does not exist."
  exit 1
fi

echo "Cleaning data directory: $DATA_DIR"
rm -rf "$DATA_DIR"/*

echo "Extracting snapshot to $DATA_DIR"
tar xzf "$SNAPSHOT_FILE" -C "$DATA_DIR"
if [[ $? -ne 0 ]]; then
  echo "Error extracting snapshot."
  exit 1
fi

if [[ "$SHOULD_RESTART" == "true" ]]; then
  echo "Restarting container: $CONTAINER"
  docker start "$CONTAINER" || { echo "Failed to restart container."; exit 1; }
  echo "Restore complete and container restarted."
else
  echo "Restore complete. Container was not restarted."
fi

