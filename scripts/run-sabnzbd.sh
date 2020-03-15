#!/usr/bin/env bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
source ${BASEDIR}/env.sh

while getopts "r" OPT; do
    case "$OPT" in
        r)  REBUILD=true
    esac
done

if [[ "$REBUILD" == "true" ]]; then
    echo "* Stopping and destroying SABnzbd"
    sudo systemctl stop sabnzbd-container.service
    sudo podman stop sabnzbd
    sudo podman rm sabnzbd
fi

echo "* Starting SABnzbd"
sudo podman run -d \
    --name sabnzbd \
    --network host \
    -e PUID=${PUID} \
    -e PGID=${PGID} \
    -e TZ=${TZ} \
    -v ${SABNZBD_CONFIG_DIR}:/config:Z \
    -v ${VIDEOS_DIR}:/videos:z \
    ${SABNZBD_IMAGE}

if [[ "$REBUILD" == "true" ]]; then
    sudo systemctl start sabnzbd-container.service
fi

