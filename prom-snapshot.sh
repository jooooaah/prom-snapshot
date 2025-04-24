#!/bin/bash

# prom-snapshot.sh
# Create a snapshot of a running Prometheus instance via its HTTP API
# Licensed under the GPLv3 (see: https://www.gnu.org/licenses/gpl-3.0.txt)

# Required arguments:
#   --url=             : Full Prometheus base URL (e.g., http://localhost:9090 or https://host/prometheus)
#   --snapshot-dir=    : Local path to the snapshot storage directory (mounted TSDB path)
# Optional:
#   --basic-auth=      : Credentials in user:password format for HTTP Basic Auth
#   --target-file=     : Full path (incl. filename) to save the .tar.gz backup file

PROMETHEUS_URL=""
BASIC_AUTH=""
SNAPSHOT_DIR=""
TARGET_FILE=""

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --url=*) PROMETHEUS_URL="${1#*=}" ;;
    --basic-auth=*) BASIC_AUTH="${1#*=}" ;;
    --snapshot-dir=*) SNAPSHOT_DIR="${1#*=}" ;;
    --target-file=*) TARGET_FILE="${1#*=}" ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

if [[ -z "$PROMETHEUS_URL" || -z "$SNAPSHOT_DIR" ]]; then
  echo "Error: --url and --snapshot-dir are required."
  exit 1
fi

# Remove trailing slash if present
PROMETHEUS_URL="${PROMETHEUS_URL%/}"

TIMESTAMP=$(date +%F_%H-%M-%S)
if [[ -z "$TARGET_FILE" ]]; then
  TARGET_FILE="prometheus-snapshot-$TIMESTAMP.tar.gz"
fi
[[ "$TARGET_FILE" != /* ]] && TARGET_FILE="$(pwd)/$TARGET_FILE"

# Send snapshot request
CURL_CMD="curl -s -X POST"
[[ -n "$BASIC_AUTH" ]] && CURL_CMD="$CURL_CMD -u $BASIC_AUTH"
CURL_CMD="$CURL_CMD $PROMETHEUS_URL/api/v1/admin/tsdb/snapshot"

echo "Requesting snapshot from Prometheus at: $PROMETHEUS_URL"
RESPONSE=$($CURL_CMD)

SNAPSHOT_NAME=$(echo "$RESPONSE" | grep -oP '"name":"\K[^"]+')
if [[ -z "$SNAPSHOT_NAME" ]]; then
  echo "Failed to create snapshot. Response:"
  echo "$RESPONSE"
  exit 1
fi

FULL_SNAPSHOT_PATH="$SNAPSHOT_DIR/$SNAPSHOT_NAME"
if [[ ! -d "$FULL_SNAPSHOT_PATH" ]]; then
  echo "Snapshot directory not found: $FULL_SNAPSHOT_PATH"
  exit 1
fi

mkdir -p "$(dirname "$TARGET_FILE")"
echo "Archiving snapshot to: $TARGET_FILE"
tar czf "$TARGET_FILE" --hard-dereference -C "$FULL_SNAPSHOT_PATH" .

if [[ $? -eq 0 ]]; then
  echo "Snapshot successfully backed up to $TARGET_FILE"
else
  echo "Error creating tarball."
  exit 1
fi

