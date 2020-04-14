#!/usr/bin/env bash

# Preflight checks
if ! hash jq 2> /dev/null; then
    echo "Error: 'jq' is not installed."
    exit 1
fi

# Variables
declare -A IMAGE_URL OLD_IMAGE_ID NEW_IMAGE_ID

# Command Line Options
while getopts "v" OPT; do
    case "$OPT" in
        v)  VERBOSE=true
    esac
done

# Verbose echo
function vecho () {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "$@"
    fi
}

# Get list of running images
CONTAINERS=$(podman ps --format json | jq -r '.[]?.Names')

# Get containers current image ID
vecho "Inspecting containers"
for CONTAINER in $CONTAINERS; do
    read -r OLD_IMAGE_ID[$CONTAINER] IMAGE_URL[$CONTAINER] <<<$(podman inspect $CONTAINER | jq -r '.[] | .Image + " " + .ImageName')
done

# Pull the latest images
for CONTAINER in $CONTAINERS; do
    vecho "Pulling ${IMAGE_URL[$CONTAINER]}"
    NEW_IMAGE_ID[$CONTAINER]=$(podman pull -q ${IMAGE_URL[$CONTAINER]})
done

# Recreate container if required
UPDATE_REQUIRED=false
for CONTAINER in $CONTAINERS; do
    if [[ "${OLD_IMAGE_ID[$CONTAINER]}" != "${NEW_IMAGE_ID[$CONTAINER]}" ]]; then
        UPDATE_REQUIRED=true
        echo "$CONTAINER has a new image, please rebuild."
    fi
done
if [[ "$UPDATE_REQUIRED" == "false" ]]; then
    echo "No containers require updating."
fi

exit 0

