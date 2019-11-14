#!/usr/bin/env bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
source ${BASEDIR}/env.sh

if [[ -z "${PLEX_CLAIM_TOKEN}" ]]; then
    echo "Error: Missing Plex Claim Token" >&2
    echo "Please visit https://www.plex.tv/claim/ and set the \$PLEX_CLAIM_TOKEN variable" >&2
    exit 1
fi

sudo podman run -d \
    --name=plex \
    --network=host \
    --systemd=false \
    -e TZ=${TZ} \
    -e PLEX_CLAIM=${PLEX_CLAIM_TOKEN} \
    -e PLEX_UID=${PUID} \
    -e PLEX_GID=${PGID} \
    -v ${PLEX_CONFIG_DIR}:/config:Z \
    -v ${PLEX_TRANSCODE_DIR}:/transcode:Z \
    -v ${VIDEOS_DIR}:/data:z \
    ${PLEX_IMAGE}:${PLEX_TAG}
