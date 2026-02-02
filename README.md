# KioskFrame

KioskFrame turns a 32-bit antiX (i386) laptop into a single-purpose appliance:
- DLNA-backed photo/video frame (shuffle slideshow) via local DLNA mount.
- MagicMirror-style dashboard for calendars and todos.
- Single Chromium kiosk shell that can switch between Frame and Mirror views.

## Recommended OS
- antiX 23 (full or base). A minimal install is ideal for Atom-class CPUs.

## Install
```sh
sudo ./install.sh
```

Optional: install MagicMirror
```sh
sudo ./mirror/install_magicmirror.sh /opt/appliance/magicmirror
```

Then open the Web UI:
```
http://<host>:8080/
```

## Finding Your DLNA Server Dir
After `djmount` is running, browse `/mnt/dlna` to see server directories. The name you see is `photoframe.server_dir`.

## Calendar Sources
- **Google Calendar**: use the public or private ICS URL (private has full details; treat as sensitive).
- **Outlook/Office365**: use a shared ICS URL. If the provider requires headers, enable the proxy fetcher.
- When `fetch_via_proxy` is enabled, KioskFrame stores the ICS under `/var/lib/appliance/calendars/<name>.ics` and serves it locally to MagicMirror.

## Tasks Providers
- **Google Tasks**: create OAuth credentials, then store `credentials.json` and generated token under `/etc/appliance/secrets`.
- **Microsoft To Do**: create an Azure app and store the client ID, tenant ID, and refresh token under `/etc/appliance/secrets`.

## Web UI
- Settings: `http://<host>:8080/settings`
- Status: `http://<host>:8080/status`
- Logs: `http://<host>:8080/logs`

## Kiosk Boot
KioskFrame expects Xorg on `tty1` and autologin as user `frame`. The `kiosk` service launches Chromium fullscreen on boot.

On antiX (sysvinit), add an autologin getty for tty1, for example in `/etc/inittab`:
```
1:2345:respawn:/sbin/agetty --autologin frame --noclear 38400 tty1 linux
```

## Uninstall
```sh
sudo ./uninstall.sh
```

To remove config/data/logs:
```sh
sudo ./uninstall.sh --purge
```

## License
MIT
