"""Keep items the Forever game client does not have out of the addon.

Wowhead Forever lists items the client cannot load yet: GetItemInfo fails,
and the hover could only show the stored Wowhead tip with the red "This game
client does not have it yet" lines. Those rows stay in items.json and
sources.json, and `pipeline/data/client_missing.json` keeps the list, so a
later client build that ships them brings them back.

An item is in the client when the Forever build's ItemSparse table has the
row (wago.tools serves it per build), or the installed client's hotfix cache
(Cache/ADB/enUS/DBCache.bin) holds a valid ItemSparse record for it. A row in
the Item table alone is not enough: without ItemSparse the client has no name
or stats, and the server answers those hotfix requests as invalid.

    python pipeline/scripts/apply_client_missing.py --refresh [--build 1.60.1.70938] [--dbcache PATH] [--cache DIR]
    python pipeline/scripts/apply_client_missing.py

--refresh rebuilds client_missing.json from that build (default: the installed
client's version) and then applies it. Without it, the stored list is applied.
Each excluded row gets `clientMissing` (the build), obtainable false, and the
reason. A row that leaves the list is restored. A row already excluded for
another reason is left alone. Run after apply_forever_absent.py and before the
rescore; the rescore drops the rows and the ranks close up.
"""
from __future__ import annotations

import csv
import json
import os
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gq_paths import DATA  # noqa: E402

LIST = Path(DATA) / "client_missing.json"
SOURCES = Path(DATA) / "sources.json"
ITEMS = Path(DATA) / "items.json"
WOW = Path(r"C:\Program Files (x86)\World of Warcraft")
DBCACHE = WOW / "_forever_" / "Cache" / "ADB" / "enUS" / "DBCache.bin"
ITEM_SPARSE_HASH = 0x919BE54E
csv.field_size_limit(1 << 30)


def arg(name: str, default: str | None = None) -> str | None:
    if name in sys.argv:
        return sys.argv[sys.argv.index(name) + 1]
    return default


def installed_build() -> str | None:
    info = WOW / ".build.info"
    if not info.exists():
        return None
    rows = info.read_text(encoding="utf-8").splitlines()
    head = [h.split("!")[0] for h in rows[0].split("|")]
    for row in rows[1:]:
        cols = dict(zip(head, row.split("|")))
        if cols.get("Product") == "wowf" and cols.get("Version"):
            return cols["Version"]
    return None


def sparse_ids(build: str, cache: Path) -> set[int]:
    path = cache / f"ItemSparse.{build}.enUS.csv"
    if not path.exists():
        url = f"https://wago.tools/db2/ItemSparse/csv?build={build}&locale=enUS"
        subprocess.run(["curl", "-sSf", "-o", str(path), url], check=True)
    with open(path, encoding="utf-8", newline="") as f:
        return {int(row["ID"]) for row in csv.DictReader(f)}


def hotfix_ids(path: Path) -> set[int]:
    """ItemSparse records whose last hotfix in the cache is valid."""
    if not path.exists():
        return set()
    data = path.read_bytes()
    last: dict[int, int] = {}
    i = data.find(b"XFTH", 4)
    while 0 <= i <= len(data) - 32:
        magic, _push, _unique, _, table, record, size, status = struct.unpack_from("<4s7I", data, i)
        if magic != b"XFTH":
            raise ValueError(f"unexpected bytes at {i} in {path}")
        if table == ITEM_SPARSE_HASH:
            last[record] = status
        i += 32 + size
    return {rid for rid, status in last.items() if status == 1}


def refresh(items: dict) -> dict:
    build = arg("--build") or installed_build()
    if not build:
        raise SystemExit("no --build and no installed Forever client")
    cache = Path(arg("--cache") or Path(tempfile.gettempdir()) / "gq_db2")
    cache.mkdir(parents=True, exist_ok=True)
    dbcache = Path(arg("--dbcache") or DBCACHE)
    client = sparse_ids(build, cache) | hotfix_ids(dbcache)
    missing = {k: (v or {}).get("name") for k, v in items.items() if k.isdigit() and int(k) not in client}
    data = {
        "build": build,
        "hotfixCache": dbcache.exists(),
        "items": dict(sorted(missing.items(), key=lambda kv: int(kv[0]))),
    }
    LIST.write_text(json.dumps(data, indent=1, ensure_ascii=True) + "\n", encoding="utf-8")
    print(f"build {build}: client has {len(client)} items, {len(missing)} catalog items missing -> {LIST}")
    return data


def main() -> None:
    items = json.loads(ITEMS.read_text(encoding="utf-8"))
    data = refresh(items) if "--refresh" in sys.argv else json.loads(LIST.read_text(encoding="utf-8"))
    build, missing = data["build"], data["items"]
    sources = json.loads(SOURCES.read_text(encoding="utf-8"))
    reason = f"The game client does not have this item yet (build {build})."

    excluded = restored = 0
    for key, src in sources.items():
        if not isinstance(src, dict):
            continue
        marked = src.get("clientMissing")
        if key in missing:
            if src.get("obtainable") is False and not marked:
                continue
            if not marked:
                excluded += 1
            src["obtainable"] = False
            src["excludedBecause"] = reason
            src["clientMissing"] = build
        elif marked:
            src["obtainable"] = True
            src["excludedBecause"] = None
            del src["clientMissing"]
            restored += 1

    tmp = SOURCES.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(sources, ensure_ascii=True, separators=(",", ":")), encoding="utf-8")
    tmp.replace(SOURCES)
    print(f"excluded {excluded} restored {restored}")


if __name__ == "__main__":
    main()
