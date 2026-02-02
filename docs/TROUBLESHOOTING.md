# Troubleshooting

## djmount issues
- Ensure `djmount` is installed and the DLNA server is reachable.
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
- Try an older MagicMirror release if 32-bit Node builds are limited.

## Calendar fetch errors
- Check `/var/log/appliance/calendar_fetch.log` for HTTP errors.
- If the provider needs headers, set `headers_file` and enable `fetch_via_proxy`.
- If Basic Auth is enabled and calendars are proxied through the Web UI, MagicMirror may not be able to fetch them. Consider disabling Basic Auth or using direct ICS URLs.
