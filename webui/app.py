#!/usr/bin/env python3
import os
import subprocess
from functools import wraps

import yaml
from flask import Flask, request, render_template, redirect, url_for, Response, send_from_directory

CONFIG_PATH = "/etc/appliance/appliance.yaml"
LOG_DIR = "/var/log/appliance"

app = Flask(__name__)


def load_config():
    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def save_config(cfg):
    with open(CONFIG_PATH, "w", encoding="utf-8") as f:
        yaml.safe_dump(cfg, f, sort_keys=False)


def init_system():
    if os.path.isdir("/etc/runit") and shutil_which("sv"):
        return "runit"
    return "sysvinit"


def shutil_which(name):
    for path in os.environ.get("PATH", "").split(os.pathsep):
        full = os.path.join(path, name)
        if os.path.isfile(full) and os.access(full, os.X_OK):
            return full
    return None


def service_action(service, action):
    system = init_system()
    if system == "runit":
        return subprocess.run(["sv", action, service], check=False)
    return subprocess.run(["/etc/init.d/%s" % service, action], check=False)


def is_running(proc_name):
    return subprocess.run(["pgrep", "-f", proc_name], check=False).returncode == 0


def tail_log(path, lines=200):
    if not os.path.exists(path):
        return "(log not found)"
    return subprocess.check_output(["tail", "-n", str(lines), path], text=True)


def require_auth(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        cfg = load_config()
        auth = cfg.get("webui", {}).get("basic_auth", {})
        if not auth.get("enabled", False):
            return view(*args, **kwargs)

        provided = request.authorization
        if not provided or provided.username != auth.get("username") or provided.password != auth.get("password"):
            return Response("Authentication required", 401, {"WWW-Authenticate": "Basic realm='KioskFrame'"})
        return view(*args, **kwargs)
    return wrapped


@app.route("/")
@require_auth
def home():
    cfg = load_config()
    return render_template("home.html", cfg=cfg)


@app.route("/frame")
@require_auth
def frame():
    cfg = load_config()
    return render_template("frame.html", cfg=cfg)


@app.route("/mirror")
@require_auth
def mirror():
    cfg = load_config()
    mirror_url = f"http://{cfg['mirror']['host']}:{cfg['mirror']['port']}/"
    return render_template("mirror.html", cfg=cfg, mirror_url=mirror_url)


@app.route("/settings", methods=["GET", "POST"])
@require_auth
def settings():
    cfg = load_config()
    if request.method == "POST":
        cfg["photoframe"]["enabled"] = request.form.get("pf_enabled") == "on"
        cfg["paths"]["dlna_mount"] = request.form.get("dlna_mount", "/mnt/dlna")
        cfg["photoframe"]["server_dir"] = request.form.get("server_dir", "")
        cfg["photoframe"]["subpath"] = request.form.get("subpath", "")
        cfg["photoframe"]["image_display_duration"] = int(request.form.get("image_duration", 12))
        cfg["photoframe"]["playlist_refresh_seconds"] = int(request.form.get("playlist_refresh", 300))
        cfg["photoframe"]["shuffle"] = request.form.get("shuffle") == "on"
        cfg["photoframe"]["mute"] = request.form.get("mute") == "on"

        cfg["mirror"]["enabled"] = request.form.get("mm_enabled") == "on"

        cfg["todos"]["google_tasks"]["enabled"] = request.form.get("gt_enabled") == "on"
        cfg["todos"]["google_tasks"]["credentials_file"] = request.form.get("gt_credentials", cfg["todos"]["google_tasks"]["credentials_file"])
        cfg["todos"]["google_tasks"]["token_file"] = request.form.get("gt_token", cfg["todos"]["google_tasks"]["token_file"])

        cfg["todos"]["microsoft_todo"]["enabled"] = request.form.get("mt_enabled") == "on"
        cfg["todos"]["microsoft_todo"]["client_id_file"] = request.form.get("mt_client_id", cfg["todos"]["microsoft_todo"]["client_id_file"])
        cfg["todos"]["microsoft_todo"]["tenant_id_file"] = request.form.get("mt_tenant_id", cfg["todos"]["microsoft_todo"]["tenant_id_file"])
        cfg["todos"]["microsoft_todo"]["refresh_token_file"] = request.form.get("mt_refresh_token", cfg["todos"]["microsoft_todo"]["refresh_token_file"])

        cfg["calendar_fetch"]["enabled"] = request.form.get("cal_enabled") == "on"
        cfg["calendar_fetch"]["refresh_minutes"] = int(request.form.get("cal_refresh", 15))

        cfg["webui"]["basic_auth"]["enabled"] = request.form.get("auth_enabled") == "on"
        cfg["webui"]["basic_auth"]["username"] = request.form.get("auth_user", "admin")
        cfg["webui"]["basic_auth"]["password"] = request.form.get("auth_pass", "change_me")

        calendars_yaml = request.form.get("calendars_yaml", "")
        try:
            cfg["calendars"] = yaml.safe_load(calendars_yaml) or []
        except Exception:
            pass

        save_config(cfg)
        subprocess.run(["/opt/appliance/venv/bin/python", "/opt/appliance/mirror/render_config.py"], check=False)
        service_action("magicmirror", "restart")
        return redirect(url_for("settings"))

    calendars_yaml = yaml.safe_dump(cfg.get("calendars", []), sort_keys=False)
    return render_template("settings.html", cfg=cfg, calendars_yaml=calendars_yaml)


@app.route("/status")
@require_auth
def status():
    cfg = load_config()
    status_data = {
        "djmount": is_running("djmount"),
        "mpv": is_running("mpv"),
        "magicmirror": is_running("node serveronly"),
        "calendar_fetch": is_running("fetcher.py"),
    }
    dlna_dir = cfg["paths"]["dlna_mount"]
    server_dirs = []
    if os.path.isdir(dlna_dir):
        server_dirs = sorted([d for d in os.listdir(dlna_dir) if os.path.isdir(os.path.join(dlna_dir, d))])
    return render_template("status.html", cfg=cfg, status=status_data, server_dirs=server_dirs)


@app.route("/logs")
@require_auth
def logs():
    logs = {
        "webui": tail_log(os.path.join(LOG_DIR, "webui.log")),
        "photoframe": tail_log(os.path.join(LOG_DIR, "photoframe.log")),
        "photoframe_watchdog": tail_log(os.path.join(LOG_DIR, "photoframe-watchdog.log")),
        "calendar_fetch": tail_log(os.path.join(LOG_DIR, "calendar_fetch.log")),
    }
    return render_template("logs.html", logs=logs)


@app.route("/static/calendars/<path:name>")
@require_auth
def calendars(name):
    cfg = load_config()
    return send_from_directory(cfg["paths"]["calendars_dir"], name)


@app.post("/action/<name>")
@require_auth
def action(name):
    if name == "restart_photoframe":
        service_action("photoframe", "restart")
    elif name == "restart_mirror":
        service_action("magicmirror", "restart")
    elif name == "rescan_dlna":
        service_action("djmount", "restart")
    elif name == "fetch_calendars":
        subprocess.run(["/opt/appliance/calendar_fetch/fetcher.py", "once"], check=False)
    return redirect(request.referrer or url_for("home"))


if __name__ == "__main__":
    cfg = load_config()
    app.run(host=cfg["webui"]["host"], port=cfg["webui"]["port"], debug=False)
