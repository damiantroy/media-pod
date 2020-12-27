#!/usr/bin/env bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
source "${BASEDIR}/env.sh"

while getopts "r" OPT; do
    case "$OPT" in
        r)  REBUILD=true
    esac
done

if [[ "$REBUILD" == "true" ]]; then
    echo "* Stopping and destroying qBittorrent"
    sudo systemctl stop qbittorrent-container.service
    sudo podman stop qbittorrent
    sudo podman rm qbittorrent
fi

echo "* Starting qBittorrent"
sudo podman run -d \
    --name=qbittorrent \
    --network=container:vpn \
    --security-opt="label=disable" \
    -e PUID="$PUID" \
    -e PGID="$PGID" \
    -e TZ="$TZ" \
    -v "$QBITTORRENT_CONFIG_DIR:/config:Z" \
    -v "$VIDEOS_DIR:/videos:z" \
    "$QBITTORRENT_IMAGE"

if [[ "$REBUILD" == "true" ]]; then
    sudo systemctl start qbittorrent-container.service
fi
