#!/usr/bin/env python3
"""Bump the app version for a release.

Reads the current `version: X.Y.Z+B` line from pubspec.yaml, bumps X/Y/Z per
the given bump type (the build number B always increments by 1), and writes
the new version back to pubspec.yaml and snap/snapcraft.yaml (build number is
only tracked in pubspec.yaml, per its own comment).

Usage: python3 scripts/bump_version.py <patch|minor|major>
Prints the new version (without the build number) to stdout, e.g. "2.10.0".
"""
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PUBSPEC = REPO / "pubspec.yaml"
SNAPCRAFT = REPO / "snap/snapcraft.yaml"

VERSION_RE = re.compile(r"^version: (\d+)\.(\d+)\.(\d+)\+(\d+)$", re.MULTILINE)


def bump(major, minor, patch, kind):
    if kind == "major":
        return major + 1, 0, 0
    if kind == "minor":
        return major, minor + 1, 0
    if kind == "patch":
        return major, minor, patch + 1
    raise ValueError(f"unknown bump kind: {kind}")


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in ("patch", "minor", "major"):
        print("Usage: bump_version.py <patch|minor|major>", file=sys.stderr)
        sys.exit(1)
    kind = sys.argv[1]

    pubspec_text = PUBSPEC.read_text()
    match = VERSION_RE.search(pubspec_text)
    if not match:
        print("Could not find a 'version: X.Y.Z+B' line in pubspec.yaml", file=sys.stderr)
        sys.exit(1)

    major, minor, patch, build = (int(g) for g in match.groups())
    new_major, new_minor, new_patch = bump(major, minor, patch, kind)
    new_build = build + 1
    new_version = f"{new_major}.{new_minor}.{new_patch}"
    new_line = f"version: {new_version}+{new_build}"

    PUBSPEC.write_text(
        pubspec_text[: match.start()] + new_line + pubspec_text[match.end() :]
    )

    snapcraft_text = SNAPCRAFT.read_text()
    snapcraft_text = re.sub(
        r"^version: \d+\.\d+\.\d+$",
        f"version: {new_version}",
        snapcraft_text,
        count=1,
        flags=re.MULTILINE,
    )
    SNAPCRAFT.write_text(snapcraft_text)

    print(new_version)


if __name__ == "__main__":
    main()
