#!/usr/bin/env python3
import os
import json
import yaml

CONFIG_PATH = "/etc/appliance/appliance.yaml"
OUT_PATH = "/opt/appliance/magicmirror/config/config.js"


def load_config():
    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def build_calendars(cfg):
    items = []
    for cal in cfg.get("calendars", []):
        name = cal.get("name", "Calendar")
        url = cal.get("url", "")
        if cal.get("fetch_via_proxy", False):
            url = f"http://127.0.0.1:{cfg['webui']['port']}/static/calendars/{name}.ics"
        if not url:
            continue
        items.append({"symbol": "calendar", "url": url, "name": name})
    return items


def build_modules(cfg):
    modules = []
    calendars = build_calendars(cfg)
    modules.append({
        "module": "calendar",
        "position": "top_left",
        "config": {"calendars": calendars},
    })

    if cfg.get("todos", {}).get("google_tasks", {}).get("enabled", False):
        modules.append({
            "module": "MMM-GoogleTasks",
            "position": "top_right",
            "config": {
                "credentials": cfg["todos"]["google_tasks"]["credentials_file"],
                "token": cfg["todos"]["google_tasks"]["token_file"],
            },
        })

    if cfg.get("todos", {}).get("microsoft_todo", {}).get("enabled", False):
        modules.append({
            "module": "MMM-MicrosoftToDo",
            "position": "top_right",
            "config": {
                "clientIdFile": cfg["todos"]["microsoft_todo"]["client_id_file"],
                "tenantIdFile": cfg["todos"]["microsoft_todo"]["tenant_id_file"],
                "refreshTokenFile": cfg["todos"]["microsoft_todo"]["refresh_token_file"],
            },
        })

    return modules


def write_config(cfg):
    modules = build_modules(cfg)
    data = {
        "address": cfg["mirror"]["host"],
        "port": cfg["mirror"]["port"],
        "basePath": "/",
        "ipWhitelist": [],
        "language": "en",
        "timeFormat": 24,
        "units": "metric",
        "modules": modules,
    }

    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    with open(OUT_PATH, "w", encoding="utf-8") as f:
        f.write("var config = ")
        f.write(json.dumps(data, indent=2))
        f.write(";\n\nif (typeof module !== 'undefined') { module.exports = config; }\n")


def main():
    cfg = load_config()
    write_config(cfg)


if __name__ == "__main__":
    main()
