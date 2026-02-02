# Security

- Enable Basic Auth in `/etc/appliance/appliance.yaml` and use a strong password.
- Restrict Web UI access to your LAN using firewall rules.
- Secrets live under `/etc/appliance/secrets` with `600` permissions. Do not share these files.
- Prefer private network segments and disable inbound access from the internet.
