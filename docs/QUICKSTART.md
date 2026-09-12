# Quickstart

1) Install dependencies (antiX packages):
```
sudo apt update
sudo apt install mpv xorg xinit x11-xserver-utils chromium python3 python3-venv python3-pip nodejs npm ffmpeg curl
```
DLNA mounting is optional. If `apt-cache show djmount` succeeds on your base, install `djmount` too; otherwise the photo slideshow can use local media only.


2) Install KioskFrame:
```
sudo ./install.sh
```

Optionally verify dependencies:
```
./check_deps.sh
```

3) Configure `/etc/appliance/appliance.yaml` and open the Web UI:
```
http://<host>:8080/
```

4) (Optional) Install MagicMirror:
```
sudo ./mirror/install_magicmirror.sh /opt/appliance/magicmirror
```

5) Reboot to verify kiosk autostart.
