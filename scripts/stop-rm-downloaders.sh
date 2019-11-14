#!/usr/bin/env bash

for SERVICE in radarr sabnzbd sonarr jackett deluge vpn; do
    echo "Stopping and removing ${SERVICE}..."
    sudo systemctl stop ${SERVICE}-container
    sudo podman stop $SERVICE
    sudo podman rm $SERVICE
    echo
done

exit 0

