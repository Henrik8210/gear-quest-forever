#!/usr/bin/env python3
"""Install per-class GearQuest Forever hunt addons next to the main addon.

The repo keeps every class file under GearQuest/_generated. At login only the
player's class should be parsed. This copies each class into
GearQuestForever_<CLASS> and moves that class's Wowhead tooltip text out of
the main foreverAudit into AuditTips.lua, which loads with the class.

The staged class files carry packed pick rows (stage_pack.py), so the game
expands only the faction on screen. Item stats for custom specs go into
GearQuestForever_ItemStats, which loads the first time a custom spec is
scored. The staged coordinate file shares repeated spots. The repo files stay
as they are.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path

import stage_pack

ROOT = Path(__file__).resolve().parents[1]
GENERATED = ROOT / "GearQuest" / "_generated"
AUDIT_NAME = "Data.ForeverAudit.generated.lua"
ITEM_STATS_NAME = "Data.ItemStats.generated.lua"
ITEM_STATS_ADDON = "GearQuestForever_ItemStats"
COORDINATES_NAME = "Data.Coordinates.generated.lua"

CLASSES = {
    "PALADIN": (
        "Paladin",
        ["Data.Paladin.generated.lua", "Data.Paladin.Early.1to9.generated.lua"],
    ),
    "WARRIOR": (
        "Warrior",
        ["Data.Warrior.generated.lua", "Data.Warrior.Early.1to9.generated.lua"],
    ),
    "HUNTER": (
        "Hunter",
        ["Data.Hunter.generated.lua", "Data.Hunter.Early.1to9.generated.lua"],
    ),
    "DRUID": (
        "Druid",
        ["Data.Druid.generated.lua", "Data.Druid.Early.1to9.generated.lua"],
    ),
    "SHAMAN": (
        "Shaman",
        ["Data.Shaman.generated.lua", "Data.Shaman.Early.1to9.generated.lua"],
    ),
    "ROGUE": (
        "Rogue",
        ["Data.Rogue.generated.lua", "Data.Rogue.Early.1to9.generated.lua"],
    ),
    "PRIEST": (
        "Priest",
        ["Data.Priest.generated.lua", "Data.Priest.Early.1to9.generated.lua"],
    ),
    "WARLOCK": (
        "Warlock",
        ["Data.Warlock.generated.lua", "Data.Warlock.Early.1to9.generated.lua"],
    ),
    "MAGE": (
        "Mage",
        ["Data.Mage.generated.lua", "Data.Mage.Early.1to9.generated.lua"],
    ),
}

HEADER_OLD = "local _, GQ = ...\n"
HEADER_NEW = (
    "local GQ = _G.GearQuest\n"
    "if not GQ then\n"
    '    error("GearQuest Forever class data loaded without the main addon")\n'
    "end\n"
)

FACT_ID = re.compile(r"^\s*\[(\d+)\]=\{")
ROW_ID = re.compile(r"^\s*\{(\d+),")


def lua_str(text: str) -> str:
    out = (
        text.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\r", " ")
        .replace("\n", "\\n")
    )
    return '"' + out + '"'


def read_lua_string(src: str, quote_at: int) -> tuple[str, int]:
    if src[quote_at] != '"':
        raise ValueError("expected quote")
    i = quote_at + 1
    chars: list[str] = []
    while i < len(src):
        c = src[i]
        if c == "\\":
            nxt = src[i + 1]
            chars.append({"n": "\n", "r": "\r", "t": "\t", "\\": "\\", '"': '"'}.get(nxt, nxt))
            i += 2
            continue
        if c == '"':
            return "".join(chars), i + 1
        chars.append(c)
        i += 1
    raise ValueError("unterminated lua string")


def strip_tip(line: str) -> tuple[str, str | None]:
    i = 0
    n = len(line)
    in_str = False
    esc = False
    while i < n:
        c = line[i]
        if in_str:
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True
            i += 1
            continue
        if line.startswith("tip=", i) and i + 4 < n and line[i + 4] == '"':
            tip, end = read_lua_string(line, i + 4)
            start = i - 1 if i > 0 and line[i - 1] == "," else i
            return line[:start] + line[end:], tip
        i += 1
    return line, None


def item_ids(path: Path) -> set[int]:
    ids: set[int] = set()
    # Class files are not all valid UTF-8. Ids are ASCII either way.
    with path.open(encoding="latin-1") as handle:
        for line in handle:
            fact = FACT_ID.match(line)
            if fact:
                ids.add(int(fact.group(1)))
                continue
            row = ROW_ID.match(line)
            if row:
                ids.add(int(row.group(1)))
    return ids


def swap_header(text: str) -> str:
    """A load-on-demand file reads the main addon's table from _G."""
    for old in (HEADER_OLD.replace("\n", "\r\n"), HEADER_OLD):
        at = text.find(old)
        if at == 0 or (at > 0 and text[at - 1] == "\n"):
            new = HEADER_NEW.replace("\n", "\r\n") if old.endswith("\r\n") else HEADER_NEW
            return text[:at] + new + text[at + len(old):]
    return text


def pick_names_for(name: str, title: str) -> set[str]:
    if ".Early.1to9." in name:
        return {f"{title.lower()}Early1to9"}
    return {f"{title.lower()}Picks"}


def copy_class_lua(src: Path, dest: Path, title: str) -> dict[str, int]:
    # Class files are not all valid UTF-8. latin-1 keeps every byte.
    text = swap_header(src.read_bytes().decode("latin-1"))
    try:
        text, counts = stage_pack.pack_class_text(text, pick_names_for(src.name, title), src.name)
    except stage_pack.PackError as err:
        raise SystemExit(f"stage-class-addons: {err}")
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(text.encode("latin-1"))
    return counts


def stage_item_stats(dest: Path, main_addon: Path) -> None:
    src = GENERATED / ITEM_STATS_NAME
    if not src.is_file():
        raise SystemExit(f"missing {src}")
    folder = dest / ITEM_STATS_ADDON
    folder.mkdir(parents=True, exist_ok=True)
    text = swap_header(src.read_bytes().decode("latin-1"))
    if HEADER_NEW not in text and HEADER_NEW.replace("\n", "\r\n") not in text:
        raise SystemExit(f"stage-class-addons: {ITEM_STATS_NAME} has no 'local _, GQ = ...' line")
    (folder / ITEM_STATS_NAME).write_bytes(text.encode("latin-1"))
    staged_main = main_addon / "_generated" / ITEM_STATS_NAME
    if staged_main.is_file():
        staged_main.unlink()
    lines = [
        "## Interface: 16001",
        "## Title: GearQuest Forever: Item Stats",
        "## Notes: Item stats for custom specs. GearQuest Forever loads this the first time a custom spec is scored.",
        "## Author: Henrik8210",
        f"## Version: {addon_version()}",
        "## IconTexture: Interface\\AddOns\\GearQuestForever\\Art\\GearQuest-Icon",
        "## LoadOnDemand: 1",
        "## Dependencies: GearQuestForever",
        "## RequiredDeps: GearQuestForever",
        "",
        ITEM_STATS_NAME,
        "",
    ]
    (folder / f"{ITEM_STATS_ADDON}.toc").write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print(f"{ITEM_STATS_ADDON}: {ITEM_STATS_NAME}")


def stage_coordinates(main_addon: Path) -> None:
    src = GENERATED / COORDINATES_NAME
    if not src.is_file():
        raise SystemExit(f"missing {src}")
    text = src.read_bytes().decode("latin-1")
    try:
        shared, report = stage_pack.share_coordinates(text)
    except stage_pack.PackError as err:
        raise SystemExit(f"stage-class-addons: {err}")
    dest = main_addon / "_generated" / COORDINATES_NAME
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(shared.encode("latin-1"))
    print(
        f"coordinates: {report['rows']} items, {report['rowsWithSpots']} with spots, "
        f"{report['spots']} distinct spots, {report['lists']} distinct spot lists"
    )


def addon_version() -> str:
    toc = Path(__file__).resolve().parents[1] / "GearQuest" / "GearQuestForever.toc"
    for line in toc.read_text(encoding="utf-8").splitlines():
        if line.startswith("## Version:"):
            return line.split(":", 1)[1].strip()
    raise SystemExit("GearQuestForever.toc has no ## Version")


def write_toc(folder: Path, title: str, files: list[str]) -> None:
    lines = [
        "## Interface: 16001",
        f"## Title: GearQuest Forever: {title}",
        "## Notes: Hunt lists for this class. GearQuest Forever loads this when you play or simulate it.",
        "## Author: Henrik8210",
        f"## Version: {addon_version()}",
        f"## IconTexture: Interface\\Icons\\ClassIcon_{title}",
        "## LoadOnDemand: 1",
        "## Dependencies: GearQuestForever",
        "## RequiredDeps: GearQuestForever",
        "",
        *files,
        "AuditTips.lua",
        "",
    ]
    (folder / f"{folder.name}.toc").write_text("\n".join(lines), encoding="utf-8", newline="\n")


def write_audit_tips(path: Path, tips: dict[int, str]) -> None:
    rows = ["local GQ = _G.GearQuest", "local audit = GQ and GQ.Data and GQ.Data.foreverAudit", "if not audit then return end", "local tips = {"]
    for item_id in sorted(tips):
        rows.append(f"    [{item_id}]={lua_str(tips[item_id])},")
    rows.append("}")
    rows.append("for id, tip in pairs(tips) do")
    rows.append("    local row = audit[id]")
    rows.append("    if row then row.tip = tip end")
    rows.append("end")
    rows.append("")
    path.write_text("\n".join(rows), encoding="utf-8", newline="\n")


def class_tips(audit_path: Path, class_ids: dict[str, set[int]]) -> tuple[list[str], dict[str, dict[int, str]]]:
    owned: dict[int, list[str]] = {}
    for class_file, ids in class_ids.items():
        for item_id in ids:
            owned.setdefault(item_id, []).append(class_file)

    tips_by_class = {class_file: {} for class_file in class_ids}
    stripped_lines: list[str] = []
    id_re = re.compile(r"^\s*\[(\d+)\]=")
    with audit_path.open(encoding="utf-8") as handle:
        for line in handle:
            match = id_re.match(line)
            if not match:
                stripped_lines.append(line)
                continue
            item_id = int(match.group(1))
            classes = owned.get(item_id)
            if not classes:
                stripped_lines.append(line)
                continue
            new_line, tip = strip_tip(line)
            stripped_lines.append(new_line)
            if tip:
                for class_file in classes:
                    tips_by_class[class_file][item_id] = tip
    return stripped_lines, tips_by_class


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dest", required=True, help="AddOns directory or .release directory")
    parser.add_argument("--main", required=True, help="Staged GearQuestForever addon folder to strip")
    args = parser.parse_args()

    dest = Path(args.dest)
    main_addon = Path(args.main)
    audit_src = GENERATED / AUDIT_NAME
    if not audit_src.is_file():
        raise SystemExit(f"missing {audit_src}")

    class_ids = {}
    for class_file, (_title, files) in CLASSES.items():
        ids: set[int] = set()
        for name in files:
            ids |= item_ids(GENERATED / name)
        class_ids[class_file] = ids

    stripped, tips_by_class = class_tips(audit_src, class_ids)
    audit_dest = main_addon / "_generated" / AUDIT_NAME
    audit_dest.parent.mkdir(parents=True, exist_ok=True)
    audit_dest.write_text("".join(stripped), encoding="utf-8", newline="\n")

    for class_file, (title, files) in CLASSES.items():
        folder = dest / f"GearQuestForever_{class_file}"
        folder.mkdir(parents=True, exist_ok=True)
        rows = 0
        for name in files:
            rows += sum(copy_class_lua(GENERATED / name, folder / name, title).values())
            staged_main = main_addon / "_generated" / name
            if staged_main.is_file():
                staged_main.unlink()
        write_audit_tips(folder / "AuditTips.lua", tips_by_class[class_file])
        write_toc(folder, title, files)
        print(f"{folder.name}: {rows} pick rows packed, {len(tips_by_class[class_file])} tooltip texts")

    stage_item_stats(dest, main_addon)
    stage_coordinates(main_addon)
    print(f"stripped audit -> {audit_dest}")


if __name__ == "__main__":
    main()
