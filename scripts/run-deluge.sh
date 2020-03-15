#!/usr/bin/env bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
source ${BASEDIR}/env.sh

while getopts "r" OPT; do
    case "$OPT" in
        r)  REBUILD=true
    esac
done

if [[ "$REBUILD" == "true" ]]; then
    echo "* Stopping and destroying Deluge"
    sudo systemctl stop deluge-container.service
    sudo podman stop deluge
    sudo podman rm deluge
fi

echo "* Starting Deluge"
sudo podman run -d \
    --name deluge \
    --network container:vpn \
    --security-opt="label=disable" \
    -e PUID=${PUID} \
    -e PGID=${PGID} \
    -e TZ=${TZ} \
    -v ${DELUGE_CONFIG_DIR}:/config:Z \
    -v ${VIDEOS_DIR}:/videos:z \
    ${DELUGE_IMAGE}

if [[ "$REBUILD" == "true" ]]; then
    sudo systemctl start deluge-container.service
fi

