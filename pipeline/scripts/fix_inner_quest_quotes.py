"""Fix inner double quotes that broke Lua strings after curly-quote folding."""
import re
from pathlib import Path
from gq_paths import OUT, ADDON_GEN

pat = re.compile(r'quest "([^"]+)"')


def fix(text):
    text = re.sub(r'quest "([^"]+)" " pick', r"quest '\1' - pick", text)
    text = re.sub(r'quest "([^"]+)"', r"quest '\1'", text)
    return text


for folder in (Path(ADDON_GEN), Path(OUT)):
    if not folder.exists():
        continue
    for path in folder.glob("Data.*.generated.lua"):
        text = path.read_text(encoding="utf-8")
        new = fix(text)
        if new != text:
            path.write_text(new, encoding="utf-8", newline="\n")
            print("fixed", path.name)
        else:
            print("ok", path.name)
