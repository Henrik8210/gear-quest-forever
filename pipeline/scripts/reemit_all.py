"""Re-emit generated Lua for every class from existing scored JSON."""
import os
import shutil
import subprocess
import sys
from pathlib import Path

from gq_paths import OUT, ADDON_GEN

ROOT = Path(__file__).resolve().parent
PY = sys.executable

CLASSES = [
    ("PALADIN", "paladin.json", "horde"),
    ("WARRIOR", "warrior.json", "horde"),
    ("HUNTER", "hunter.json", "early"),
    ("DRUID", "druid.json", "early"),
    ("SHAMAN", "shaman.json", "early"),
    ("ROGUE", "rogue.json", "early"),
    ("PRIEST", "priest.json", "early"),
    ("WARLOCK", "warlock.json", "early"),
    ("MAGE", "mage.json", "early"),
]


def run(cls, out_name, kind):
    env = os.environ.copy()
    env["GQ_CLASS"] = cls
    env["GQ_OUT"] = out_name
    print(f"== {cls} payload ==")
    subprocess.check_call([PY, str(ROOT / "payload.py")], cwd=str(ROOT), env=env)
    if kind == "horde":
        print(f"== {cls} horde 1-9 ==")
        subprocess.check_call([PY, str(ROOT / "emit_horde19.py")], cwd=str(ROOT), env=env)
    else:
        env["GQ_FACTIONS"] = "Alliance,Horde"
        print(f"== {cls} early 1-9 ==")
        subprocess.check_call([PY, str(ROOT / "emit_early.py")], cwd=str(ROOT), env=env)


def copy_generated():
    dest = Path(ADDON_GEN)
    dest.mkdir(parents=True, exist_ok=True)
    for path in Path(OUT).glob("Data.*.generated.lua"):
        shutil.copy2(path, dest / path.name)
        print("copied", path.name)


def main():
    for cls, out_name, kind in CLASSES:
        run(cls, out_name, kind)
    copy_generated()


if __name__ == "__main__":
    main()
