#!/usr/bin/env bash

echo "Stopping and removing plex..."
sudo systemctl stop plex-container
sudo podman stop plex
sudo podman rm plex

