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
