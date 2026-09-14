#!/usr/bin/env python3
"""Scrape Wowhead Classic random-enchantment tables.

Forever uses the Node scraper (`scripts/scrape-classic-random-enchants.mjs`) as
the live path. This file is kept so ad-hoc Python fetches still hit /classic/.

One HTTP request per item.  The plain HTML item page is blocked by Wowhead's
CloudFront for datacenter IPs (403), but appending `&power` to the item URL
returns the SAME full HTML page and is NOT blocked.  The "Random Enchantments"
section is server-rendered into that HTML, so a single curl/GET per item is
enough -- no JS execution, no headless browser.

  curl -sSL --compressed -A 'Mozilla/5.0' 'https://www.wowhead.com/classic/item=1207?power'

The canonical URL (no query string) IS blocked; `?power` is not.  Do NOT send a
realistic Chrome User-Agent -- CloudFront 403s it.  A plain UA works.

Usage:
  python3 wowhead_random.py 1207 1608 15228          # ad-hoc
  python3 wowhead_random.py --file ids.txt --out wowhead_random.json
"""
import json, re, sys, time, urllib.request, gzip, io, argparse, os

# NOTE: Wowhead's CloudFront bot-management BLOCKS a spoofed full Chrome
# User-Agent from a datacenter IP (403).  A plain / honest UA passes.  Do not
# "improve" this into a realistic browser string -- that is what gets blocked.
UA = "wow-classic-data-research/1.0 (+contact: local script)"
URL = "https://www.wowhead.com/classic/item={}?power"

# one <li> per suffix inside div.random-enchantments; the list is split over
# several sibling <div class="random-enchantments"> blocks (two-column layout).
LI_RX = re.compile(
    r'<li><div>\s*'
    r'<span class="q\d">\.\.\.(?P<name>[^<]+)</span>\s*'
    r'<small class="q0">\((?P<chance>[\d.]+)% chance\)</small>\s*<br\s*/?>'
    r'(?P<stats>.*?)</div></li>', re.S)
TAG_RX = re.compile(r'<[^>]+>')

def fetch(item_id, timeout=30):
    req = urllib.request.Request(URL.format(item_id), headers={
        "User-Agent": UA, "Accept-Encoding": "gzip",
        "Accept": "text/html,application/xhtml+xml"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        raw = r.read()
        if r.headers.get("Content-Encoding") == "gzip":
            raw = gzip.decompress(raw)
    return raw.decode("utf-8", "replace")

def parse(html):
    """-> list of {suffix, chance, stats:[str]} in Wowhead's own order."""
    out = []
    for m in LI_RX.finditer(html):
        stats_html = m.group("stats")
        # stats are comma-separated text fragments padded with whitespace
        parts = [TAG_RX.sub("", p).strip()
                 for p in stats_html.split(",")]
        parts = [re.sub(r"\s+", " ", p) for p in parts if p.strip()]
        out.append({"suffix": m.group("name").strip(),
                    "chance": float(m.group("chance")),
                    "stats": parts})
    return out

STAT_RX = re.compile(r'^\+\(?(\d+)(?:\s*-\s*(\d+))?\)?\s+(.*)$')
def normalize(stats):
    """['+(12 - 14) Attack Power'] -> [{'stat':'Attack Power','min':12,'max':14}]"""
    out = []
    for s in stats:
        m = STAT_RX.match(s)
        if m:
            lo = int(m.group(1)); hi = int(m.group(2) or m.group(1))
            out.append({"stat": m.group(3).strip(), "min": lo, "max": hi})
        else:
            out.append({"raw": s})
    return out

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("ids", nargs="*", type=int)
    ap.add_argument("--file", help="file with one item id per line")
    ap.add_argument("--out", default="wowhead_random.json")
    ap.add_argument("--sleep", type=float, default=0.6)
    ap.add_argument("--retries", type=int, default=3)
    a = ap.parse_args()

    ids = list(a.ids)
    if a.file:
        ids += [int(l) for l in open(a.file) if l.strip().isdigit()]

    res = json.load(open(a.out)) if os.path.exists(a.out) else {}
    for i, iid in enumerate(ids):
        if str(iid) in res:
            continue
        for attempt in range(a.retries):
            try:
                rows = parse(fetch(iid))
                res[str(iid)] = [{**r, "statsParsed": normalize(r["stats"])} for r in rows]
                break
            except Exception as e:
                if attempt == a.retries - 1:
                    res[str(iid)] = {"error": str(e)}
                else:
                    time.sleep(2 ** attempt)
        if i % 25 == 0:
            json.dump(res, open(a.out, "w"), indent=0)
            print(f"{i}/{len(ids)}", file=sys.stderr)
        time.sleep(a.sleep)
    json.dump(res, open(a.out, "w"), indent=0)
    print(f"wrote {a.out}: {len(res)} items", file=sys.stderr)

if __name__ == "__main__":
    main()
