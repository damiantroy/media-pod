# Damo's Media Pod

This tutorial will show the technical instructions for install Plex,
along with Sonarr, Radarr, SABNZBd, qBittorrent, and Prowlarr.

The instructions are written for Enterprise Linux 9 running Podman. I've
written the tutorial on CentOS Stream release 9, but it should also work
on AlmaLinux 9, and Rocky Linux 9.

## User Setup

```bash
sudo dnf install git podman
sudo useradd -G video media
sudo loginctl enable-linger media
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
sudo mkdir -p /data/{usenet,torrents,media}/{movies,tv}
sudo mkdir -p /data/{usenet,torrents}/incomplete
sudo mkdir -p /var/lib/plex/Transcode
sudo chown media:media -R /data/{usenet,torrents,media} /srv/{prowlarr,qbittorrent,radarr,sabnzbd,sonarr} /var/lib/plex
sudo su - media
podman unshare chown -R media:media /data/{usenet,torrents,media} /srv/{prowlarr,qbittorrent,radarr,sabnzbd,sonarr} /var/lib/plex
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

## Containers

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

