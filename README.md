# Damo's Media Pod

This tutorial will show the technical instructions to install Plex,
Sonarr, Radarr, SABNZBd, qBittorrent, Prowlarr, and Gluetun.

The instructions were written for an Enterprise Linux 9 minimal install,
and should work for CentOS Stream release 9, AlmaLinux 9, and Rocket Linux 9.

This setup will send qBittorrent and Prowler through the VPN using Gluetun,
the rest of the traffic will go direct.

## User Setup

```bash
sudo dnf install git podman
sudo useradd -G video media
sudo loginctl enable-linger media
sudo setsebool -P container_use_devices=true
sudo su - media
git clone https://github.com/damiantroy/media-pod.git
mkdir -p ~/.bashrc.d
echo "export XDG_RUNTIME_DIR=/run/user/$(id -u)" > ~/.bashrc.d/systemd
source ~/.bashrc.d/systemd
```

## File Storage

We'll be using `/srv` for config, and `/data` for media files, so make sure
you configure the appropriate partitions before this step.

```bash
sudo mkdir -p /srv/{prowlarr,qbittorrent,radarr,sabnzbd,sonarr}
sudo mkdir -p /data/media/{Movies,TV,RealityTV,KidsMovies,KidsTV}
sudo mkdir -p /data/{usenet,torrents}/{movies,tv,incomplete}
sudo mkdir -p /var/lib/plex/Transcode
sudo chown media:media -R /data/{usenet,torrents,media} \
    /srv/{prowlarr,qbittorrent,radarr,sabnzbd,sonarr} /var/lib/plex
sudo su - media
podman unshare chown -R media:media /data/{usenet,torrents,media} \
    /srv/{prowlarr,qbittorrent,radarr,sabnzbd,sonarr} /var/lib/plex
```

## Networking

```bash
echo ip_tables | sudo tee /etc/modules-load.d/ip_tables.conf
sudo systemctl restart systemd-modules-load
sudo firewall-cmd --add-masquerade --permanent
for SERVICE in prowlarr qbittorrent radarr sabnzbd sonarr; do
    sudo firewall-cmd --new-service-from-file ~media/media-pod/firewalld/${SERVICE}.xml --permanent
    sudo firewall-cmd --add-service $SERVICE --permanent
done
sudo firewall-cmd --add-service plex --permanent
sudo firewall-cmd --reload
```

## Quickstart

```bash
sudo su - media
mkdir -p ~/.config/containers/systemd ~/.config/environment.d
cp ~/media-pod/systemd/* ~/.config/containers/systemd/
cp ~/media-pod/environment.d/* ~/.config/environment.d/
vi ~/.config/environment.d/media.conf
vi ~/.config/environment.d/gluetun.env
systemctl --user daemon-reload
systemctl --user start gluetun prowlarr qbittorrent sabnzbd radarr sonarr plex
```

## Bookmarks

Replace 'localhost' with your server IP:

* Plex: http://localhost:32400/web/
* Sonarr: http://localhost:8989/
* Radarr: http://localhost:7878/
* SABnzbd: http://localhost:8080/
* qBittorrent: http://localhost:8111/
* Prowlarr: http://localhost:9696/

## Config

### Global

Config: `~/.config/environment.d/media.conf`

### Gluetun

Gluetun config: `~/.config/environment.d/gluetun.env`

Update the config file with your VPN details then start the service as
the `media` user:

```bash
sudo su - media
vi ~/.config/environment.d/gluetun.env
systemctl --user start gluetun
```

### qBittorrent

```bash
systemctl --user start qbittorrent
podman logs qbittorrent 2>&1 |grep 'temporary password'
```

URL: http://localhost:8111/ (Replace localhost if needed)
Username: admin
Password: (from the `podman logs` command above)

Config:
- Downloads:
  - Default Save Path: /data/torrents
  - Keep incomplete torrents in: /data/torrents/incomplete
- Connection:
  - Port used for incoming connections: 6881
- WebUI:
  - Username
  - Password
  - Bypass authentication for clients in whitelisted IP subnets: 10.0.0.0/8, 192.168.0.0/16

### SABnzbd

```bash
systemctl --user start sabnzbd
```

URL: http://localhost:8080/ (Replace localhost if needed)

Config
- Add your server
- Folders:
  - Completed Download Folder: /data/usenet
  - Temporary Download Folder: /data/usenet/incomplete
- Categories:
  - movies -> /data/usenet/movies
  - tv -> /data/usenet/tv

### Radarr

```bash
systemctl --user start radarr
```

URL: http://localhost:7878/ (Replace localhost if needed)

Config:
- Settings > Download Clients
  - Add SABnzbd and qBittorrent
  - Change Host to server IP address
  - Change Category to 'movies'
  - qBittorrent
    - Change Port to 8111

### Sonarr

```bash
systemctl --user start sonarr
```

URL: http://localhost:8989/

Config:
- Settings > Download Clients
  - Add SABnzbd and qBittorrent
  - Change Host to server IP address
  - Change Category to 'tv'
  - qBittorrent
    - Change Port to 8111


### Prowlarr

```bash
systemctl --user start prowlarr
```

URL: http://localhost:9696/

Config:
- Indexers:
  - Add your preferred NZB and torrent indexers
- Settings:
  - Apps and Download Clients:
    - Add Sonarr, Radarr, SABnzbd, qBittorrent
    - Use server IP, not localhost
    - Copy API Key from under Settings/General
    - qBittorrent: Change port to 8111

### Plex


```bash
systemctl --user start prowlarr
```

URL: http://localhost:32400/web/

Config:
- Chose Add Library to add each of the folders under /data/media

