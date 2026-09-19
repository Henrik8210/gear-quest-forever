"""Repo-relative paths for the BiS pipeline.

Not part of the CurseForge zip. Players never run this.
Set GQ_ROOT to override (defaults to the `pipeline/` folder).
"""
import os

ROOT = os.environ.get("GQ_ROOT") or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPO = os.path.dirname(ROOT)
DATA = os.path.join(ROOT, "data")
GUIDES_DIR = os.path.join(ROOT, "guides")
OUT = os.path.join(ROOT, "out")
ADDON_GEN = os.path.join(REPO, "GearQuest", "_generated")
G = DATA + os.sep

os.makedirs(OUT, exist_ok=True)

def scored(name):
    """JSON written by score.py (pipeline/out/), not the input tables."""
    return os.path.join(OUT, name)

def forever_missing_ids():
    """Item ids Wowhead Forever 404'd. Those cannot be a hunt target."""
    import re
    path = os.path.join(ADDON_GEN, "Data.ForeverAudit.generated.lua")
    alt = os.path.join(os.path.dirname(REPO), "GearQuest", "GearQuest", "_generated",
                       "Data.ForeverAudit.generated.lua")
    for candidate in (path, alt):
        if os.path.exists(candidate):
            text = open(candidate, encoding="utf-8").read()
            return {int(m.group(1)) for m in re.finditer(r'\[(\d+)\]=\{status="missing"', text)}
    return set()
