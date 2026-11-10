#!/usr/bin/env python3
"""Install one GearQuest Forever language addon.

English stays in the main addon. French, German, and the other client
languages live in GearQuest/Locales/ and are copied into
GearQuestForever_Languages. That addon is LoadOnDemand and is parsed
only when a language other than English is selected.

Every new player-facing string is an English GQ.L key. Add the same key
to each language file in that folder in the same change. A missing key
falls back to English. A file that is not on disk yet is read from the
local git ref `more-locales`. Quest story paragraphs live in `*.lore.lua`,
keyed by the exact English paragraph. The old quest-id pairing inside
`*.quests.lua` is still dropped on the way out.
"""

from __future__ import annotations

import argparse
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOCALES = ROOT / "GearQuest" / "Locales"
REF = "more-locales"
HEADER = "local GQ = _G.GearQuest\nif not GQ then return end\n"
GUARD = re.compile(
    r'if GQ\.(?:LOCALE|ActiveLocale) ~= "[^"]+"'
    r'(?: and GQ\.(?:LOCALE|ActiveLocale) ~= "[^"]+")* then'
)
KEEP = {"Locale.lua", "Zones.lua"}

# (filename, origin, locale ids that file should load for).
# None keeps the file with no locale guard (the shared phrase helper).
# Rules.lua is first so the other languages can call AddPhraseRules.
FILES: list[tuple[str, str, list[str] | None]] = [
    ("Rules.lua", "git", None),
    ("frFR.lua", "disk", ["frFR"]),
    ("frFR.rules.lua", "disk", ["frFR"]),
    ("frFR.sentences.lua", "disk", ["frFR"]),
    ("frFR.names.lua", "disk", ["frFR"]),
    ("frFR.db2.lua", "disk", ["frFR"]),
    ("frFR.quests.lua", "disk", ["frFR"]),
    ("frFR.lore.lua", "disk", ["frFR"]),
    ("deDE.lua", "git", ["deDE"]),
    ("deDE.rules.lua", "git", ["deDE"]),
    ("deDE.sentences.lua", "git", ["deDE"]),
    ("deDE.names.lua", "git", ["deDE"]),
    ("deDE.db2.lua", "git", ["deDE"]),
    ("deDE.quests.lua", "git", ["deDE"]),
    ("deDE.lore.lua", "disk", ["deDE"]),
    ("esES.lua", "git", ["esES", "esMX"]),
    ("esES.rules.lua", "git", ["esES", "esMX"]),
    ("esES.sentences.lua", "disk", ["esES", "esMX"]),
    ("esES.names.lua", "git", ["esES"]),
    ("esES.db2.lua", "git", ["esES"]),
    ("esES.quests.lua", "git", ["esES"]),
    ("esES.lore.lua", "disk", ["esES", "esMX"]),
    ("esMX.names.lua", "git", ["esMX"]),
    ("esMX.db2.lua", "git", ["esMX"]),
    ("esMX.quests.lua", "git", ["esMX"]),
    ("ptBR.lua", "git", ["ptBR"]),
    ("ptBR.rules.lua", "git", ["ptBR"]),
    ("ptBR.sentences.lua", "disk", ["ptBR"]),
    ("ptBR.names.lua", "git", ["ptBR"]),
    ("ptBR.db2.lua", "git", ["ptBR"]),
    ("ptBR.quests.lua", "git", ["ptBR"]),
    ("ptBR.lore.lua", "disk", ["ptBR"]),
    ("ruRU.lua", "git", ["ruRU"]),
    ("ruRU.rules.lua", "git", ["ruRU"]),
    ("ruRU.sentences.lua", "disk", ["ruRU"]),
    ("ruRU.names.lua", "git", ["ruRU"]),
    ("ruRU.db2.lua", "git", ["ruRU"]),
    ("ruRU.quests.lua", "git", ["ruRU"]),
    ("ruRU.lore.lua", "disk", ["ruRU"]),
    ("koKR.lua", "git", ["koKR"]),
    ("koKR.rules.lua", "git", ["koKR"]),
    ("koKR.sentences.lua", "disk", ["koKR"]),
    ("koKR.names.lua", "git", ["koKR"]),
    ("koKR.db2.lua", "git", ["koKR"]),
    ("koKR.quests.lua", "git", ["koKR"]),
    ("koKR.lore.lua", "disk", ["koKR"]),
    ("zhCN.lua", "git", ["zhCN"]),
    ("zhCN.rules.lua", "git", ["zhCN"]),
    ("zhCN.sentences.lua", "disk", ["zhCN"]),
    ("zhCN.names.lua", "git", ["zhCN"]),
    ("zhCN.db2.lua", "git", ["zhCN"]),
    ("zhCN.quests.lua", "git", ["zhCN"]),
    ("zhCN.lore.lua", "disk", ["zhCN"]),
    ("zhTW.lua", "git", ["zhTW"]),
    ("zhTW.rules.lua", "git", ["zhTW"]),
    ("zhTW.sentences.lua", "disk", ["zhTW"]),
    ("zhTW.names.lua", "git", ["zhTW"]),
    ("zhTW.db2.lua", "git", ["zhTW"]),
    ("zhTW.quests.lua", "git", ["zhTW"]),
    ("zhTW.lore.lua", "disk", ["zhTW"]),
]
ADDON = "GearQuestForever_Languages"


def addon_version() -> str:
    toc = ROOT / "GearQuest" / "GearQuestForever.toc"
    for line in toc.read_text(encoding="utf-8").splitlines():
        if line.startswith("## Version:"):
            return line.split(":", 1)[1].strip()
    raise SystemExit("GearQuestForever.toc has no ## Version")


def read_source(name: str, origin: str) -> str:
    path = LOCALES / name
    if path.is_file():
        return path.read_text(encoding="utf-8")
    if origin == "disk":
        raise SystemExit(f"missing {path}")
    rel = f"GearQuest/Locales/{name}"
    try:
        data = subprocess.check_output(
            ["git", "show", f"{REF}:{rel}"],
            cwd=ROOT,
        )
    except subprocess.CalledProcessError as exc:
        raise SystemExit(
            f"git show {REF}:{rel} failed. The other languages live on the local ref {REF}."
        ) from exc
    return data.decode("utf-8")


def adapt(name: str, text: str, locales: list[str] | None) -> str:
    if not text.startswith("local _, GQ = ..."):
        raise SystemExit(f"{name} is missing the addon header")
    text = HEADER + text.split("\n", 1)[1]
    if locales:
        guard = " and ".join(f'GQ.ActiveLocale ~= "{locale}"' for locale in locales)
        updated, count = GUARD.subn(f"if {guard} then", text, count=1)
        if count != 1:
            raise SystemExit(f"{name} has no locale guard")
        text = updated
    return text


def strip_lore(text: str) -> str:
    marker = "local objectives = GQ.LocaleObjectives"
    idx = text.find(marker)
    if idx < 0:
        return text
    guard_end = None
    for i, line in enumerate(text.splitlines(keepends=True)):
        if line.strip() == "end":
            guard_end = i
            break
    if guard_end is None:
        return text
    lines = text.splitlines(keepends=True)
    return "".join(lines[: guard_end + 1]) + "\n" + text[idx:]


def write_toc(folder: Path, files: list[str]) -> None:
    lines = [
        "## Interface: 16001",
        "## Title: GearQuest Forever: Languages",
        "## Notes: French, German, and the other client languages. GearQuest loads this only when a language other than English is selected. Disable it to keep GearQuest in English.",
        "## Author: Henrik8210",
        f"## Version: {addon_version()}",
        "## IconTexture: Interface\\Icons\\INV_Misc_Book_09",
        "## LoadOnDemand: 1",
        "## OptionalDeps: GearQuestForever",
        "## DefaultState: enabled",
        "",
        *files,
        "",
    ]
    (folder / f"{folder.name}.toc").write_text("\n".join(lines), encoding="utf-8", newline="\n")


def clear_main_locale_files(main_addon: Path) -> None:
    folder = main_addon / "Locales"
    if not folder.is_dir():
        return
    for path in folder.glob("*.lua"):
        if path.name not in KEEP:
            path.unlink()
            print(f"removed from main addon: Locales/{path.name}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dest", required=True, help="AddOns directory")
    parser.add_argument("--main", required=True, help="Staged GearQuestForever folder")
    args = parser.parse_args()
    dest = Path(args.dest)
    clear_main_locale_files(Path(args.main))
    folder = dest / ADDON
    folder.mkdir(parents=True, exist_ok=True)
    names: list[str] = []
    for name, origin, locales in FILES:
        text = read_source(name, origin)
        text = adapt(name, text, locales)
        if name.endswith(".quests.lua"):
            text = strip_lore(text)
        (folder / name).write_text(text, encoding="utf-8", newline="\n")
        names.append(name)
        print(f"  {name}")
    write_toc(folder, names)
    print(f"{folder.name}: {len(names)} files")


if __name__ == "__main__":
    main()
