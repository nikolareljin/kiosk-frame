#!/usr/bin/env python3
import os
import sys
from util import load_config, log

IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp"}
VIDEO_EXTS = {".mp4", ".mkv", ".avi", ".mov", ".webm", ".m4v"}


def iter_media(root_dir):
    for base, _dirs, files in os.walk(root_dir):
        for name in files:
            path = os.path.join(base, name)
            ext = os.path.splitext(name)[1].lower()
            if ext in IMAGE_EXTS or ext in VIDEO_EXTS:
                yield path


def build_root(cfg):
    dlna_mount = cfg["paths"]["dlna_mount"]
    server_dir = cfg["photoframe"].get("server_dir", "")
    subpath = cfg["photoframe"].get("subpath", "")
    root = os.path.join(dlna_mount, server_dir, subpath)
    return os.path.normpath(root)


def main():
    cfg = load_config()
    playlist_path = cfg["paths"]["playlist"]
    root = build_root(cfg)

    if not os.path.isdir(root):
        log(f"playlist root missing: {root}")
        return 2

    os.makedirs(os.path.dirname(playlist_path), exist_ok=True)
    count = 0
    with open(playlist_path, "w", encoding="utf-8") as f:
        for media in iter_media(root):
            f.write(media + "\n")
            count += 1

    log(f"playlist refreshed: {count} items from {root}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
