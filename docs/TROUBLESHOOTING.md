# Troubleshooting

## Optional djmount issues
- If your package repository provides `djmount`, install it and ensure the DLNA server is reachable. Without it, use local media paths.
- Check `/var/log/appliance/photoframe.log` and the service status page.

## mpv not starting
- Confirm `/var/lib/appliance/playlist.m3u` contains media paths.
- Verify file permissions under `/mnt/dlna`.

## Chromium kiosk black screen
- Verify Xorg is running on tty1.
- Check that `chromium` or `chromium-browser` is installed.
- Test running `/opt/appliance/kiosk/xsession.sh` manually under the `frame` user.

## MagicMirror node issues
- Ensure Node.js and npm are installed.
- Check MagicMirror install in `/opt/appliance/magicmirror`.
- The installer automatically uses MagicMirror v2.25.0 with Node.js 18–23; Node.js 24+ uses the current release.

## Calendar fetch errors
- Check `/var/log/appliance/calendar_fetch.log` for HTTP errors.
- If the provider needs headers, set `headers_file` and enable `fetch_via_proxy`.
- If Basic Auth is enabled and calendars are proxied through the Web UI, MagicMirror may not be able to fetch them. Consider disabling Basic Auth or using direct ICS URLs.
