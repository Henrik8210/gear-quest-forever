"""Score every class, then re-emit and copy Lua into GearQuest/_generated/."""
import os
import subprocess
import sys
from pathlib import Path

from reemit_all import CLASSES, copy_generated, run as emit_class

ROOT = Path(__file__).resolve().parent
PY = sys.executable

GUIDES = {
    "PALADIN": "guides.json",
    "WARRIOR": "guides_warrior.json",
    "HUNTER": "guides_hunter.json",
    "DRUID": "guides_druid.json",
    "SHAMAN": "guides_shaman.json",
    "ROGUE": "guides_rogue.json",
    "PRIEST": "guides_priest.json",
    "WARLOCK": "guides_warlock.json",
    "MAGE": "guides_mage.json",
}


def score(cls, out_name):
    env = os.environ.copy()
    env["GQ_CLASS"] = cls
    env["GQ_OUT"] = out_name
    env["GQ_GUIDES"] = GUIDES[cls]
    print(f"== {cls} score ({GUIDES[cls]}) ==")
    subprocess.check_call([PY, str(ROOT / "score.py")], cwd=str(ROOT), env=env)


def main():
    for cls, out_name, kind in CLASSES:
        score(cls, out_name)
        emit_class(cls, out_name, kind)
    copy_generated()


if __name__ == "__main__":
    main()
