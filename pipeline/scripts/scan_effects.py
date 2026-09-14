import json,re,collections,html
rx_tag=re.compile(r"<[^>]+>")
def txt(s):
    s=re.sub(r"<!--[^>]*?-->","",s)
    s=rx_tag.sub("",s)
    return html.unescape(s)
cnt=collections.Counter()
with open("/tmp/wowsims-tbc/assets/item_data/all_item_tooltips.csv",encoding="utf-8") as f:
    next(f)
    for line in f:
        a=line.split(",",2)
        if len(a)<3: continue
        try: d=json.loads(a[2].strip())
        except: continue
        t=d.get("tooltip","")
        for m in re.finditer(r'<span class="q2">(?:Equip|Use):(.*?)</span>', t, re.S):
            s=txt(m.group(1)).strip()
            s=re.sub(r"[\d,.]+","N",s)
            cnt[s[:110]]+=1
print(f"{len(cnt)} distinct effect patterns\n")
for s,c in cnt.most_common(60):
    print(f"{c:>6}  {s}")
