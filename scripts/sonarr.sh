#!/usr/bin/env bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
source ${BASEDIR}/env.sh

while getopts "r" OPT; do
    case "$OPT" in
        r)  REBUILD=true
    esac
done

if [[ "$REBUILD" == "true" ]]; then
    echo "* Stopping and destroying Sonarr"
    sudo systemctl stop sonarr-container.service
    sudo podman stop sonarr
    sudo podman rm sonarr
fi

echo "* Starting Sonarr"
sudo podman run -d \
    --name=sonarr \
    --network=host \
    -e PUID="$PUID" \
    -e PGID="$PGID" \
    -e TZ="$TZ" \
    -v "$SONARR_CONFIG_DIR:/config:Z" \
    -v "$VIDEOS_DIR:/videos:z" \
    "$SONARR_IMAGE"

if [[ "$REBUILD" == "true" ]]; then
    sudo systemctl start sonarr-container.service
fi

