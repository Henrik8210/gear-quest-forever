#!/usr/bin/env python3
"""A pull request does not change protected files by accident.

- Weights stay until a retune is asked for. A PR that changes
  pipeline/data/weights.json, the generated weight tables, or the leveling
  weights_at_level() in score.py needs the `weights-change`
  label.
- notebook/seenItems/ is retired. No PR grows, shrinks, or edits it.

Labels come from GQ_PR_LABELS (comma separated), which the CI workflow fills
from the pull request.

Usage: python scripts/ci/check_protected.py --base origin/main
"""
from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys

WEIGHT_FILES = [
    "pipeline/data/weights.json",
    "GearQuest/_generated/ScoringWeights.generated.lua",
    "GearQuest/_generated/StatWeights.generated.lua",
]
WEIGHT_PATTERN = re.compile(r"^GearQuest/_generated/[A-Z]+\.weights\.json$")
SCORE_PY = "pipeline/scripts/score.py"
LABEL = "weights-change"


def git(*args: str) -> str:
    return subprocess.run(["git", *args], check=True, capture_output=True, text=True,
                          encoding="utf-8").stdout


def leveling_block(text: str) -> str:
    """weights_at_level(), which must keep returning the sheet row."""
    start = text.find("def weights_at_level")
    if start < 0:
        return ""
    end = text.find("\ndef ", start + 1)
    return text[start:end] if end > 0 else text[start:]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", default="origin/main")
    args = parser.parse_args()
    labels = {l.strip() for l in os.environ.get("GQ_PR_LABELS", "").split(",") if l.strip()}
    merge_base = git("merge-base", args.base, "HEAD").strip()
    changed = [p for p in git("diff", "--name-only", merge_base, "HEAD").splitlines() if p]
    errors: list[str] = []

    weights = [p for p in changed if p in WEIGHT_FILES or WEIGHT_PATTERN.match(p)]
    if SCORE_PY in changed:
        try:
            before = git("show", f"{merge_base}:{SCORE_PY}")
        except subprocess.CalledProcessError:
            before = ""
        after = open(SCORE_PY, encoding="utf-8").read()
        if leveling_block(before) != leveling_block(after):
            weights.append(f"{SCORE_PY} (weights_at_level)")
    if weights and LABEL not in labels:
        errors.append(
            "weights changed without the `weights-change` label: " + ", ".join(weights)
            + ". Weights stay until a retune is asked for; add the label if this PR is that retune.")

    notebook = [p for p in changed if p.startswith("notebook/seenItems/")]
    if notebook:
        errors.append(f"notebook/seenItems/ is retired and must not change ({len(notebook)} files)")

    for error in errors:
        print(f"FAIL {error}")
    print(f"Checked {len(changed)} changed files against {args.base}, {len(errors)} problems"
          + (f" (labels: {', '.join(sorted(labels))})" if labels else ""))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
