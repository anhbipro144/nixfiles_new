"""Explicitly replace selected MCPJungle registrations from Home Manager files."""

import argparse
import json
import os
from pathlib import Path
import sqlite3
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config-dir", type=Path, required=True)
    parser.add_argument("--database", type=Path, required=True)
    parser.add_argument("--mcpjungle", required=True)
    parser.add_argument("servers", nargs="*", help="server names; default: all managed servers")
    args = parser.parse_args()
    available = {p.stem: p for p in (args.config_dir / "servers").glob("*.json")}
    names = args.servers or sorted(available)
    if not names or set(names) - available.keys():
        parser.error("select installed server names from: " + ", ".join(sorted(available)))

    # Validate every selected file and credential before changing registrations.
    configs = []
    for name in names:
        settings = json.loads(available[name].read_text())
        if settings.get("name") != name:
            parser.error(f"configuration name does not match {name}")
        if name == "figma_framelink":
            key_file = args.config_dir / "figma-api-key"
            key = os.environ.get("FIGMA_API_KEY", "").strip()
            if not key and key_file.is_file():
                if key_file.stat().st_mode & 0o077:
                    parser.error(f"run chmod 600 {key_file} before syncing")
                key = key_file.read_text().strip()
            if not key:
                parser.error(f"set FIGMA_API_KEY or put the key in {key_file} (mode 600)")
            settings.setdefault("env", {})["FIGMA_API_KEY"] = key
        configs.append(settings)

    cli = [args.mcpjungle, "--registry", "http://127.0.0.1:37373"]
    if subprocess.run(cli + ["list", "servers"], stdout=subprocess.DEVNULL,
                      stderr=subprocess.DEVNULL).returncode:
        parser.exit(1, "MCPJungle is unavailable at 127.0.0.1:37373; start the gateway first.\n")

    if args.database.is_file():
        backup_dir = args.database.parent / "backups"
        backup_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(prefix="before-sync-", suffix=".db",
                                         dir=backup_dir, delete=False) as backup:
            backup_path = Path(backup.name)
            with sqlite3.connect(args.database.resolve().as_uri() + "?mode=ro", uri=True) as source:
                with sqlite3.connect(backup_path) as destination:
                    source.backup(destination)
        print(f"Database backup: {backup_path}", flush=True)

    for settings in configs:
        # The resolved secret is written only to a private temporary file.
        with tempfile.TemporaryDirectory(prefix="mcpjungle-sync-") as directory:
            path = Path(directory) / "server.json"
            with open(path, "w", opener=lambda p, flags: os.open(p, flags, 0o600)) as stream:
                json.dump(settings, stream)
            result = subprocess.run(cli + ["register", "--force", "--conf", str(path)],
                                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if result.returncode:
            parser.exit(1, f"Registration failed for {settings['name']}; stopped. "
                        "Earlier registrations may have changed; the database backup is preserved.\n")
        print(f"Synced {settings['name']}", flush=True)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, sqlite3.Error):
        raise SystemExit("Sync failed; check configuration paths, file permissions, and SQLite. "
                         "If registration had started, earlier servers may already have changed.") from None
