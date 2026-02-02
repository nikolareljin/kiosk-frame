#!/usr/bin/env python3
import os
import signal
import subprocess
import sys
from util import load_config, log


def pid_file():
    return "/var/run/photoframe-mpv.pid"


def is_running():
    try:
        with open(pid_file(), "r", encoding="utf-8") as f:
            pid = int(f.read().strip())
        os.kill(pid, 0)
        return pid
    except Exception:
        return None


def start():
    cfg = load_config()
    playlist = cfg["paths"]["playlist"]
    pf = cfg["photoframe"]
    if not os.path.isfile(playlist):
        log("playlist missing, refusing to start mpv")
        return 2

    cmd = [
        "mpv",
        "--fs",
        "--no-osd-bar",
        "--input-default-bindings=no",
        "--input-vo-keyboard=no",
        "--no-border",
        "--keep-open=yes",
        "--loop-playlist=yes",
        f"--image-display-duration={pf.get('image_display_duration', 12)}",
    ]
    if pf.get("shuffle", True):
        cmd.append("--shuffle")
    if pf.get("mute", True):
        cmd.append("--mute=yes")
    cmd.append(playlist)

    proc = subprocess.Popen(cmd)
    with open(pid_file(), "w", encoding="utf-8") as f:
        f.write(str(proc.pid))
    log(f"mpv started pid={proc.pid}")
    return 0


def stop():
    pid = is_running()
    if not pid:
        return 0
    try:
        os.kill(pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    try:
        os.remove(pid_file())
    except FileNotFoundError:
        pass
    log("mpv stopped")
    return 0


def status():
    pid = is_running()
    if pid:
        print(pid)
        return 0
    return 1


def main():
    if len(sys.argv) < 2:
        print("usage: framectl.py start|stop|status")
        return 1
    cmd = sys.argv[1]
    if cmd == "start":
        return start()
    if cmd == "stop":
        return stop()
    if cmd == "status":
        return status()
    print("unknown command")
    return 1


if __name__ == "__main__":
    sys.exit(main())
