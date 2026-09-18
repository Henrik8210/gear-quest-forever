"""Inject quality/ilvl/reqLevel into existing generated fact tables."""
import json
import re
from pathlib import Path

from gq_paths import G, OUT, ADDON_GEN

items = json.load(open(G + "items.json", encoding="utf-8"))
pat = re.compile(r'\[(\d+)\]=\{name=("(?:\\.|[^"\\])*"),(?!quality=)')


def repl(match):
    item = items.get(match.group(1)) or {}
    extra = ""
    quality = item.get("quality")
    if quality is not None:
        extra += "quality=%d," % int(quality)
    ilvl = item.get("ilvl")
    if ilvl:
        extra += "ilvl=%d," % int(ilvl)
    rlvl = item.get("rlvl")
    if rlvl:
        extra += "reqLevel=%d," % int(rlvl)
    return "[%s]={name=%s,%s" % (match.group(1), match.group(2), extra)


folders = [Path(ADDON_GEN), Path(OUT)]
for folder in folders:
    if not folder.exists():
        continue
    for path in folder.glob("Data.*.generated.lua"):
        text = path.read_text(encoding="utf-8", errors="replace")
        new, count = pat.subn(repl, text)
        if count:
            path.write_text(new, encoding="utf-8", newline="\n")
            print("%s: %d facts" % (path, count))
        else:
            print("%s: no changes" % path)
