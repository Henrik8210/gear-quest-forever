#!/usr/bin/env python3
"""Upload a packager zip to CurseForge as WoW Forever (not Classic Era / TBC)."""

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

SKIP_TYPES = {517, 67408, 73246, 73713, 77522, 79434, 81212}


def main() -> int:
    token = os.environ.get("CF_API_KEY") or ""
    project = os.environ.get("CF_PROJECT_ID") or "1698950"
    wanted = os.environ.get("CF_GAME_VERSION") or "1.60.1"
    if not token:
        print("CF_API_KEY is not set", file=sys.stderr)
        return 1

    zips = sorted(
        p for p in Path(".release").glob("*.zip") if "nolib" not in p.name.lower()
    )
    if not zips:
        print("No packager zip found in .release/", file=sys.stderr)
        return 1
    zip_path = zips[0]
    print(f"Uploading {zip_path}")

    req = subprocess.run(
        [
            "curl",
            "-sS",
            "-H",
            f"X-Api-Token: {token}",
            "https://wow.curseforge.com/api/game/versions",
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    versions = json.loads(req.stdout)
    matches = [v for v in versions if v.get("name") == wanted]
    if not matches:
        nearby = sorted(
            {
                (v.get("gameVersionTypeID"), v.get("name"))
                for v in versions
                if "1.60" in str(v.get("name", ""))
            }
        )
        print(f"No CurseForge game version named {wanted}", file=sys.stderr)
        print(f"Nearby 1.60* entries: {nearby}", file=sys.stderr)
        return 1

    preferred = [v for v in matches if v.get("gameVersionTypeID") not in SKIP_TYPES]
    chosen = (preferred or matches)[0]
    print(
        f"Using CurseForge version {chosen['name']} "
        f"id={chosen['id']} type={chosen.get('gameVersionTypeID')} "
        f"apiVersion={chosen.get('apiVersion')}"
    )

    changelog = "GearQuest Forever"
    changelog_path = Path("CHANGELOG.md")
    if changelog_path.is_file():
        text = changelog_path.read_text(encoding="utf-8")
        parts = text.split("## ", 2)
        changelog = ("## " + parts[1]).strip() if len(parts) > 1 else text[:4000]

    tag = os.environ.get("GITHUB_REF_NAME") or zip_path.stem
    if tag.lower().startswith("gearquestforever-"):
        tag = tag.split("-", 1)[1]
    if not tag.lower().startswith("v"):
        tag = "v" + tag
    display = tag
    release_type = (os.environ.get("CF_RELEASE_TYPE") or "beta").lower()
    if release_type not in {"alpha", "beta", "release"}:
        release_type = "beta"
    print(f"CurseForge displayName={display} releaseType={release_type}")
    metadata = json.dumps(
        {
            "changelog": changelog,
            "changelogType": "markdown",
            "displayName": display,
            "gameVersions": [int(chosen["id"])],
            "releaseType": release_type,
        }
    )

    # curl -F treats ";" as extra parameters (type=, filename=). Write JSON to a
    # file so changelog punctuation cannot break the multipart field.
    with tempfile.NamedTemporaryFile(
        "w", encoding="utf-8", suffix=".json", delete=False
    ) as fh:
        fh.write(metadata)
        meta_path = fh.name

    try:
        result = subprocess.run(
            [
                "curl",
                "-sS",
                "-w",
                "\n%{http_code}",
                "-X",
                "POST",
                f"https://wow.curseforge.com/api/projects/{project}/upload-file",
                "-H",
                f"X-Api-Token: {token}",
                "-F",
                f"metadata=<{meta_path}",
                "-F",
                f"file=@{zip_path}",
            ],
            check=True,
            capture_output=True,
            text=True,
        )
    finally:
        Path(meta_path).unlink(missing_ok=True)
    body, _, code = result.stdout.rpartition("\n")
    print(body)
    print("HTTP", code)
    return 0 if code.startswith("2") else 1


if __name__ == "__main__":
    raise SystemExit(main())
