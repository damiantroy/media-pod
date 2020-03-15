#!/usr/bin/env bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
source ${BASEDIR}/env.sh

while getopts "r" OPT; do
    case "$OPT" in
        r)  REBUILD=true
    esac
done

if [[ "$REBUILD" == "true" ]]; then
    echo "* Stopping and destroying Jackett"
    sudo systemctl stop jackett-container.service
    sudo podman stop jackett
    sudo podman rm jackett
fi

echo "* Starting Jackett"
sudo podman run -d \
    --name jackett \
    --network container:vpn \
    --security-opt="label=disable" \
    -e PUID=${PUID} \
    -e PGID=${PGID} \
    -e TZ=${TZ} \
    -v ${JACKETT_CONFIG_DIR}:/config:Z \
    -v ${VIDEOS_DIR}:/videos:z \
    ${JACKETT_IMAGE}

if [[ "$REBUILD" == "true" ]]; then
    sudo systemctl start jackett-container.service
fi

