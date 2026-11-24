"""Compact forms of the generated data, written only into the staged addons.

The repo keeps the readable generated files. The pipeline checks read those.
Staging writes the same facts in a form that costs less memory in the game:

- Pick rows become one text line each, grouped by faction, so the addon can
  expand only the faction on screen and read the other one again later.
- Coordinate spots and spot lists that repeat are written once and shared.

Every pack is read back here and compared with the source. A difference stops
the stage.
"""

from __future__ import annotations

import re

ARRAY_START = re.compile(r"^GQ\.Data\.(\w+)\s*=\s*\{\s*$")
ROW_LINE = re.compile(r"^\s*\{(.*)\},?\s*$")
INT = re.compile(r"^\d+$")
NUMBER = re.compile(r"^-?\d+(\.\d+)?([eE][-+]?\d+)?$")
NAMED = re.compile(r"^([A-Za-z_]\w*)=(.*)$", re.S)

EXTRA_KEYS = {
    "reserve", "suffix", "suffixChance", "suffixId", "suffixRange",
    "hand", "route", "healOnly", "origin", "guidePlace",
}
NO_FACTION = "_"


class PackError(Exception):
    pass


def lua_str(text: str) -> str:
    out = (
        text.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\r", "\\r")
        .replace("\n", "\\n")
    )
    return '"' + out + '"'


def read_lua_string(token: str) -> str:
    if len(token) < 2 or token[0] != '"' or token[-1] != '"':
        raise PackError(f"not a string literal: {token!r}")
    out: list[str] = []
    i = 1
    end = len(token) - 1
    while i < end:
        c = token[i]
        if c == "\\":
            nxt = token[i + 1]
            out.append({"n": "\n", "r": "\r", "t": "\t", "\\": "\\", '"': '"'}.get(nxt, nxt))
            i += 2
            continue
        if c == '"':
            raise PackError(f"bare quote inside {token!r}")
        out.append(c)
        i += 1
    return "".join(out)


def split_items(body: str) -> list[str]:
    """Top-level comma split of a flat Lua table body. Strings may hold commas."""
    items: list[str] = []
    cur: list[str] = []
    in_str = False
    esc = False
    depth = 0
    for c in body:
        if in_str:
            cur.append(c)
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
            continue
        if c == '"':
            in_str = True
        elif c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth < 0:
                raise PackError(f"unbalanced braces in {body!r}")
        elif c == "," and depth == 0:
            items.append("".join(cur).strip())
            cur = []
            continue
        cur.append(c)
    if in_str or depth != 0:
        raise PackError(f"unterminated item in {body!r}")
    tail = "".join(cur).strip()
    if tail:
        items.append(tail)
    return items


# --------------------------------------------------------------------------
# Pick rows
# --------------------------------------------------------------------------

def parse_pick_row(line: str):
    m = ROW_LINE.match(line)
    if not m:
        raise PackError(f"pick row does not look like a row: {line.strip()[:120]!r}")
    items = split_items(m.group(1))
    positional: list[str] = []
    named: list[str] = []
    for item in items:
        nm = NAMED.match(item)
        if nm and not item.startswith('"'):
            key = nm.group(1)
            if key not in EXTRA_KEYS:
                raise PackError(f"unknown pick field {key!r} in {line.strip()[:120]!r}")
            named.append(item)
        else:
            if named:
                raise PackError(f"positional value after a named one in {line.strip()[:120]!r}")
            positional.append(item)
    if len(positional) != 8:
        raise PackError(f"pick row has {len(positional)} positional values: {line.strip()[:120]!r}")
    item_id, slot, lo, hi, rank, spec, faction, score = positional
    for label, tok in (("itemId", item_id), ("minLevel", lo), ("maxLevel", hi), ("rank", rank)):
        if not INT.match(tok):
            raise PackError(f"{label} {tok!r} is not a whole number in {line.strip()[:120]!r}")
    if not NUMBER.match(score):
        raise PackError(f"score {score!r} is not a number in {line.strip()[:120]!r}")
    slot_raw = read_lua_string(slot)
    spec_raw = read_lua_string(spec)
    faction_raw = NO_FACTION if faction == "nil" else read_lua_string(faction)
    if faction_raw == NO_FACTION and faction != "nil":
        raise PackError("a faction may not be named _")
    has_suffix = any(item.startswith("suffix=") for item in named)
    return {
        "item": item_id,
        "slot": slot_raw,
        "lo": lo,
        "hi": hi,
        "rank": rank,
        "spec": spec_raw,
        "faction": faction_raw,
        "score": score,
        "extra": "{" + ",".join(named) + "}" if named else "",
        "suffix": has_suffix,
    }


def pack_rows(rows: list[dict]) -> dict:
    slots: list[str] = []
    specs: list[str] = []
    extras: list[str] = []
    slot_ix: dict[str, int] = {}
    spec_ix: dict[str, int] = {}
    extra_ix: dict[str, int] = {}
    by_faction: dict[str, list[str]] = {}
    masks: dict[str, dict[str, set[int]]] = {}
    suffix_rows: list[str] = []
    for row in rows:
        if row["slot"] not in slot_ix:
            slots.append(row["slot"])
            slot_ix[row["slot"]] = len(slots)
        if row["spec"] not in spec_ix:
            specs.append(row["spec"])
            spec_ix[row["spec"]] = len(specs)
            if len(specs) > 9:
                raise PackError("more than nine specs in one pick table")
        extra = 0
        if row["extra"]:
            if row["extra"] not in extra_ix:
                extras.append(row["extra"])
                extra_ix[row["extra"]] = len(extras)
            extra = extra_ix[row["extra"]]
        line = " ".join((
            row["item"], str(slot_ix[row["slot"]]), row["lo"], row["hi"], row["rank"],
            str(spec_ix[row["spec"]]), row["score"], str(extra),
        ))
        by_faction.setdefault(row["faction"], []).append(line)
        masks.setdefault(row["faction"], {}).setdefault(row["item"], set()).add(spec_ix[row["spec"]])
        if row["suffix"]:
            suffix_rows.append(f"{row['item']} {row['lo']} {extra}")
    return {
        "slots": slots,
        "specs": specs,
        "extras": extras,
        "rows": {faction: "".join(l + "\n" for l in lines) for faction, lines in by_faction.items()},
        "specMask": {
            faction: "\n" + "".join(f"{item} {''.join(str(i) for i in sorted(ix))}\n" for item, ix in items.items())
            for faction, items in masks.items()
        },
        "suffixRows": "".join(l + "\n" for l in suffix_rows),
    }


def unpack_rows(packed: dict) -> dict[str, list[tuple]]:
    """Read packed rows back the way DataAdapter.lua does."""
    out: dict[str, list[tuple]] = {}
    for faction, text in packed["rows"].items():
        rows = []
        for line in text.split("\n"):
            if not line:
                continue
            item, slot, lo, hi, rank, spec, score, extra = line.split(" ")
            rows.append((
                item, packed["slots"][int(slot) - 1], lo, hi, rank,
                packed["specs"][int(spec) - 1], score,
                packed["extras"][int(extra) - 1] if extra != "0" else "",
            ))
        out[faction] = rows
    return out


def check_pack(rows: list[dict], packed: dict, name: str) -> None:
    want: dict[str, list[tuple]] = {}
    for row in rows:
        want.setdefault(row["faction"], []).append((
            row["item"], row["slot"], row["lo"], row["hi"], row["rank"],
            row["spec"], row["score"], row["extra"],
        ))
    got = unpack_rows(packed)
    if set(want) != set(got):
        raise PackError(f"{name}: factions changed in the pack ({sorted(want)} vs {sorted(got)})")
    for faction in want:
        if want[faction] != got[faction]:
            for i, (a, b) in enumerate(zip(want[faction], got[faction])):
                if a != b:
                    raise PackError(f"{name} {faction} row {i + 1}: {a} became {b}")
            raise PackError(f"{name} {faction}: {len(want[faction])} rows became {len(got[faction])}")
    for faction, items in packed["specMask"].items():
        expect: dict[str, set[str]] = {}
        for r in want[faction]:
            expect.setdefault(r[0], set()).add(r[5])
        listed = set()
        for line in items.strip("\n").split("\n"):
            item, ix = line.split(" ")
            listed.add(item)
            if {packed["specs"][int(c) - 1] for c in ix} != expect.get(item):
                raise PackError(f"{name} {faction}: spec list for {item} is wrong")
        if listed != set(expect):
            raise PackError(f"{name} {faction}: spec list misses items")
    suffix_want = [f"{r['item']} {r['lo']}" for r in rows if r["suffix"]]
    suffix_got = [" ".join(l.split(" ")[:2]) for l in packed["suffixRows"].split("\n") if l]
    if suffix_want != suffix_got:
        raise PackError(f"{name}: suffix rows do not match")


def lua_packed(name: str, packed: dict) -> list[str]:
    lines = [f"GQ.Data.{name}Packed = {{"]
    lines.append("    slots = {" + ",".join(lua_str(s) for s in packed["slots"]) + "},")
    lines.append("    specs = {" + ",".join(lua_str(s) for s in packed["specs"]) + "},")
    lines.append("    extras = {")
    for extra in packed["extras"]:
        lines.append(f"        {extra},")
    lines.append("    },")
    lines.append("    rows = {")
    for faction in sorted(packed["rows"]):
        lines.append(f"        [{lua_str(faction)}] = {lua_str(packed['rows'][faction])},")
    lines.append("    },")
    lines.append("    specMask = {")
    for faction in sorted(packed["specMask"]):
        lines.append(f"        [{lua_str(faction)}] = {lua_str(packed['specMask'][faction])},")
    lines.append("    },")
    lines.append(f"    suffixRows = {lua_str(packed['suffixRows'])},")
    lines.append("}")
    return lines


def pack_class_text(text: str, pick_names: set[str], label: str) -> tuple[str, dict[str, int]]:
    """Replace each pick array in a class file with its packed table."""
    lines = text.split("\n")
    out: list[str] = []
    counts: dict[str, int] = {}
    i = 0
    while i < len(lines):
        line = lines[i]
        m = ARRAY_START.match(line.rstrip("\r"))
        if not m or m.group(1) not in pick_names:
            out.append(line)
            i += 1
            continue
        name = m.group(1)
        rows: list[dict] = []
        i += 1
        while True:
            if i >= len(lines):
                raise PackError(f"{label}: {name} never closes")
            body = lines[i].rstrip("\r")
            if body.startswith("}"):
                if body.strip() != "}":
                    raise PackError(f"{label}: {name} closes with {body!r}")
                break
            if body.strip():
                rows.append(parse_pick_row(body))
            i += 1
        i += 1
        packed = pack_rows(rows)
        check_pack(rows, packed, f"{label} {name}")
        out.extend(lua_packed(name, packed))
        counts[name] = len(rows)
    missing = pick_names - set(counts)
    if missing:
        raise PackError(f"{label}: no pick table named {', '.join(sorted(missing))}")
    return "\n".join(out), counts


# --------------------------------------------------------------------------
# Coordinates
# --------------------------------------------------------------------------

COORD_ROW = re.compile(r"^(\s*)\[(\d+)\]=\{(.*)\}(,?)\s*$")
COORD_START = "GQ.Data.coordinates = {"
SHARED_REF = re.compile(r"^(\s*)\[(\d+)\]=\{(.*)spots=P\[(\d+)\](.*)\}(,?)\s*$")


def find_spots(body: str) -> tuple[int, int] | None:
    """Start and end (exclusive) of the spots={...} value inside a row body."""
    in_str = False
    esc = False
    depth = 0
    i = 0
    n = len(body)
    while i < n:
        c = body[i]
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
        elif c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
        elif depth == 0 and body.startswith("spots={", i) and (i == 0 or body[i - 1] == ","):
            start = i + len("spots=")
            j = start
            d = 0
            s_in = False
            s_esc = False
            while j < n:
                cj = body[j]
                if s_in:
                    if s_esc:
                        s_esc = False
                    elif cj == "\\":
                        s_esc = True
                    elif cj == '"':
                        s_in = False
                elif cj == '"':
                    s_in = True
                elif cj == "{":
                    d += 1
                elif cj == "}":
                    d -= 1
                    if d == 0:
                        return start, j + 1
                j += 1
            raise PackError(f"spots never close in {body[:120]!r}")
        i += 1
    return None


def split_spots(value: str) -> list[str]:
    if not (value.startswith("{") and value.endswith("}")):
        raise PackError(f"spots is not a table: {value[:120]!r}")
    spots = split_items(value[1:-1])
    for spot in spots:
        if not (spot.startswith("{") and spot.endswith("}")):
            raise PackError(f"spot is not a table: {spot[:120]!r}")
        for item in split_items(spot[1:-1]):
            nm = NAMED.match(item)
            value = nm.group(2) if nm and not item.startswith('"') else item
            if value.startswith("{"):
                raise PackError(f"spot holds a nested table: {spot[:120]!r}")
    return spots


def share_coordinates(text: str) -> tuple[str, dict[str, int]]:
    lines = text.split("\n")
    try:
        start = next(i for i, l in enumerate(lines) if l.rstrip("\r") == COORD_START)
    except StopIteration:
        raise PackError("coordinate file has no GQ.Data.coordinates table")
    spot_ix: dict[str, int] = {}
    spot_list: list[str] = []
    list_ix: dict[str, int] = {}
    list_list: list[list[int]] = []
    out_rows: list[str] = []
    originals: list[str] = []
    rows = 0
    shared_rows = 0
    i = start + 1
    while i < len(lines):
        line = lines[i].rstrip("\r")
        if line.startswith("}"):
            break
        i += 1
        if not line.strip():
            out_rows.append(line)
            originals.append(line)
            continue
        m = COORD_ROW.match(line)
        if not m:
            raise PackError(f"coordinate row does not look like a row: {line[:120]!r}")
        rows += 1
        originals.append(line)
        indent, item, body, comma = m.groups()
        span = find_spots(body)
        if not span:
            out_rows.append(line)
            continue
        value = body[span[0]:span[1]]
        refs: list[int] = []
        for spot in split_spots(value):
            if spot not in spot_ix:
                spot_list.append(spot)
                spot_ix[spot] = len(spot_list)
            refs.append(spot_ix[spot])
        key = ",".join(str(r) for r in refs)
        if key not in list_ix:
            list_list.append(refs)
            list_ix[key] = len(list_list)
        shared_rows += 1
        new_body = body[: span[0] - len("spots=")] + f"spots=P[{list_ix[key]}]" + body[span[1]:]
        out_rows.append(f"{indent}[{item}]={{{new_body}}}{comma}")
    else:
        raise PackError("coordinate table never closes")
    tail = lines[i:]
    head = lines[:start]
    shared = [
        "-- Staged copy: a spot or spot list that repeats is written once and",
        "-- shared. scripts/stage_pack.py compared every row with the repo file.",
        "local S = {",
    ]
    shared.extend(f"    {spot}," for spot in spot_list)
    shared.append("}")
    shared.append("local P = {")
    shared.extend("    {" + ",".join(f"S[{r}]" for r in refs) + "}," for refs in list_list)
    shared.append("}")
    new_text = "\n".join(head + shared + [lines[start]] + out_rows + tail)
    check_coordinates(originals, new_text)
    return new_text, {
        "rows": rows,
        "rowsWithSpots": shared_rows,
        "spots": len(spot_list),
        "lists": len(list_list),
    }


def check_coordinates(originals: list[str], staged: str) -> None:
    """Read the staged file back and rebuild every original row from it."""
    lines = staged.split("\n")
    spots: list[str] = []
    lists: list[list[int]] = []
    mode = None
    rows: list[str] = []
    for raw in lines:
        line = raw.rstrip("\r")
        if line == "local S = {":
            mode = "S"
            continue
        if line == "local P = {":
            mode = "P"
            continue
        if line == COORD_START:
            mode = "rows"
            continue
        if line.startswith("}"):
            mode = None if mode != "rows" else "done"
            continue
        if mode == "S":
            spots.append(line.strip()[:-1])
        elif mode == "P":
            body = line.strip()[1:-2]
            lists.append([int(x[2:-1]) for x in body.split(",")] if body else [])
        elif mode == "rows":
            rows.append(line)
    if len(rows) != len(originals):
        raise PackError(f"coordinate rows: {len(originals)} became {len(rows)}")
    for want, got in zip(originals, rows):
        m = SHARED_REF.match(got)
        if m:
            indent, item, before, ref, after, comma = m.groups()
            refs = lists[int(ref) - 1]
            value = "{" + ",".join(spots[r - 1] for r in refs) + "}"
            got = f"{indent}[{item}]={{{before}spots={value}{after}}}{comma}"
        if got != want:
            raise PackError(f"coordinate row changed when shared:\n  {want[:160]}\n  {got[:160]}")
