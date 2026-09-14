"""lore.json -- a short piece of flavour for an item, shown under its name.

Henrik: "for named gear that has a background story to it, could you add some nice text
before the description/below the title of the item ... just to have a nice 'Ah, cool - i
didn't know this about this item' feeling."

Three sources, in priority order, and NONE of them is invented:

  1. ITEM_LORE   -- hand-written, for the seven legendaries and a few named items whose
                    story is the whole point of them.
  2. quest text  -- for a quest reward, the actual in-game quest text from
                    quest_template.Details, trimmed to its first sentence or two. This is
                    the canonical reason the item exists and it covers 100% of shipped
                    quest rewards.
  3. BOSS_LORE   -- for a boss drop, a note about the boss. 67 distinct bosses account for
                    all 275 shipped epic drops, so this is written once per boss rather
                    than once per item.

Anything not covered gets NO lore rather than a guess. A world drop off 358 creature types
has no story, and inventing one would be worse than leaving it blank.
"""
import sqlite3, json, re, collections

con=sqlite3.connect("tbc.db"); con.row_factory=sqlite3.Row
items=json.load(open("items.json")); srcs=json.load(open("sources.json"))

# ---------- 2. canonical quest text ------------------------------------------
qcols=[f"RewChoiceItemId{i}" for i in range(1,7)]+[f"RewItemId{i}" for i in range(1,5)]
sel=",".join(f"CAST({c} AS INT) {c}" for c in qcols)
QUEST={}
for r in con.execute(f"SELECT Title,Details,{sel} FROM quest_template"):
    for c in qcols:
        if r[c] and r[c] not in QUEST: QUEST[r[c]]=(r["Title"], r["Details"] or "")

def clean(t):
    t=re.sub(r"\$[Bb]", " ", t or "")          # $B is a line break
    t=re.sub(r"\$[NnRrCcGgGg]", "", t)         # $N is the player's name, etc.
    t=re.sub(r"\$\w+", "", t)
    t=re.sub(r"<[^>]*>", "", t)
    t=t.replace("’","'").replace("‘","'")
    t=re.sub(r"\s+", " ", t).strip()
    # Removing $N (the player's name) leaves the punctuation that framed it -- "thank you,
    # ." and "Well done, !". Tidy those rather than shipping them.
    t=re.sub(r"\s+([,;:.!?])", r"\1", t)
    t=re.sub(r",\s*([.!?])", r"\1", t)
    t=re.sub(r"([,;:])\s*\1+", r"\1", t)
    t=re.sub(r"\(\s*\)", "", t)
    return re.sub(r"\s+", " ", t).strip(" ,;:")

def first_sentences(t, maxlen=240):
    """One or two sentences, whole ones, under maxlen."""
    t=clean(t)
    if not t: return None
    parts=re.split(r"(?<=[.!?])\s+", t)
    out=""
    for p in parts:
        if not out: out=p
        elif len(out)+1+len(p)<=maxlen: out=out+" "+p
        else: break
        if len(out)>=140: break
    if len(out)>maxlen: return None
    # a line that is only an instruction ("Bring me 8 wolf pelts.") is not flavour
    if re.match(r"(?i)^(bring|return|speak|talk|go to|find|collect|kill|slay)\b", out) and len(out)<70:
        return None
    return out

from lore_data import ITEM_LORE, BOSS_LORE

STOP=set("the of and a an in on to for from with your you my his her their this that "
         "is are was were be been it its i we they them he she at by or if as but not no "
         "so then than there here what which who whom will would can could shall should".split())

def item_words(name):
    """The distinctive words in an item's name, for spotting it inside quest prose."""
    ws=re.findall(r"[A-Za-z']{4,}", name)
    return [w for w in ws if w.lower() not in STOP]

def quest_lore(iid, name):
    """Prefer the part of the quest that is about THIS ITEM.

    Henrik: "take bits of the quest input, but if it is not relevant in explaining the
    item's story just have the quest description as fallback." So look for a sentence that
    actually names the item -- that is the one carrying its story -- and only fall back to
    the opening of the quest when no sentence mentions it.
    """
    if iid not in QUEST: return None
    title, det = QUEST[iid]
    body = clean(det)
    if not body: return None
    words = item_words(name)
    if words:
        sents = re.split(r"(?<=[.!?])\s+", body)
        for i, snt in enumerate(sents):
            if any(re.search(r"\b"+re.escape(w)+r"\b", snt, re.I) for w in words):
                # the sentence about the item, plus the one before it for context
                chunk = " ".join(sents[max(0,i-1):i+1]) if i and len(sents[i-1])<120 else snt
                out = first_sentences(chunk)
                if out: return out
    return first_sentences(body)

def lore_for(iid):
    """Item's own story first, then the quest it came from, then the boss.

    Boss lore is LAST on purpose. The instructions line already says "Drops from
    Kel'Thuzad in Naxxramas", so leading with who Kel'Thuzad is spends the one interesting
    line on something already on screen.
    """
    if iid in ITEM_LORE: return ITEM_LORE[iid], "item"
    s=srcs[str(iid)]
    if s["sourceType"]=="quest_reward":
        t=quest_lore(iid, items[str(iid)]["name"])
        if t: return t, "quest"
    if s["sourceType"]=="boss_drop" and (s.get("npc") or "") in BOSS_LORE:
        return BOSS_LORE[s["npc"]], "boss"
    return None, None

def build():
    out={}; how=collections.Counter()
    for k in items:
        txt,src=lore_for(int(k))
        if txt: out[k]=txt; how[src]+=1
    json.dump(out, open("lore.json","w"), ensure_ascii=False, separators=(",",":"))
    return out, how

if __name__=="__main__":
    out,how=build()
    print(f"lore.json written: {len(out)} items  by source {dict(how)}")
    shipped=set()
    for c in ("paladin","warrior","hunter","druid","shaman","rogue","priest","warlock","mage"):
        g=json.load(open(c+".json"))
        for sp,v in g.items():
            for b in v["bands"]:
                for p in b["picks"][:3]: shipped.add(p["id"])
                for p in (b.get("notableEffects") or []): shipped.add(p["id"])
    n=collections.Counter(); sample=[]
    for i in sorted(shipped):
        s=srcs[str(i)]
        if s["sourceType"]!="quest_reward" or i not in QUEST: continue
        title,det=QUEST[i]
        txt=first_sentences(det)
        n["yes" if txt else "too long / not flavour"]+=1
        if txt and len(sample)<10: sample.append((items[str(i)]["name"], title, txt))
    print("quest-reward lore extraction:", dict(n))
    for nm,t,x in sample: print(f"\n  {nm}  <- {t!r}\n     {x}")
