"""Replace curly quotes / replacement chars in generated Lua so WoW does not draw boxes."""
from pathlib import Path
from gq_paths import OUT, ADDON_GEN

REPLACEMENTS = {
    "\ufffd": "'",
    "\u201c": "'",
    "\u201d": "'",
    "\u2018": "'",
    "\u2019": "'",
    "\u2014": "-",
    "\u2013": "-",
    "\u2026": "...",
    "\u00a0": " ",
    "\x93": "'",
    "\x94": "'",
    "\x91": "'",
    "\x92": "'",
    "\x97": "-",
    "\x96": "-",
}


def clean(text):
    for src, dst in REPLACEMENTS.items():
        text = text.replace(src, dst)
    return text


for folder in (Path(ADDON_GEN), Path(OUT)):
    if not folder.exists():
        continue
    for path in folder.glob("Data.*.generated.lua"):
        raw = path.read_bytes()
        for enc in ("utf-8", "cp1252", "latin-1"):
            try:
                text = raw.decode(enc)
                break
            except UnicodeDecodeError:
                text = None
        if text is None:
            text = raw.decode("utf-8", errors="replace")
        new = clean(text)
        if new != text:
            path.write_text(new, encoding="utf-8", newline="\n")
            print("cleaned", path.name)
        else:
            print("ok", path.name)
