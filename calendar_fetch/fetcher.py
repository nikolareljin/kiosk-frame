#!/usr/bin/env python3
import json
import os
import sys
import time
import yaml
import requests

CONFIG_PATH = "/etc/appliance/appliance.yaml"
LOG_PATH = "/var/log/appliance/calendar_fetch.log"


def log(msg):
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {msg}\n")


def load_config():
    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_headers(path):
    if not path:
        return {}
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as exc:
        log(f"failed to load headers {path}: {exc}")
        return {}


def fetch_once(cfg):
    calendars = cfg.get("calendars", [])
    calendars_dir = cfg["paths"]["calendars_dir"]
    os.makedirs(calendars_dir, exist_ok=True)

    ua = cfg.get("calendar_fetch", {}).get("user_agent", "KioskFrame/1.0")

    for cal in calendars:
        name = cal.get("name") or "calendar"
        url = cal.get("url", "")
        if not url:
            continue
        headers = {"User-Agent": ua}
        headers.update(load_headers(cal.get("headers_file", "")))
        try:
            resp = requests.get(url, headers=headers, timeout=20)
            resp.raise_for_status()
            out_path = os.path.join(calendars_dir, f"{name}.ics")
            with open(out_path, "wb") as f:
                f.write(resp.content)
            log(f"fetched {name} -> {out_path}")
        except Exception as exc:
            log(f"fetch failed {name}: {exc}")


def main():
    cfg = load_config()
    if len(sys.argv) > 1 and sys.argv[1] == "once":
        fetch_once(cfg)
        return 0

    refresh_min = cfg.get("calendar_fetch", {}).get("refresh_minutes", 15)
    while True:
        fetch_once(cfg)
        time.sleep(max(1, int(refresh_min)) * 60)


if __name__ == "__main__":
    sys.exit(main())
