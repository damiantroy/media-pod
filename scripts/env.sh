# Personal
TZ=Australia/Melbourne
LOCAL_NET_CIDR=192.168.1.0/24

# User and group
PUID=1001
PGID=1001
APP_USER=videos
APP_GROUP=videos

# Image Tags
PLEX_TAG=plexpass # Options: latest, public, plexpass
VPN_TAG=latest
NGINX_TAG=latest

# Directories
VIDEOS_DIR=/videos
VPN_CONFIG_DIR=/etc/openvpn
JACKETT_CONFIG_DIR=/etc/jackett
DELUGE_CONFIG_DIR=/etc/deluge
SABNZBD_CONFIG_DIR=/etc/sabnzbd
SONARR_CONFIG_DIR=/etc/sonarr
RADARR_CONFIG_DIR=/etc/radarr
PLEX_CONFIG_DIR=/var/lib/plexmediaserver
PLEX_TRANSCODE_DIR=/videos/plex
NGINX_CONFIG_DIR=/etc/nginx
NGINX_CACHE_DIR=/var/cache/nginx
NGINX_RUN_DIR=/run/nginx

# Images
VPN_IMAGE=dperson/openvpn-client
JACKETT_IMAGE=damiantroy/jackett
DELUGE_IMAGE=damiantroy/deluge
SABNZBD_IMAGE=damiantroy/sabnzbd
RADARR_IMAGE=damiantroy/radarr
SONARR_IMAGE=damiantroy/sonarr
PLEX_IMAGE=plexinc/pms-docker
NGINX_IMAGE=library/nginx
