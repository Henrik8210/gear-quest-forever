import re, sqlite3, sys, os

SRC = "/tmp/tbcdb.sql"
DB  = "/home/claude/gq/tbc.db"

WANT = {
 "item_template","item_enchantment_template","creature_loot_template","creature_template",
 "quest_template","npc_vendor","npc_vendor_template","reference_loot_template",
 "gameobject_loot_template","item_loot_template","npc_trainer","npc_trainer_template",
 "spell_template","creature","creature_questrelation","gameobject_template","game_tele","gameobject","fishing_loot_template","pickpocketing_loot_template","skinning_loot_template","mail_loot_template","disenchant_loot_template",
}

if os.path.exists(DB): os.remove(DB)
con = sqlite3.connect(DB)
con.execute("PRAGMA journal_mode=OFF"); con.execute("PRAGMA synchronous=OFF")

def parse_tuples(s):
    """Parse MySQL extended-insert VALUES payload: (a,b,'c'),(d,...) -> list[list]"""
    out=[]; i=0; n=len(s)
    while i<n:
        while i<n and s[i] in " \t\r\n,": i+=1
        if i>=n or s[i]!="(": break
        i+=1; row=[]; cur=[]; inq=False
        while i<n:
            c=s[i]
            if inq:
                if c=="\\":
                    nxt=s[i+1] if i+1<n else ""
                    cur.append({"n":"\n","t":"\t","r":"\r","0":"\0"}.get(nxt,nxt)); i+=2; continue
                if c=="'":
                    if i+1<n and s[i+1]=="'": cur.append("'"); i+=2; continue
                    inq=False; i+=1; continue
                cur.append(c); i+=1; continue
            if c=="'": inq=True; i+=1; continue
            if c==",": row.append("".join(cur)); cur=[]; i+=1; continue
            if c==")": row.append("".join(cur)); i+=1; break
            cur.append(c); i+=1
        out.append([None if v.strip()=="NULL" else v.strip() for v in row])
    return out

cols={}
cur_tbl=None; cur_cols=[]
buf=None; buf_tbl=None
inserted={}

with open(SRC, encoding="utf-8", errors="replace") as f:
    for line in f:
        if buf is None:
            m=re.match(r"CREATE TABLE `([a-z_0-9]+)`", line)
            if m:
                cur_tbl=m.group(1); cur_cols=[]; continue
            if cur_tbl:
                mc=re.match(r"\s+`([A-Za-z_0-9]+)`", line)
                if mc: cur_cols.append(mc.group(1)); continue
                if line.startswith(")"):
                    if cur_tbl in WANT:
                        cols[cur_tbl]=cur_cols
                        q=",".join(f'"{c}"' for c in cur_cols)
                        con.execute(f'CREATE TABLE "{cur_tbl}" ({q})')
                    cur_tbl=None; continue
            mi=re.match(r"INSERT INTO `([a-z_0-9]+)` VALUES ", line)
            if not mi: continue
            t=mi.group(1)
            if t not in cols: continue
            buf_tbl=t; buf=[line[mi.end():]]
            if not line.rstrip().endswith(";"): continue
        else:
            buf.append(line)
            if not line.rstrip().endswith(";"): continue
        payload="".join(buf).rstrip()
        if payload.endswith(";"): payload=payload[:-1]
        rows=parse_tuples(payload)
        c=cols[buf_tbl]; ph=",".join("?"*len(c))
        good=[r for r in rows if len(r)==len(c)]
        bad=len(rows)-len(good)
        if bad: print(f"  ! {buf_tbl}: {bad} arity-mismatch rows skipped", file=sys.stderr)
        con.executemany(f'INSERT INTO "{buf_tbl}" VALUES ({ph})', good)
        inserted[buf_tbl]=inserted.get(buf_tbl,0)+len(good)
        buf=None; buf_tbl=None

con.commit()
for t in sorted(inserted): print(f"{t:32} {inserted[t]:>8}")
con.close()
