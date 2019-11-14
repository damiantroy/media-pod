#!/usr/bin/env bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
source ${BASEDIR}/env.sh

sudo podman run -d --cap-add=NET_ADMIN --device /dev/net/tun \
    --name=vpn \
    --security-opt="label=disable" \
    -e TZ=${TZ} \
    -v ${VPN_CONFIG_DIR}:/vpn:Z \
    -p 9117:9117 \
    -p 8112:8112 \
    ${VPN_IMAGE}:${VPN_TAG} \
    -r ${LOCAL_NET_CIDR} \
    -f ""