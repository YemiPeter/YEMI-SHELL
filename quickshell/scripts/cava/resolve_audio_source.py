#!/usr/bin/env python3
"""Pick a cava [input] source that follows music, not VoIP/system mix.

Prefers PipeWire/Pulse streams tagged media.role=music, then streams whose
client binary matches the active MPRIS desktop entry. Falls back to the
default sink monitor when nothing better exists.
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass


EXCLUDED_APP_NAMES = (
    "discord",
    "vesktop",
    "webRTC",
    "webrtc",
    "teams",
    "zoom",
    "slack",
    "telegram-desktop",
    "element",
    "speech-dispatcher",
    "speech-dispatcher-dummy",
    "steam voice",
)

EXCLUDED_BINARIES = (
    "discord",
    "vesktop",
    "teams",
    "zoom",
    "slack",
    "sd_dummy",
)

EXCLUDED_MEDIA_ROLES = (
    "communication",
    "phone",
    "notification",
    "alert",
    "game",
    "production",
)

DESKTOP_ENTRY_BINARIES: dict[str, tuple[str, ...]] = {
    "spotify": ("spotify",),
    "mpv": ("mpv",),
    "vlc": ("vlc",),
    "firefox": ("firefox", "zen"),
    "chromium": ("chromium", "chrome", "brave", "google-chrome", "google-chrome-stable"),
    "chrome": ("chrome", "google-chrome", "google-chrome-stable", "brave"),
    "brave": ("brave",),
    "org.chromium.Chromium": ("chromium", "chrome"),
    "com.google.Chrome": ("chrome", "google-chrome", "google-chrome-stable"),
    "org.mozilla.firefox": ("firefox",),
    "strawberry": ("strawberry",),
    "audacious": ("audacious",),
    "deadbeef": ("deadbeef",),
    "rhythmbox": ("rhythmbox",),
    "clementine": ("clementine",),
    "haruna": ("haruna",),
    "com.github.thitz.ekai.Mooz": ("mooz",),
}


@dataclass
class SinkInput:
    index: int
    client_id: str
    node_name: str
    media_role: str
    app_name: str
    binary_name: str


def run(cmd: list[str]) -> str:
    """Run a command and return stripped stdout, or empty string on failure."""
    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True, timeout=5
        )
        return result.stdout.strip()
    except Exception:
        return ""


def parse_sink_inputs(desktop_entry: str) -> list[SinkInput]:
    """Parse pactl output to find sink inputs matching the desktop entry."""
    output = run(["pactl", "list", "sink-inputs"])
    if not output:
        return []

    sinks = []
    current: SinkInput | None = None

    for line in output.splitlines():
        line = line.strip()

        if re.match(r"^Sink Input #", line):
            if current is not None:
                sinks.append(current)
            current = SinkInput(
                index=0,
                client_id="",
                node_name="",
                media_role="",
                app_name="",
                binary_name="",
            )
        elif current is None:
            continue
        elif line.startswith("Index:"):
            try:
                current.index = int(line.split(":")[1].strip())
            except ValueError:
                pass
        elif line.startswith("Driver:"):
            pass
        elif line.startswith("Client:"):
            try:
                current.client_id = line.split(":")[1].strip()
            except IndexError:
                pass
        elif line.startswith("Media Name:"):
            current.media_role = line.split(":", 1)[1].strip().lower()
        elif line.startswith("application.name:"):
            current.app_name = line.split(":", 1)[1].strip()
        elif line.startswith("application.process.binary:"):
            current.binary_name = line.split(":", 1)[1].strip()
        elif line.startswith("media.class:"):
            current.node_name = line.split(":", 1)[1].strip()

    if current is not None:
        sinks.append(current)

    return sinks


def score_sink(sink: SinkInput, target_binaries: tuple[str, ...]) -> int | None:
    """Score a sink input. Returns score or None if should be excluded."""
    # Exclude VoIP/communication apps
    if sink.binary_name.lower() in EXCLUDED_BINARIES:
        return None
    if sink.app_name.lower() in EXCLUDED_APP_NAMES:
        return None
    if sink.media_role and sink.media_role in EXCLUDED_MEDIA_ROLES:
        return None

    score = 0

    # Exact binary match — highest priority
    if sink.binary_name.lower() in target_binaries:
        score = 100

    # Media role music
    if sink.media_role == "music":
        score = max(score, 80)

    # Media role video
    if sink.media_role == "video":
        score = max(score, 50)

    return score if score > 0 else None


def resolve(desktop_entry: str) -> str | None:
    """Resolve the best monitor source for the given desktop entry."""
    if not desktop_entry:
        return None

    target_binaries = DESKTOP_ENTRY_BINARIES.get(desktop_entry, (desktop_entry,))
    sinks = parse_sink_inputs(desktop_entry)

    best: SinkInput | None = None
    best_score = 0

    for sink in sinks:
        s = score_sink(sink, target_binaries)
        if s is not None and s > best_score:
            best = sink
            best_score = s

    if best is not None and best.node_name:
        return best.node_name

    return None


def main():
    parser = argparse.ArgumentParser(description="Resolve cava audio source")
    parser.add_argument(
        "--desktop-entry",
        required=False,
        default="",
        help="Desktop entry of the active MPRIS player",
    )
    args = parser.parse_args()

    result = resolve(args.desktop_entry)
    if result:
        print(result)
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
