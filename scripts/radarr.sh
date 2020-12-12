#!/usr/bin/env bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
source "${BASEDIR}/env.sh"

while getopts "r" OPT; do
    case "$OPT" in
        r)  REBUILD=true
    esac
done

if [[ "$REBUILD" == "true" ]]; then
    echo "* Stopping and destroying Radarr"
    sudo systemctl stop radarr-container.service
    sudo podman stop radarr
    sudo podman rm radarr
fi

echo "* Starting Radarr"
sudo podman run -d \
    --name=radarr \
    --network=host \
    -e PUID="$PUID" \
    -e PGID="$PGID" \
    -e TZ="$TZ" \
    -v "$RADARR_CONFIG_DIR:/config:Z" \
    -v "$VIDEOS_DIR:/videos:z" \
    "$RADARR_IMAGE"

if [[ "$REBUILD" == "true" ]]; then
    sudo systemctl start radarr-container.service
fi
