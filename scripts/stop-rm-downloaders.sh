#!/usr/bin/env bash

for CONTAINER in radarr sonarr sabnzbd qbittorrent jackett vpn nginx; do
    echo "Stopping and removing ${CONTAINER}..."
    sudo systemctl stop ${CONTAINER}-container
    sudo podman stop $CONTAINER
    sudo podman rm $CONTAINER
    echo
done

exit 0

