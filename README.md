# VideoBot: Personal Video Downloader

This tutorial will help you create an all-in-one HTPC downloader box. You'll create installations for OpenVPN, Jackett,
Deluge, SABnzbd, Sonarr, Radarr and Plex Media Server in Podman containers running on CentOS Stream 8.

As this was a learning experience for CentOS 8, Podman, and containers in general, I've written most of the container
code myself. It's probably not the best code, but I had fun along the way.

Originally the containers were created using CentOS 7, and just as I coverted a few of them to CentOS 8, Red Hat
pulled some shenanigans by annoncing the early EOL of CentOS 8, so I'll be converting the containers to
[Rocky Linux](https://rockylinux.org/) when it becomes available and when I get the chance.

As with any tutorial, but sure to inspect any scripts or Dockerfiles before running them. Not just for safety, but you
may learn something along the way.

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

### Clone Repo

If you haven't cloned the VideoBot repo already, you'll need to do so:

```shell script
sudo dnf install git make
git clone https://github.com/damiantroy/videobot.git
cd videobot/
```

### Environment Variables

These variables need to be set in the terminal where you'll be executing your commands. If you close your terminal and
come back later, be sure to set these variables again.

```shell script
vi scripts/env.sh
source scripts/env.sh
```

### User and Group

Here we'll add the user and group which will own the downloaded and configuration files. Each of the containers run
their applications as the same UID/GID, so won't have any trouble working with the files.

```shell script
sudo groupadd -g "$PGID" "$APP_GROUP"
sudo useradd -u "$PUID" -g "$APP_GROUP" "$APP_USER"
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

Generate the required configuration file from PIA:

```shell script
sudo dnf install unzip
curl https://www.privateinternetaccess.com/openvpn/openvpn.zip -o /tmp/pia.zip
unzip /tmp/pia.zip -d /tmp/pia
cp /tmp/pia/au_melbourne.ovpn /tmp/pia/vpn.conf # Or pick your own location file
sed -i 's/^persist-tun/# persist-tun/' /tmp/pia/vpn.conf
echo 'keepalive 10 30' >> /tmp/pia/vpn.conf
echo 'pull-filter ignore "auth-token"' >> /tmp/pia/vpn.conf
sed -i 's#^auth-user-pass#auth-user-pass /vpn/vpn.auth#' /tmp/pia/vpn.conf
sudo mkdir -p "$VPN_CONFIG_DIR"
sudo cp /tmp/pia/vpn.conf "${VPN_CONFIG_DIR}/"
rm -rf /tmp/pia*
```

Securely create your VPN authentication file:

```shell script
sudo touch ${VPN_CONFIG_DIR}/vpn.auth
sudo chmod 600 ${VPN_CONFIG_DIR}/vpn.auth
```

`sudoedit ${VPN_CONFIG_DIR}/vpn.auth`, with your PIA username and password:

```text
your_pia_username
your_pia_password
```

Load the `tun` module:

```shell script
echo tun | sudo tee /etc/modules-load.d/tun.conf
sudo modprobe tun
```

Start the VPN container:

```shell script
./scripts/vpn.sh
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
source scripts/env.sh
sudo mkdir -p "$VIDEOS_DIR/downloads/torrents" "$JACKETT_CONFIG_DIR"
sudo chown -R "$APP_USER:$APP_GROUP" "$VIDEOS_DIR" "$JACKETT_CONFIG_DIR"
```

Start the Jackett container:

```shell script
./scripts/jackett.sh
```

Add the container to systemd for service management:

```shell script
sudo cp systemd/jackett-container.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now jackett-container.service
```

Open a web browser and enter the address with your hostname:
* http://example.com:9117/

### Install Deluge Container

Create the required directories:

```shell script
scripts/env.sh
sudo mkdir -p "$VIDEOS_DIR/downloads/{deluge,torrents}" "$DELUGE_CONFIG_DIR"
sudo chown -R "$APP_USER:$APP_GROUP" "$VIDEOS_DIR" "$DELUGE_CONFIG_DIR"
```

Start the Deluge container:

```shell script
./scripts/deluge.sh
```

Add the container to systemd for service management:

```shell script
sudo cp systemd/deluge-container.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now deluge-container.service
```

Open a web browser and enter the address with your hostname:
* http://example.com:8112/

### Install SABnzbd Container

Create the required directories:

```shell script
source scripts/env.sh
sudo mkdir -p "$VIDEOS_DIR/downloads/sabnzbd/{incomplete,complete}" "$SABNZBD_CONFIG_DIR"
sudo chown -R "$APP_USER:$APP_GROUP" "$VIDEOS_DIR" "$SABNZBD_CONFIG_DIR"
```

As this service is running on the host network, we need to open the firewall for it:

```shell script
sudo firewall-cmd --new-service-from-file firewalld/sabnzbd.xml --permanent
sudo firewall-cmd --add-service sabnzbd --permanent
sudo firewall-cmd --reload
```

Start the SABnzbd container:

```shell script
./scripts/sabnzbd.sh
```

Add the container to systemd for service management:

```shell script
sudo cp systemd/sabnzbd-container.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now sabnzbd-container.service
```

SABnzbd binds to the localhost, we need to change that if you want to access it from another host:

```shell script
sudo systemctl stop sabnzbd-container.service
sudo sed -i 's/^host =.*/host = 0.0.0.0/' ${SABNZBD_CONFIG_DIR}/.sabnzbd/sabnzbd.ini
sudo systemctl start sabnzbd-container.service
```

Open a web browser and enter the address with your hostname:
* http://example.com:8080/

### Install Sonarr Container

Create the required directories:

```shell script
source scripts/env.sh
sudo mkdir -p "$VIDEOS_DIR/TVShows" "$SONARR_CONFIG_DIR"
sudo chown -R "$APP_USER:$APP_GROUP" "$VIDEOS_DIR $SONARR_CONFIG_DIR"
```

As this service is running on the host network, we need to open the firewall for it:

```shell script
sudo firewall-cmd --new-service-from-file firewalld/sonarr.xml --permanent
sudo firewall-cmd --add-service sonarr --permanent
sudo firewall-cmd --reload
```

Start the Sonarr container:

```shell script
./scripts/sonarr.sh
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
source scripts/env.sh
sudo mkdir -p "$VIDEOS_DIR/Movies" "$RADARR_CONFIG_DIR"
sudo chown -R "$APP_USER:$APP_GROUP" "$VIDEOS_DIR" "$RADARR_CONFIG_DIR"
```

As this service is running on the host network, we need to open the firewall for it:

```shell script
sudo firewall-cmd --new-service-from-file firewalld/radarr.xml --permanent
sudo firewall-cmd --add-service radarr --permanent
sudo firewall-cmd --reload
```

Start the Radarr container:

```shell script
./scripts/radarr.sh
```

Add the container to systemd for service management:

```shell script
sudo cp systemd/radarr-container.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now radarr-container.service
```

Open a web browser and enter the address with your hostname:
* http://example.com:7878/

### Install Plex Media Server Container

This install is using the [official Plex Media Server container](https://hub.docker.com/r/plexinc/pms-docker/).

Create the required directories, and set their permissions:

```shell script
source scripts/env.sh
sudo mkdir -p "$VIDEOS_DIR/{TVShows,Movies}" "$PLEX_CONFIG_DIR" "$PLEX_TRANSCODE_DIR"
sudo chown -R "$APP_USER:$APP_GROUP" "$VIDEOS_DIR" "$PLEX_CONFIG_DIR" "$PLEX_TRANSCODE_DIR"
```

As this service is running on the host network, we need to open the firewall for it:

```shell script
sudo firewall-cmd --new-service-from-file firewalld/plexmediaserver.xml --permanent
sudo firewall-cmd --add-service plexmediaserver --permanent
sudo firewall-cmd --reload
```

Generate a [Plex Claim Token](https://www.plex.tv/claim/), then save it to an environment variable:

```shell script
export PLEX_CLAIM_TOKEN=claim-xxx
```

Create the Plex Media Server container:

```shell script
./scripts/plex.sh
```

Add the container to systemd for service management:

```shell script
sudo cp systemd/plex-container.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now plex-container.service
```

Open a web browser and enter the address with your hostname:
* http://example.com:32400/web/index.html

