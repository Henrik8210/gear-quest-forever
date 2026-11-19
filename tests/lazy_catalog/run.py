#!/usr/bin/env python3
"""Stage current data, then compare lazy runtime behavior with v1.2.3.

Requires Python 3.10+ and lupa with its lua51 module. This never syncs to WoW.
The baseline ref must be available locally (git fetch origin tag v1.2.3).
"""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
RUNTIME = ["Data.lua", "DataAdapter.lua", "CustomSpec.lua", "Log.lua",
           "MobDrop.lua", "GearQuestForever.toc"]


def command(*args, env=None):
    subprocess.run(args, cwd=REPO, env=env, check=True)


def check(root, scripts, classes):
    env = dict(os.environ, GQ_LAZY_TEST_ROOT=str(root))
    for script in scripts:
        print(f"Checking {root.name}: {script}", flush=True)
        args = classes if script == "test_release.py" else []
        command(sys.executable, str(HERE / script), *args, env=env)


def run(root, baseline, classes):
    from lupa.lua51 import LuaRuntime

    current = root / "optimized"
    main = current / "GearQuestForever"
    shutil.copytree(REPO / "GearQuest", main)
    command(sys.executable, "scripts/stage-class-addons.py",
            "--dest", str(current), "--main", str(main))
    original = root / "source"
    shutil.copytree(current, original)
    for name in RUNTIME:
        content = subprocess.check_output(
            ["git", "show", f"{baseline}:GearQuest/{name}"], cwd=REPO)
        (original / "GearQuestForever" / name).write_bytes(content)
    (original / "GearQuestForever/Catalog.lua").unlink()

    lua = LuaRuntime()
    compile_lua = lua.eval("function(s,n)local f,e=loadstring(s,n);assert(f,e)end")
    count = 0
    for path in current.rglob("*.lua"):
        compile_lua(path.read_text(encoding="utf-8-sig"), "@" + str(path))
        count += 1
    print(f"Compiled {count} staged Lua files with Lua 5.1", flush=True)
    check(root, ["test_release.py", "test_integration.py", "test_weapons.py",
                 "test_contexts.py", "test_async_lookup.py", "test_maps.py",
                 "test_text_contract.py"], classes)

    # The repo's readable row arrays remain supported for development. Only
    # class files differ here; both runtimes consume the very same item data.
    raw = root / "raw"
    for tree in ["source", "optimized"]:
        shutil.copytree(root / tree, raw / tree)
        for folder in (raw / tree).glob("GearQuestForever_*"):
            for path in folder.glob("Data.*.generated.lua"):
                source = REPO / "GearQuest/_generated" / path.name
                if source.is_file() and folder.name != "GearQuestForever_ItemStats":
                    shutil.copyfile(source, path)
    check(raw, ["test_release.py", "test_integration.py", "test_raw_cursor.py"], classes)
    print("All staged and raw comparisons passed", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", default="v1.2.3")
    parser.add_argument("--classes", nargs="*", default=[])
    parser.add_argument("--output", type=Path,
                        help="Keep staged trees and JSON results in a NEW directory")
    args = parser.parse_args()
    if args.output:
        args.output.mkdir(parents=True, exist_ok=False)
        run(args.output.resolve(), args.baseline, args.classes)
    else:
        with tempfile.TemporaryDirectory(prefix="gq-lazy-tests-") as folder:
            run(Path(folder), args.baseline, args.classes)
