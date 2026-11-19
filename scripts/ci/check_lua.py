#!/usr/bin/env python3
"""Compile every Lua file with the Lua 5.1 compiler WoW uses (via lupa).

A file that does not compile stops the whole addon from loading, so this runs
on the source tree and on the staged class and language addons. Files must
also be valid UTF-8, or the client shows boxes or refuses the file. Every
.toc under the given folders lists only files that exist; the client skips a
missing one without an error.

Usage: python scripts/ci/check_lua.py GearQuest [.ci-stage ...]
"""
from __future__ import annotations

import sys
from pathlib import Path

from lupa.lua51 import LuaRuntime


def lua_files(roots: list[Path]) -> list[Path]:
    files: list[Path] = []
    for root in roots:
        if root.is_file():
            files.append(root)
        else:
            files.extend(sorted(root.rglob("*.lua")))
    return files


def main(argv: list[str]) -> int:
    roots = [Path(a) for a in argv] or [Path("GearQuest")]
    lua = LuaRuntime()
    compile_lua = lua.eval(
        "function(code, name) local f, err = loadstring(code, name) return err end"
    )
    failures = 0
    files = lua_files(roots)
    for path in files:
        raw = path.read_bytes()
        try:
            text = raw.decode("utf-8-sig")
        except UnicodeDecodeError as exc:
            print(f"FAIL {path}: not valid UTF-8 ({exc})")
            failures += 1
            continue
        err = compile_lua(text, "@" + str(path))
        if err:
            print(f"FAIL {err}")
            failures += 1
    print(f"Compiled {len(files)} Lua files with Lua 5.1, {failures} failed")

    tocs = [t for root in roots if root.is_dir() for t in sorted(root.rglob("*.toc"))]
    missing = 0
    for toc in tocs:
        for line in toc.read_text(encoding="utf-8-sig").splitlines():
            entry = line.strip()
            if entry and not entry.startswith("#") and not (toc.parent / entry.replace("\\", "/")).is_file():
                print(f"FAIL {toc}: lists {entry}, which does not exist")
                missing += 1
    print(f"Checked {len(tocs)} toc files, {missing} missing entries")
    return 1 if failures or missing else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
