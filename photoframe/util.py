#!/usr/bin/env python3
import os
import time
import yaml

CONFIG_PATH = "/etc/appliance/appliance.yaml"


def load_config(path=CONFIG_PATH):
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def now_ts():
    return time.strftime("%Y-%m-%d %H:%M:%S")


def log(msg, logs_dir="/var/log/appliance"):
    os.makedirs(logs_dir, exist_ok=True)
    with open(os.path.join(logs_dir, "photoframe.log"), "a", encoding="utf-8") as f:
        f.write(f"[{now_ts()}] {msg}\n")
