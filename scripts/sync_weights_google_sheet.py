#!/usr/bin/env python3
"""Push pipeline/data/weights.json live grid to the class stat-weight Google Sheet.

First run opens a browser for OAuth (Desktop client). Tokens live in scripts/.google/
(gitignored). Requires Google Sheets API + Drive API enabled on the Cloud project.

  pip install gspread google-auth-oauthlib
  python scripts/sync_weights_google_sheet.py SHAMAN
  python scripts/sync_weights_google_sheet.py --all
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WEIGHTS_PATH = ROOT / "pipeline" / "data" / "weights.json"
SPREADSHEET_ID = "1jMC89KgzHpPZHYgcjOq6ef7lENhh8OGgypG2rC2m0Ok"
GOOGLE_DIR = ROOT / "scripts" / ".google"
CLIENT_SECRET = GOOGLE_DIR / "client_secret.json"
TOKEN_PATH = GOOGLE_DIR / "authorized_user.json"

# Worksheet title on each tab (class log scene name).
CLASS_WORKSHEETS = {
    "PALADIN": "Paladin",
    "WARRIOR": "Warrior",
    "HUNTER": "Hunter",
    "ROGUE": "Rogue",
    "DRUID": "Druid",
    "MAGE": "Mage",
    "PRIEST": "Priest",
    "SHAMAN": "Shaman",
    "WARLOCK": "Warlock",
}

# Header labels in the LIVE WEIGHTS grid (row with Stat / Key).
SPEC_COLUMNS = {
    "Levels 1-9": "levelling_1_9",
    "Elemental": "elemental",
    "Enhancement": "enhancement",
    "Enhancement Tank": "enhancement_tank",
    "Restoration": "restoration",
    "Holy": "holy",
    "Protection": "protection",
    "Retribution": "retribution",
    "Shockadin": "shockadin",
    "Arms": "arms",
    "Fury": "fury",
    "Beast Mastery": "beast_mastery",
    "Marksmanship": "marksmanship",
    "Survival": "survival",
    "Assassination": "assassination",
    "Combat": "combat",
    "Subtlety": "subtlety",
    "Balance": "balance",
    "Feral (Cat)": "feral",
    "Feral": "feral",
    "Guardian (Bear)": "bear",
    "Guardian": "bear",
    "Restoration": "restoration",
    "Shadow": "shadow",
    "Discipline": "discipline",
    "Frost": "frost",
    "Fire": "fire",
    "Arcane": "arcane",
    "Affliction": "affliction",
    "Demonology": "demonology",
    "Destruction": "destruction",
    "Battle Mage Frost": "battlemage_frost",
    "Battle Mage Fire": "battlemage_fire",
    "Battle Mage Arcane": "battlemage_arcane",
    "Battle Mage (Frost)": "battlemage_frost",
    "Battle Mage (Fire)": "battlemage_fire",
    "Battle Mage (Arcane)": "battlemage_arcane",
}


def get_client():
    try:
        import gspread
    except ImportError:
        raise SystemExit("pip install gspread google-auth-oauthlib")

    if not CLIENT_SECRET.is_file():
        raise SystemExit(f"Missing OAuth client: {CLIENT_SECRET}")

    return gspread.oauth(
        credentials_filename=str(CLIENT_SECRET),
        authorized_user_filename=str(TOKEN_PATH),
    )


def find_live_header(ws) -> tuple[int, dict[str, int]]:
    """Return (header_row_index_1based, label -> column_index_1based)."""
    values = ws.get_all_values()
    for i, row in enumerate(values):
        if len(row) >= 2 and row[0] == "Stat" and row[1] == "Key":
            cols = {}
            for j, label in enumerate(row):
                label = label.strip()
                if label in SPEC_COLUMNS or label in ("Levels 1-9",):
                    cols[label] = j + 1
            return i + 1, cols
    raise ValueError(f"Live header (Stat, Key) not found on {ws.title}")


def sync_class(ws, class_file: str, class_data: dict) -> list[str]:
    import gspread.utils

    header_row, col_by_label = find_live_header(ws)
    updates: list[str] = []

    values = ws.get_all_values()
    stat_end = header_row
    for i in range(header_row, len(values)):
        row = values[i]
        if not row or not row[0]:
            break
        if row[0] in ("Weapon", "Armor type (multiplies the whole score)"):
            break
        stat_end = i + 1

    weapon_row = None
    for i in range(header_row, min(stat_end + 8, len(values))):
        row = values[i]
        if row and row[0] == "Melee weapon damage" and len(row) > 1 and row[1] == "dpsWeight":
            weapon_row = i
            break

    grid_end = (weapon_row + 1) if weapon_row is not None else stat_end
    cols = sorted(col_by_label.values())
    if not cols:
        return updates
    col_min, col_max = min(cols), max(cols)

    for row_idx in range(header_row - 1, grid_end):
        if row_idx >= len(values):
            values.append([""] * col_max)
        row = values[row_idx]
        while len(row) < col_max:
            row.append("")
        if header_row <= row_idx + 1 < stat_end and len(row) > 1:
            stat_key = row[1].strip()
            if stat_key:
                for label, col in col_by_label.items():
                    spec_id = SPEC_COLUMNS.get(label)
                    if not spec_id or spec_id not in class_data:
                        continue
                    weights = class_data[spec_id].get("weights") or {}
                    if stat_key not in weights:
                        continue
                    val = weights[stat_key]
                    if isinstance(val, (int, float)):
                        old = row[col - 1]
                        if str(old).replace(",", ".") != str(val):
                            updates.append(f"{label} {stat_key}={val}")
                        row[col - 1] = val
        if weapon_row is not None and row_idx == weapon_row:
            for label, col in col_by_label.items():
                spec_id = SPEC_COLUMNS.get(label)
                if not spec_id or spec_id not in class_data:
                    continue
                val = class_data[spec_id].get("dpsWeight")
                if val is not None:
                    row[col - 1] = val
                    updates.append(f"{label} dpsWeight={val}")

    out_rows = [values[i][col_min - 1 : col_max] for i in range(header_row - 1, grid_end)]
    top_left = gspread.utils.rowcol_to_a1(header_row, col_min)
    bottom_right = gspread.utils.rowcol_to_a1(grid_end, col_max)
    ws.update(
        values=out_rows,
        range_name=f"{top_left}:{bottom_right}",
        value_input_option="USER_ENTERED",
    )

    return updates


def delete_stat_row(ws, stat_key: str) -> bool:
    """Drop one live-grid stat row. Hunters have no ranged attack power row."""
    values = ws.get_all_values()
    for i, row in enumerate(values):
        if len(row) > 1 and row[1].strip() == stat_key and row[0].strip():
            ws.delete_rows(i + 1)
            return True
    return False


def mark_suggestions_implemented(ws, name: str, rows: list[tuple[str, str]]) -> int:
    """Set Weber8210's note column for matching suggestion rows."""
    values = ws.get_all_values()
    note_col = None
    header_idx = None
    for i, row in enumerate(values):
        if row and row[0] == "Your name":
            header_idx = i
            for j, cell in enumerate(row):
                if cell.strip().startswith("Weber8210"):
                    note_col = j
            break
    if note_col is None or header_idx is None:
        return 0
    count = 0
    for i in range(header_idx + 1, len(values)):
        row = values[i]
        if not row or not row[0]:
            break
        author = row[0].strip().lower()
        want = name.strip().lower()
        if author != want and want not in author and author not in want:
            continue
        if len(row) <= 2:
            continue
        spec = row[1].strip()
        stat = row[2].strip()
        for want_spec, want_stat in rows:
            if spec == want_spec and stat == want_stat:
                while len(row) <= note_col:
                    row.append("")
                if row[note_col].strip().lower() != "implemented":
                    ws.update_cell(i + 1, note_col + 1, "Implemented")
                    count += 1
                break
    return count


def main() -> int:
    parser = argparse.ArgumentParser(description="Sync weights.json live grid to Google Sheets")
    parser.add_argument("classes", nargs="*", help="Class keys e.g. SHAMAN (default: SHAMAN)")
    parser.add_argument("--all", action="store_true", help="Sync every class in weights.json")
    args = parser.parse_args()

    weights = json.loads(WEIGHTS_PATH.read_text(encoding="utf-8"))
    if args.all:
        classes = [
            k
            for k in weights
            if not k.startswith("_") and k in CLASS_WORKSHEETS
        ]
    else:
        classes = [c.upper() for c in (args.classes or ["SHAMAN"])]

    gc = get_client()
    sh = gc.open_by_key(SPREADSHEET_ID)

    for class_file in classes:
        title = CLASS_WORKSHEETS.get(class_file)
        if not title:
            print(f"skip unknown class {class_file}")
            continue
        try:
            ws = sh.worksheet(title)
        except Exception:
            # fallback: title case of class name
            ws = sh.worksheet(title)
        block = weights[class_file]
        n = sync_class(ws, class_file, block)
        print(f"{class_file}: updated {len(n)} cells on tab {ws.title}")
        removed = delete_stat_row(ws, "rap")
        if removed:
            print("  removed the Ranged attack power row")
        marks = {
            "SHAMAN": [
                ("Maximus", "Enhancement", "Agility"),
                ("Maximus", "Levels 1-9", "Strength"),
            ],
            "DRUID": [
                (".eao.", "Guardian (Bear)", "Stamina"),
                (".eao.", "Guardian (Bear)", "Hit"),
                (".eao.", "Guardian (Bear)", "Critical strike"),
            ],
        }
        if class_file in marks:
            total = 0
            for row in marks[class_file]:
                total += mark_suggestions_implemented(ws, row[0], [row[1:]])
            if total:
                print(f"  marked {total} suggestion row(s) Implemented")

    print("done")
    return 0


if __name__ == "__main__":
    sys.exit(main())