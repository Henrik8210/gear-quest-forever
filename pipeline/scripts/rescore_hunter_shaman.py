"""Re-score Forever-model classes only (jackpot + survivability + endurance)."""
import os
import shutil
import subprocess
import sys
from pathlib import Path

from gq_paths import OUT, ADDON_GEN
from reemit_all import run as emit_class

ROOT = Path(__file__).resolve().parent
PY = sys.executable

# (class, out json, emit kind, guides file, lua files to copy)
JOBS = [
    ("HUNTER", "hunter.json", "early", "guides_hunter.json",
     ("Data.Hunter.generated.lua", "Data.Hunter.Early.1to9.generated.lua")),
    ("SHAMAN", "shaman.json", "early", "guides_shaman.json",
     ("Data.Shaman.generated.lua", "Data.Shaman.Early.1to9.generated.lua")),
    ("PALADIN", "paladin.json", "horde", "guides.json",
     ("Data.Paladin.generated.lua", "Data.Paladin.Horde.1to9.generated.lua")),
    ("WARRIOR", "warrior.json", "horde", "guides_warrior.json",
     ("Data.Warrior.generated.lua", "Data.Warrior.Horde.1to9.generated.lua")),
    ("DRUID", "druid.json", "early", "guides_druid.json",
     ("Data.Druid.generated.lua", "Data.Druid.Early.1to9.generated.lua")),
    ("ROGUE", "rogue.json", "early", "guides_rogue.json",
     ("Data.Rogue.generated.lua", "Data.Rogue.Early.1to9.generated.lua")),
    ("PRIEST", "priest.json", "early", "guides_priest.json",
     ("Data.Priest.generated.lua", "Data.Priest.Early.1to9.generated.lua")),
    ("MAGE", "mage.json", "early", "guides_mage.json",
     ("Data.Mage.generated.lua", "Data.Mage.Early.1to9.generated.lua")),
    ("WARLOCK", "warlock.json", "early", "guides_warlock.json",
     ("Data.Warlock.generated.lua", "Data.Warlock.Early.1to9.generated.lua")),
]


def score(cls, out_name, guides):
    env = os.environ.copy()
    env["GQ_CLASS"] = cls
    env["GQ_OUT"] = out_name
    env["GQ_GUIDES"] = guides
    env["GQ_NO_GUIDES"] = "1"
    print(f"== {cls} score ==")
    subprocess.check_call([PY, str(ROOT / "score.py")], cwd=str(ROOT), env=env)


def main():
    only = [a.upper() for a in sys.argv[1:]]
    jobs = [j for j in JOBS if not only or j[0] in only]
    copied = []
    for cls, out_name, kind, guides, lua_names in jobs:
        score(cls, out_name, guides)
        emit_class(cls, out_name, kind)
        dest = Path(ADDON_GEN)
        dest.mkdir(parents=True, exist_ok=True)
        for name in lua_names:
            src = Path(OUT) / name
            shutil.copy2(src, dest / name)
            copied.append(name)
            print("copied", name)
    print("done:", ", ".join(copied))


if __name__ == "__main__":
    main()
