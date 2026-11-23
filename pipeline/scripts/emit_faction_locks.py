"""Write the vendor and drop faction locks the addon reads at display time.

quest_faction.json is written by index_coordinates.py. These two tables are
the same kind of lock: a Horde-only row never shows to Alliance, and the
reverse. A hunt that is not in the table is one both factions can get.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "pipeline" / "data"
GEN = ROOT / "GearQuest" / "_generated"

TABLES = (
    ("vendor_side.json", "Data.VendorSide.generated.lua", "vendorSide",
     "A vendor whose every seller is one faction. Absent means both factions."),
    ("drop_faction.json", "Data.DropFaction.generated.lua", "dropFaction",
     "A dropper friendly to one faction and hostile to the other. Absent means both."),
)


def emit(json_name: str, lua_name: str, field: str, comment: str) -> None:
    sides = json.loads((DATA / json_name).read_text(encoding="utf-8"))
    lines = [
        f'    [{int(iid)}] = "{side}",'
        for iid, side in sorted(sides.items(), key=lambda kv: int(kv[0]))
    ]
    text = (
        "local _, GQ = ...\n"
        "GQ.Data = GQ.Data or {}\n"
        "\n"
        f"-- {comment}\n"
        f"GQ.Data.{field} = {{\n"
        + "\n".join(lines)
        + "\n}\n"
    )
    (GEN / lua_name).write_text(text, encoding="utf-8", newline="\n")
    print(f"{lua_name} {len(lines)} locks")


def main() -> None:
    for spec in TABLES:
        emit(*spec)


if __name__ == "__main__":
    main()
