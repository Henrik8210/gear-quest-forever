#!/usr/bin/env python3
"""Release metadata agrees with itself.

- `## Version:` in the toc equals `GQ.VERSION` in Core.lua.
- `## X-Curse-Project-ID:` and release.yml are the Forever project (1698950),
  never TBC GearQuest (1669225).
- CHANGELOG.md has exactly one `## ` heading, the first heading in the file,
  and it names that version. Older versions are `### `.
- RELEASE.md names that version as the current release.
- Every file the toc lists exists.
- With --tag vX.Y.Z (the release workflow passes the pushed tag), the tag is
  that version.

Usage: python scripts/ci/check_release.py [--tag v1.2.3]
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
TOC = REPO / "GearQuest" / "GearQuestForever.toc"
FOREVER_PROJECT = "1698950"
TBC_PROJECT = "1669225"


def toc_field(text: str, name: str) -> str | None:
    match = re.search(rf"^## {re.escape(name)}:\s*(.+?)\s*$", text, re.M)
    return match.group(1) if match else None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tag")
    args = parser.parse_args()
    errors: list[str] = []

    toc = TOC.read_text(encoding="utf-8-sig")
    version = toc_field(toc, "Version")
    core = (REPO / "GearQuest" / "Core.lua").read_text(encoding="utf-8-sig")
    code = re.search(r'^GQ\.VERSION\s*=\s*"([^"]+)"', core, re.M)
    if not version:
        errors.append("toc has no ## Version: line")
    if not code:
        errors.append('Core.lua has no GQ.VERSION = "..." line')
    elif version and code.group(1) != version:
        errors.append(f"toc version {version} != GQ.VERSION {code.group(1)}")

    project = toc_field(toc, "X-Curse-Project-ID")
    if project != FOREVER_PROJECT:
        errors.append(f"toc X-Curse-Project-ID is {project}, expected {FOREVER_PROJECT}")
    workflow = (REPO / ".github" / "workflows" / "release.yml").read_text(encoding="utf-8")
    if f'CF_PROJECT_ID: "{FOREVER_PROJECT}"' not in workflow:
        errors.append(f"release.yml does not upload to CF_PROJECT_ID {FOREVER_PROJECT}")
    for path in [TOC, REPO / ".github" / "workflows" / "release.yml"]:
        if TBC_PROJECT in path.read_text(encoding="utf-8-sig"):
            errors.append(f"{path.relative_to(REPO)} mentions the TBC project {TBC_PROJECT}")

    changelog = (REPO / "CHANGELOG.md").read_text(encoding="utf-8-sig").splitlines()
    level2 = [line for line in changelog if line.startswith("## ")]
    headings = [line for line in changelog if re.match(r"^#{1,3} ", line) and not line.startswith("# ")]
    if len(level2) != 1:
        errors.append(f"CHANGELOG.md has {len(level2)} '## ' headings, expected exactly 1")
    elif headings and headings[0] != level2[0]:
        errors.append("CHANGELOG.md: the '## ' heading must come before every '### ' heading")
    if level2 and version and not re.match(rf"^## v{re.escape(version)}\b", level2[0]):
        errors.append(f"CHANGELOG.md top heading is {level2[0]!r}, expected '## v{version}'")

    release_md = (REPO / "RELEASE.md").read_text(encoding="utf-8-sig")
    if version and f"the current release is `{version}`" not in release_md:
        errors.append(f"RELEASE.md does not say the current release is `{version}`")

    for line in toc.splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            if not (TOC.parent / line.replace("\\", "/")).is_file():
                errors.append(f"toc lists {line}, which does not exist")

    if args.tag and version and args.tag.lstrip("v") != version:
        errors.append(f"tag {args.tag} does not match toc version {version}")

    for error in errors:
        print(f"FAIL {error}")
    print(f"Release metadata for {version}: {len(errors)} problems")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
