#!/usr/bin/env python3
"""Open a Rex source block's scrollback in the isolated Vim copy viewer."""

from pathlib import Path
import os
import shutil
import subprocess
import sys
import tempfile


def main():
    if len(sys.argv) != 2 or not os.environ.get("REX_SESSION"):
        raise RuntimeError("a Rex session and source block are required")
    for program in ("rex", "nvim"):
        if not shutil.which(program):
            raise RuntimeError(f"{program} is required on PATH")
    command = ["rex", "--autostart=false", "--timeout", "30s"]
    if os.environ.get("REX_SERVER"):
        command.extend(["--server", os.environ["REX_SERVER"]])
    command.extend([
        "capture", "--session", os.environ["REX_SESSION"],
        "--block", sys.argv[1], "--unwrap",
    ])
    capture = subprocess.run(command, capture_output=True, timeout=35)
    if capture.returncode:
        raise RuntimeError(capture.stderr.decode(errors="replace").strip() or "Rex capture failed")
    # A private directory (0700) keeps captured terminal output out of shared
    # files. The snapshot is removed after the viewer exits, including failure.
    with tempfile.TemporaryDirectory(prefix="rex-copy-") as directory:
        snapshot = Path(directory) / "scrollback.txt"
        snapshot.write_bytes(capture.stdout)
        return subprocess.run([
            "nvim", "-u", str(Path(__file__).resolve().with_name("copy_mode.lua")),
            "-i", "NONE", "-n", "-R", "--", str(snapshot),
        ]).returncode


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, OSError, subprocess.TimeoutExpired) as error:
        print(f"Rex copy mode: {error}", file=sys.stderr)
        if sys.stdin.isatty():
            try:
                input("Press Enter to close...")
            except EOFError:
                pass
        raise SystemExit(1)
