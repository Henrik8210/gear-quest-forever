#!/usr/bin/env python3
"""Every GQ.L sentence in the code has a translation in all eight languages.

The keys are read by running each language file in Lua 5.1 with that locale
selected, so escapes and concatenation match what the client sees. A missing
key falls back to English in game; here it fails the check, because a new
sentence is translated in the same change.

Each language file is also loaded under a different locale and must not add
a key, so a file whose `if GQ.LOCALE ~= "xxXX" then return end` guard went
missing cannot overwrite another language.

Usage: python scripts/ci/check_locales.py
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

from lupa.lua51 import LuaRuntime

REPO = Path(__file__).resolve().parents[2]
ADDON = REPO / "GearQuest"
LOCALES = ["frFR", "deDE", "esES", "ptBR", "ruRU", "koKR", "zhCN", "zhTW"]
PACK_FILE = re.compile(r"^(frFR|deDE|esES|esMX|ptBR|ruRU|koKR|zhCN|zhTW)\.")
KEY_USE = re.compile(
    r"""(?<![\w])L\[\s*("(?:[^"\\\n]|\\.)*"|'(?:[^'\\\n]|\\.)*')\s*\](?!\s*=[^=])"""
)

STUB = """
local function sink()
    return setmetatable({}, {
        __index = function(t, k) local v = sink(); rawset(t, k, v); return v end,
        __call = function(_, first) return first end,
    })
end
function LoadPack(code, name, locale)
    local L = {}
    local GQ = sink()
    -- Sources guard on either name; stage-locale-addons.py rewrites both to
    -- ActiveLocale, so a pack must load when either one matches.
    rawset(GQ, "LOCALE", locale)
    rawset(GQ, "ActiveLocale", locale)
    rawset(GQ, "L", L)
    local f, err = loadstring(code, name)
    if not f then error(err) end
    f("GearQuestForever", GQ)
    return L
end
"""


def code_files() -> list[Path]:
    files = []
    for path in sorted(ADDON.rglob("*.lua")):
        rel = path.relative_to(ADDON).as_posix()
        if rel.startswith("_generated/"):
            continue
        if rel.startswith("Locales/") and PACK_FILE.match(path.name):
            continue
        files.append(path)
    return files


def used_keys(lua) -> dict[str, str]:
    decode = lua.eval("function(lit) return loadstring('return ' .. lit)() end")
    keys: dict[str, str] = {}
    for path in code_files():
        text = path.read_text(encoding="utf-8-sig")
        for match in KEY_USE.finditer(text):
            key = decode(match.group(1))
            if isinstance(key, str):
                line = text.count("\n", 0, match.start()) + 1
                keys.setdefault(key, f"{path.relative_to(REPO).as_posix()}:{line}")
    return keys


def pack_keys(lua, locale: str, as_locale: str) -> set[str]:
    load = lua.globals().LoadPack
    keys: set[str] = set()
    for path in sorted((ADDON / "Locales").glob(f"{locale}*.lua")):
        table = load(path.read_text(encoding="utf-8-sig"), "@" + str(path), as_locale)
        keys.update(k for k in table.keys() if isinstance(k, str))
    return keys


def main(argv: list[str]) -> int:
    lua = LuaRuntime()
    lua.execute(STUB)
    used = used_keys(lua)
    failures = 0

    for locale in LOCALES:
        other = "enUS"
        leaked = pack_keys(lua, locale, other)
        if leaked:
            print(f"FAIL {locale}: {len(leaked)} keys load while {other} is selected "
                  f"(missing `if GQ.LOCALE ~= \"{locale}\" then return end` guard?)")
            failures += 1

    for locale in LOCALES:
        have = pack_keys(lua, locale, locale)
        for key in sorted(k for k in used if k not in have):
            print(f"FAIL {locale}: missing translation for {key!r} (used at {used[key]})")
            failures += 1

    print(f"Checked {len(used)} GQ.L keys in {len(LOCALES)} languages, {failures} failures")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
