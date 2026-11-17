#!/usr/bin/env python3
"""Open a Rex source block's scrollback in the isolated Vim copy viewer."""

from pathlib import Path
import os
import json
import re
import shutil
import subprocess
import sys
import tempfile


ESCAPE = re.compile(r"\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x07\x1b]*(?:\x07|\x1b\\)|[PX^_][\s\S]*?\x1b\\|[@-_])")
SGR = re.compile(r"\x1b\[[0-9;:]*m")


def display_text(raw):
    """Keep printable output and colors, never replay terminal commands."""
    text = raw.decode("utf-8", errors="replace").replace("\r\n", "\n")
    text = ESCAPE.sub(lambda match: match[0] if SGR.fullmatch(match[0]) else "", text)
    text = re.sub(r"[\x00-\x08\x0b-\x1a\x1c-\x1f\x7f-\x9f]|\x1b(?!\[[0-9;:]*m)", "", text)
    return text.expandtabs(8).rstrip("\n") + "\n"


def restore_source(command, source, zoomed):
    """Restore focus only if the user is still in this viewer."""
    session = os.environ["REX_SESSION"]
    result = subprocess.run(command + ["api", "call", "-s", session, "session.view"],
                            capture_output=True, timeout=10)
    if result.returncode:
        return
    view = json.loads(result.stdout)
    for window in view.get("windows", []):
        if (window["window_id"] == view.get("active_window_id")
                and window.get("focused_block_id") == os.environ.get("REX_BLOCK")):
            method = "session.zoom_block" if zoomed else "session.focus_block"
            args = {"block_id": source}
            if zoomed:
                args["zoom"] = True
            subprocess.run(command + ["api", "call", "-s", session, method, json.dumps(args)],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=10)
            return


def main():
    if len(sys.argv) not in (2, 4) or not os.environ.get("REX_SESSION"):
        raise RuntimeError("a Rex session and source block are required")
    for program in ("rex", "nvim"):
        if not shutil.which(program):
            raise RuntimeError(f"{program} is required on PATH")
    command = ["rex", "--autostart=false", "--timeout", "30s"]
    if os.environ.get("REX_SERVER"):
        command.extend(["--server", os.environ["REX_SERVER"]])
    capture_command = command + [
        "capture", "--session", os.environ["REX_SESSION"],
        "--block", sys.argv[1], "--unwrap", "--format", "vt",
    ]
    capture = subprocess.run(capture_command, capture_output=True, timeout=35)
    if capture.returncode:
        raise RuntimeError(capture.stderr.decode(errors="replace").strip() or "Rex capture failed")
    # A private directory (0700) keeps captured terminal output out of shared
    # files. The snapshot is removed after the viewer exits, including failure.
    with tempfile.TemporaryDirectory(prefix="rex-copy-") as directory:
        snapshot = Path(directory) / "scrollback.vt"
        snapshot.write_text(display_text(capture.stdout))
        settings = {"file": str(snapshot), "start": sys.argv[2] if len(sys.argv) == 4 else "bottom"}
        try:
            return subprocess.run([
                "nvim", "-u", str(Path(__file__).resolve().with_name("copy_mode.lua")),
                "-i", "NONE", "-n", "--noplugin",
            ], env={**os.environ, "REX_COPY_SETTINGS": json.dumps(settings)}).returncode
        finally:
            try:
                restore_source(command, sys.argv[1], len(sys.argv) == 4 and sys.argv[3] == "zoomed")
            except (OSError, ValueError, subprocess.TimeoutExpired):
                pass  # A closed source/server must not prevent closing the viewer.


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
