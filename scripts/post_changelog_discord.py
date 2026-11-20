#!/usr/bin/env python3
"""Post the current release section from CHANGELOG.md to Discord #changelog.

Requires GearQuest Helper bot token in .cursor/mcp.json (or DISCORD_TOKEN env).

  python scripts/post_changelog_discord.py
  python scripts/post_changelog_discord.py --version 1.2.7
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHANGELOG = ROOT / "CHANGELOG.md"
CHANNEL_ID = "1570179420260532315"
DISCORD_LIMIT = 2000


def token() -> str:
    if os.environ.get("DISCORD_TOKEN"):
        return os.environ["DISCORD_TOKEN"]
    mcp = ROOT / ".cursor" / "mcp.json"
    if mcp.is_file():
        return json.loads(mcp.read_text(encoding="utf-8"))["mcpServers"]["discord"]["env"]["DISCORD_TOKEN"]
    raise SystemExit("Set DISCORD_TOKEN or configure .cursor/mcp.json")


def extract_section(version: str | None) -> str:
    text = CHANGELOG.read_text(encoding="utf-8")
    if version:
        pattern = rf"^## v{re.escape(version.lstrip('v'))}\s*$"
    else:
        pattern = r"^## v[\d.]+\S*\s*$"
    m = re.search(pattern, text, re.MULTILINE)
    if not m:
        raise SystemExit("No matching ## v… section in CHANGELOG.md")
    start = m.start()
    rest = text[m.end() :]
    # CurseForge keeps one ## heading; older releases are ### vX.Y.Z below it.
    n = re.search(r"^### v[\d.]+\S*\s*$", rest, re.MULTILINE)
    if not n:
        n = re.search(r"^## v", rest, re.MULTILINE)
    end = m.end() + n.start() if n else len(text)
    return text[start:end].strip()


def send_chunks(content: str) -> None:
    tok = token()
    chunks: list[str] = []
    while content:
        if len(content) <= DISCORD_LIMIT:
            chunks.append(content)
            break
        cut = content.rfind("\n", 0, DISCORD_LIMIT - 20)
        if cut < DISCORD_LIMIT // 2:
            cut = DISCORD_LIMIT - 20
        chunks.append(content[:cut])
        content = content[cut:].lstrip()

    import time

    for i, part in enumerate(chunks):
        if i > 0:
            time.sleep(1.25)
        body = json.dumps({"content": part}).encode("utf-8")
        req = urllib.request.Request(
            f"https://discord.com/api/v10/channels/{CHANNEL_ID}/messages",
            data=body,
            headers={
                "Authorization": f"Bot {tok}",
                "Content-Type": "application/json",
                "User-Agent": "GearQuestHelper",
            },
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=30) as resp:
            msg = json.loads(resp.read().decode())
            print("posted", msg.get("id"))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", help="Version without v prefix, e.g. 1.2.7")
    args = parser.parse_args()
    section = extract_section(args.version)
    send_chunks(section)
    return 0


if __name__ == "__main__":
    sys.exit(main())