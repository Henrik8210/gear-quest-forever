"""Re-splice the current review payload into a bench page.

The bench pages are how Henrik audits the lists, so a stale one is worse than none --
he found Left-Handed Brass Knuckles at 102.0 in a rogue off hand on a page built before
the off-hand fix. This makes regenerating them a one-liner, so they cannot drift again.

The HTML shell (styles, JS, prose) is left exactly as it is; only the <script
id="gqdata"> payload is replaced with <class>.review.json as it stands right now.
"""
import re, sys, os, json
from gq_paths import scored
for cls in sys.argv[1:]:
    page=os.path.join(os.path.dirname(__file__) or ".", cls+"-bench.html")
    blob=scored(cls+".review.json")
    s=open(page,encoding="utf-8").read()
    m=re.search(r'(<script id="gqdata" type="application/json">)(.*?)(</script>)', s, re.S)
    if not m: print(cls,"NO gqdata block"); continue
    new=open(blob,encoding="utf-8").read()
    old=json.loads(m.group(2)); cur=json.loads(new)
    s=s[:m.start(2)]+new+s[m.end(2):]
    open(page,"w",encoding="utf-8").write(s)
    def nb(d): return sum(len(v["bands"]) for v in d["specs"].values())
    print(f"  {cls+'-bench.html':<22} bands {nb(old)} -> {nb(cur)}   items {len(old['items'])} -> {len(cur['items'])}"
          f"   {os.path.getsize(page)/1e6:.2f} MB")
