#!/usr/bin/env bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
source ${BASEDIR}/env.sh

sudo podman run -d \
    --name sonarr \
    --network host \
    -e PUID=${PUID} \
    -e PGID=${PGID} \
    -e TZ=${TZ} \
    -v ${SONARR_CONFIG_DIR}:/config:Z \
    -v ${VIDEOS_DIR}:/videos:z \
    ${SONARR_IMAGE}
