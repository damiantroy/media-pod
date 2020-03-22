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

    echo "* Stopping and destroying Jackett"
    sudo systemctl stop jackett-container.service
    sudo podman stop jackett
    sudo podman rm jackett

    echo "* Stopping and destroying VPN"
    sudo systemctl stop vpn-container.service
    sudo podman stop vpn
    sudo podman rm vpn
fi

echo "* Starting VPN"
sudo podman run -d --cap-add=NET_ADMIN --device /dev/net/tun \
    --network host \
    --name=vpn \
    --security-opt="label=disable" \
    -e TZ=${TZ} \
    -v ${VPN_CONFIG_DIR}:/vpn:Z \
    -p 9117:9117 \
    -p 8112:8112 \
    ${VPN_IMAGE}:${VPN_TAG} \
    -r ${LOCAL_NET_CIDR} \
    -f ""

if [[ "$REBUILD" == "true" ]]; then
    sudo systemctl start vpn-container.service

    $BASEDIR/run-jackett.sh
    sudo systemctl start jackett-container.service

    $BASEDIR/run-deluge.sh
    sudo systemctl start deluge-container.service
fi

