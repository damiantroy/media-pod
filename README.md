# VideoBot: Personal Video Downloader

This tutorial will help you create an all-in-one HTPC Downloader box. You'll create installations for OpenVPN, Jackett,
Deluge, SABnzbd, Sonarr, Radarr and Plex Media Server in Podman containers running on CentOS 8.

As this was a learning experience for CentOS 8, Podman, and containers in general, I've written most of the container
code myself. It's probably not the best code, but I had fun along the way.

I had hoped to create CentOS 8 containers, but many of the dependencies weren't available at the time of writing,
so I opted for CentOS 7 for now. I know there are more popular distributions for containers, but I'm always up for
learning more about RHEL/CentOS, so I chose to stick with that. Apologies for the container sizes.

As with any tutorial, but sure to inspect any scripts or Dockerfiles before running them. Not just for safety, but you
may learn something, or even just get a laugh out of my code.

## Table of Contents

+ [Installation](#Installation)
  + [Install VPN](#Install-VPN-Container)
  + [Install Jackett](#Install-Jackett-Container)
  + [Install Deluge](#Install-Deluge-Container)
  + [Install SABnzbd](#Install-SABnzbd-Container)
  + [Install Sonarr](#Install-Sonarr-Container)
  + [Install Radarr](#Install-Radarr-Container)
  + [Install Plex Media Server](#Install-Plex-Media-Server-Container)

## Preparation

### Environment Variables

These variables need to be set in the terminal where you'll be executing your commands. If you close your terminal and
come back later, be sure to set these variables again.

```shell script
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
VPN_CONFIG_DIR=/etc/config/vpn
JACKETT_CONFIG_DIR=/etc/config/jackett
DELUGE_CONFIG_DIR=/etc/config/deluge
SABNZBD_CONFIG_DIR=/etc/config/sabnzbd
SONARR_CONFIG_DIR=/etc/config/sonarr
RADARR_CONFIG_DIR=/etc/config/radarr
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
```

### Clone Repo

If you haven't cloned the VideoBot repo already, you'll need to do so:

```shell script
sudo dnf install git
git clone git@github.com:damiantroy/videobot.git
```

### User and Group

Here we'll add the user and group which will own the downloaded and configuration files. Each of the containers run
their applications as the same UID/GID, so won't have any trouble working with the files.

```shell script
sudo groupadd -g ${PGID} $APP_GROUP
sudo useradd -u ${PUID} -g $APP_GROUP $APP_USER
```

### Enable Masquerading

```shell script
sudo firewall-cmd --add-masquerade --permanent
sudo firewall-cmd --reload
```

### Configure Podman

```shell script
sudo dnf install podman
```

Allow containers to be managed by systemd in SELinux:

```shell script
sudo setsebool -P container_manage_cgroup on
```

## Installation

### Install VPN Container

This is a third party container, [dperson/openvpn-client](https://github.com/dperson/openvpn-client).

[Private Internet Access](https://www.privateinternetaccess.com/) (PIA) is used in this example, but any provider
compatible with OpenVPN should work.

Install required packages:

```shell script
sudo dnf install unzip
```

Generate the required configuration file from PIA:

```shell script
mkdir /tmp/pia
cd /tmp/pia/
curl https://www.privateinternetaccess.com/openvpn/openvpn.zip -o openvpn.zip
unzip openvpn.zip
cp AU\ Melbourne.ovpn vpn.conf # Or any other .ovpn file
sed -i 's/^persist-tun/# persist-tun/' vpn.conf
echo 'keepalive 10 30' >> vpn.conf
echo 'pull-filter ignore "auth-token"' >> vpn.conf
sed -i 's#^auth-user-pass#auth-user-pass /vpn/vpn.auth#' vpn.conf
sudo mkdir -p ${VPN_CONFIG_DIR}
sudo cp vpn.conf ${VPN_CONFIG_DIR}/
cd -
rm -rf /tmp/pia
```

Securely create your VPN authentication file:

```shell script
sudo touch ${VPN_CONFIG_DIR}/vpn.auth
sudo chmod 600 ${VPN_CONFIG_DIR}/vpn.auth
```

`sudo` edit your authentication file, `${VPN_CONFIG_DIR}/vpn.auth`, with your PIA username and password:

```text
your_pia_username
your_pia_password
```

Load the tun module:

```shell script
echo tun | sudo tee /etc/modules-load.d/tun.conf
modprobe tun
```

Start the VPN container:

```shell script
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
```

Add the container to systemd for service management:

```shell script
sudo cp systemd/vpn-container.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now vpn-container.service
```

### Install Jackett Container

Create the required directories:

```shell script
sudo mkdir -p ${VIDEOS_DIR}/downloads/torrents ${JACKETT_CONFIG_DIR}
sudo chown -R ${APP_USER}:${APP_GROUP} ${VIDEOS_DIR} ${JACKETT_CONFIG_DIR}
```

Start the Jackett container:

```shell script
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
```

Add the container to systemd for service management:

```shell script
sudo cp systemd/jackett-container.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now jackett-container.service
```

### Install Deluge Container

Create the required directories:

```shell script
sudo mkdir -p ${videos_dir}/downloads/{deluge,torrents} ${DELUGE_CONFIG_DIR}
sudo chown -R ${APP_USER}:${APP_GROUP} ${VIDEOS_DIR} ${DELUGE_CONFIG_DIR}
```

Start the Deluge container:

```shell script
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
```

Add the container to systemd for service management:

```shell script
sudo cp systemd/deluge-container.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now deluge-container.service
```

### Install SABnzbd Container

Create the required directories:

```shell script
sudo mkdir -p ${VIDEOS_DIR}/downloads/sabnzbd ${SABNZBD_CONFIG_DIR}
sudo chown -R ${APP_USER}:${APP_GROUP} ${VIDEOS_DIR} ${SABNZBD_CONFIG_DIR}
```

As this service is running on the host network, we need to open the firewall for it:

```shell script
sudo firewall-cmd --new-service-from-file firewalld/sabnzbd.xml --permanent
sudo firewall-cmd --add-service sabnzbd --permanent
sudo firewall-cmd --reload
```

Start the SABnzbd container:

```shell script
sudo podman run -d \
    --name sabnzbd \
    --network host \
    -e PUID=${PUID} \
    -e PGID=${PGID} \
    -e TZ=${TZ} \
    -v ${SABNZBD_CONFIG_DIR}:/config:Z \
    -v ${VIDEOS_DIR}:/videos:z \
    ${SABNZBD_IMAGE}
```

Add the container to systemd for service management:

```shell script
sudo cp systemd/sabnzbd-container.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now sabnzbd-container.service
```

### Install Sonarr Container

Create the required directories:

```shell script
sudo mkdir -p ${VIDEOS_DIR}/TVShows ${SONARR_CONFIG_DIR}
sudo chown -R ${APP_USER}:${APP_GROUP} ${VIDEOS_DIR} ${SONARR_CONFIG_DIR}
```

As this service is running on the host network, we need to open the firewall for it:

```shell script
sudo firewall-cmd --new-service-from-file firewalld/sonarr.xml --permanent
sudo firewall-cmd --add-service sonarr --permanent
sudo firewall-cmd --reload
```

Start the Sonarr container:

```shell script
sudo podman run -d \
    --name sonarr \
    --network host \
    -e PUID=${PUID} \
    -e PGID=${PGID} \
    -e TZ=${TZ} \
    -v ${SONARR_CONFIG_DIR}:/config:Z \
    -v ${VIDEOS_DIR}:/videos:z \
    ${SONARR_IMAGE}
```

Add the container to systemd for service management:

```shell script
sudo cp systemd/sonarr-container.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now sonarr-container.service
```

### Install Radarr Container

Create the required directories:

```shell script
sudo mkdir -p ${VIDEOS_DIR}/Movies ${RADARR_CONFIG_DIR}
sudo chown -R ${APP_USER}:${APP_GROUP} ${VIDEOS_DIR} ${RADARR_CONFIG_DIR}
```

As this service is running on the host network, we need to open the firewall for it:

```shell script
sudo firewall-cmd --new-service-from-file firewalld/radarr.xml --permanent
sudo firewall-cmd --add-service radarr --permanent
sudo firewall-cmd --reload
```

Start the Radarr container:

```shell script
sudo podman run -d \
    --name radarr \
    --network host \
    -e PUID=${PUID} \
    -e PGID=${PGID} \
    -e TZ=${TZ} \
    -v ${RADARR_CONFIG_DIR}:/config:Z \
    -v ${VIDEOS_DIR}:/videos:z \
    ${RADARR_IMAGE}
```

Add the container to systemd for service management:

```shell script
sudo cp systemd/radarr-container.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now radarr-container.service
```

### Install Plex Media Server Container

This install is using the [official Plex Media Server container](https://hub.docker.com/r/plexinc/pms-docker/).

Create the required directories, and set their permissions:

```shell script
sudo mkdir -p $VIDEOS_DIR/{TVShows,Movies} $PLEX_CONFIG_DIR $PLEX_TRANSCODE_DIR
sudo chown -R ${APP_USER}:${APP_GROUP} $VIDEOS_DIR $PLEX_CONFIG_DIR $PLEX_TRANSCODE_DIR
```

As this service is running on the host network, we need to open the firewall for it:

```shell script
sudo firewall-cmd --new-service-from-file firewalld/plexmediaserver.xml --permanent
sudo firewall-cmd --add-service plexmediaserver --permanent
sudo firewall-cmd --reload
```

Generate a [Plex Claim Token](https://www.plex.tv/claim/), then save it to an environment variable:

```shell script
PLEX_CLAIM_TOKEN=claim-xxx
```

Create the Plex Media Server container:

```shell script
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
```

Add the container to systemd for service management:

```shell script
sudo cp systemd/plex-container.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now plex-container.service
```
