# Personal
export TZ=Australia/Melbourne
export LOCAL_NET_CIDR=192.168.1.0/24

# User and group
export PUID=1001
export PGID=1001
export APP_USER=videos
export APP_GROUP=videos

# Image Tags
# PLEX_TAG Options: latest, public, plexpass
export PLEX_TAG=plexpass
export VPN_TAG=latest
export NGINX_TAG=latest

# Directories
export VIDEOS_DIR=/videos
export VPN_CONFIG_DIR=/etc/openvpn
export JACKETT_CONFIG_DIR=/etc/jackett
export SABNZBD_CONFIG_DIR=/etc/sabnzbd
export QBITTORRENT_CONFIG_DIR=/etc/qbittorrent
export SONARR_CONFIG_DIR=/etc/sonarr
export RADARR_CONFIG_DIR=/etc/radarr
export PLEX_CONFIG_DIR=/var/lib/plexmediaserver
export PLEX_TRANSCODE_DIR=/videos/plex
export NGINX_CONFIG_DIR=/etc/nginx
export NGINX_CACHE_DIR=/var/cache/nginx
export NGINX_RUN_DIR=/run/nginx

# Images
export VPN_IMAGE=docker.io/dperson/openvpn-client
export JACKETT_IMAGE=docker.io/damiantroy/jackett
export SABNZBD_IMAGE=docker.io/damiantroy/sabnzbd
export QBITTORRENT_IMAGE=docker.io/damiantroy/qbittorrent
export RADARR_IMAGE=docker.io/damiantroy/radarr
export SONARR_IMAGE=docker.io/damiantroy/sonarr
export PLEX_IMAGE=docker.io/plexinc/pms-docker
export NGINX_IMAGE=docker.io/library/nginx
