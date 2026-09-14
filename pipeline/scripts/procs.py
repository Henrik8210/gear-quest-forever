"""
Proc valuation -- turning "Chance on hit: ..." into points.

Why this exists: a stat-weight model scores Thunderfury at 30 against a field
whose leaders sit at 115, because its printed stats are 5 Agility and 8 Stamina.
Every guide ranks it first in slot for a Prot paladin. The value is entirely in
the proc, so either procs get a number or the model is permanently wrong about a
whole class of items.

METHOD. Each proc is converted into the same currency the stat weights already
use -- points, where 1 point = 1 unit of the spec's primary stat -- by routing it
through one of three channels:

  damage      -> extra DPS      -> x the spec's dpsWeight (which is itself
                                   derived: 1 weapon dps = 4.31 Strength)
  stat buff   -> stat x uptime  -> x the spec's own weight for that stat
  mitigation  -> effective HP   -> x the spec's stamina weight / 10 HP per point

That routing is the whole trick: nothing here invents a new scale. A proc is
priced against the same yardstick as a point of Strength.

PROC RATE. TBC normalised weapon procs to procs-per-minute, and per-swing chance
is PPM * weapon_speed / 60 -- so PPM is speed-independent and is the right unit.
Where the text states a percentage we use it against the weapon's real swing
rate; otherwise we assume PPM_DEFAULT.

EVERY ASSUMPTION IS A NAMED CONSTANT BELOW. They are estimates, not sim output.
The test of whether they are sane is not whether they look reasonable, it is
whether the proc items the pros rank first actually rise -- reported by
proc_validate.py, which is a test and not a target.
"""
import re, json

# ---- scenario constants -----------------------------------------------------
PPM_DEFAULT      = 2.0    # weapon procs with no stated chance
FIGHT_SECONDS    = 45.0   # one levelling engagement; sets on-use cooldown value
SWING_1H         = 2.6
SWING_2H         = 3.4
# Expected weapon damage per swing for the level, used when the proc lives on an
# item that has no weapon of its own -- Hand of Justice is a trinket, so its extra
# attack has to be priced against whatever the player is swinging.
def scenario_swing_damage(level, twohand=False):
    return level*1.05*(SWING_2H if twohand else SWING_1H)
MELEE_SHARE      = 0.70
AOE_TARGETS      = 4.0    # typical adds hit by a chaining proc while levelling   # share of incoming damage that is melee (slows/parry only help here)
HP_PER_STA       = 10.0
# how much a mitigation proc is worth to each spec. A tank prices it fully; a
# leveller soloing prices it partly; nobody prices it at zero.
MIT_RELEVANCE    = {"protection":1.00,"retribution":0.35,"holy":0.35,"levelling_1_9":0.40}
# threat-only value (AoE threat, taunt-adjacent) matters to a tank and nobody else
THREAT_RELEVANCE = {"protection":1.00,"retribution":0.10,"holy":0.05,"levelling_1_9":0.15}

def player_hp(level):
    """Rough unbuffed plate-wearer health. Used only to price mitigation procs."""
    return 60 + level*55.0

STATWORDS = {
 "strength":"str","agility":"agi","stamina":"sta","intellect":"int","spirit":"spi",
 "attack power":"ap","haste rating":"haste","critical strike rating":"crit",
 "spell critical strike rating":"spellCrit","hit rating":"hit","dodge rating":"dodge",
 "parry rating":"parry","defense rating":"defense","block value":"blockValue",
 "armor":"armor","healing":"heal","damage and healing done by magical spells and effects":"sp",
 "spell damage":"sp","fire resistance":"resist","shadow resistance":"resist",
}

NUM = r"(\d[\d,]*)"
def n(x): return float(x.replace(",",""))

def classify(text):
    """One proc line -> list of (kind, params). A line can carry two effects:
    Thunderfury deals nature damage AND applies an attack-speed slow."""
    t=" ".join(text.split())
    low=t.lower()
    out=[]

    # A quest-scripted effect is not a combat effect. "Use: Use on Dar'Khan
    # Drathir ... causing 500 Arcane damage" only fires on one quest NPC, but the
    # damage parser read it as a general nuke and, at PPM_DEFAULT, priced it at
    # 116 points -- enough to put Sunwell Orb (a green +3 Intellect off-hand) at
    # rank 1 in a Horde warrior's off hand for every level from 1 to 19, and the
    # same for the paladin list that already shipped.
    if re.match(r"use:\s*use\b", low): return []

    on_use = low.startswith("use:")
    cd=None
    m=re.search(r"\((\d+)\s*(min|sec)[^)]*cooldown\)", low)
    if m: cd = n(m.group(1))*(60 if m.group(2)=="min" else 1)

    # stated proc chance
    pct=None
    m=re.search(r"(\d+)%\s*chance", low)
    if m: pct=n(m.group(1))/100.0

    # --- mitigation / control -------------------------------------------------
    # "slowing its attack speed by 20% for 12 sec" (Thunderfury) as well as
    # "reduces ... attack speed". Getting this wrong is what kept Thunderfury at
    # 30 points: the clause sits 230 characters into the tooltip and uses "slowing".
    m=re.search(r"(?:slow\w*|reduc\w*)[^.]{0,40}attack speed by (\d+)%(?:\s*for\s*(\d+)\s*sec)?", low)
    if m: out.append(("slow",{"pct":n(m.group(1))/100.0,
                              "dur":n(m.group(2)) if m.group(2) else 12.0}))
    m=re.search(r"stuns? (?:the )?target for ([\d.]+) sec", low)
    if m: out.append(("stun",{"dur":n(m.group(1))}))
    m=re.search(r"absorb\w*\s+"+NUM+r"(?:\s*to\s*"+NUM+r")?\s*(?:physical\s*)?damage", low)
    if m:
        a=n(m.group(1)); b=n(m.group(2)) if m.group(2) else a
        out.append(("absorb",{"amt":(a+b)/2,"cd":cd}))

    # --- extra attack ---------------------------------------------------------
    if re.search(r"extra attack", low):
        out.append(("extra_attack",{"pct":pct}))

    # --- life steal -----------------------------------------------------------
    m=re.search(r"steals? "+NUM+r"(?:\s*to\s*"+NUM+r")? (?:life|health)", low)
    if m:
        a=n(m.group(1)); b=n(m.group(2)) if m.group(2) else a
        out.append(("lifesteal",{"amt":(a+b)/2}))
        return out

    # --- damage over time -----------------------------------------------------
    m=re.search(NUM+r"(?:\s*to\s*"+NUM+r")? damage over (\d+) sec", low)
    if m:
        a=n(m.group(1)); b=n(m.group(2)) if m.group(2) else a
        out.append(("dot",{"amt":(a+b)/2,"dur":n(m.group(3)),"cd":cd,"onUse":on_use}))

    # --- direct damage --------------------------------------------------------
    m=re.search(r"(?:causing|causes|for|deal\w*|blasts?[^\d]{0,24}|bolt[^\d]{0,24})\s*"
                +NUM+r"(?:\s*to\s*"+NUM+r")?\s*(?:additional\s+)?"
                r"(?:arcane|fire|frost|nature|shadow|holy|physical)?\s*damage", low)
    if m and not any(k=="dot" for k,_ in out):
        a=n(m.group(1)); b=n(m.group(2)) if m.group(2) else a
        out.append(("dmg",{"amt":(a+b)/2,"cd":cd,"onUse":on_use}))

    # "grants the wielder 20 defense rating and 300 armor for 10 sec" (Quel'Serrar)
    mg=re.search(r"grants?[^.]{0,24}?\s"+NUM+r"\s+([a-z ]+?)(?:\s+and\s+"+NUM+r"\s+([a-z ]+?))?"
                 r"(?:\s+for\s+(\d+)\s*sec)", low)
    if mg:
        dur=n(mg.group(5))
        for amt,word in ((mg.group(1),mg.group(2)),(mg.group(3),mg.group(4))):
            if not amt: continue
            key=None
            for w,k in STATWORDS.items():
                if w in word.strip(): key=k; break
            if key: out.append(("stat_buff",{"stat":key,"amt":n(amt),"dur":dur,"cd":cd,"onUse":on_use}))

    # "All attacks are guaranteed to land and will be critical strikes for N sec"
    mc=re.search(r"guaranteed to land and will be critical strikes for the next (\d+) sec", low)
    if mc: out.append(("guaranteed_crit",{"dur":n(mc.group(1))}))

    # --- temporary stat buff --------------------------------------------------
    m=re.search(r"increas\w+\s+(?:your\s+)?(?:maximum\s+)?([a-z ]+?)\s+by "+NUM+r"(?:\s*for\s*(\d+)\s*sec)?", low)
    if m:
        word=m.group(1).strip()
        key=None
        for w,k in STATWORDS.items():
            if w in word: key=k; break
        if key:
            out.append(("stat_buff",{"stat":key,"amt":n(m.group(2)),
                                     "dur":n(m.group(3)) if m.group(3) else (10.0 if not on_use else 20.0),
                                     "cd":cd,"onUse":on_use}))
    # AoE threat: a chained/jumping proc is worth more to a tank than its damage
    if re.search(r"jump\w*\s+to\s+additional|nearby enemies|all enemies", low):
        out.append(("aoe_threat",{}))
    return out

def value(procs, item, spec, weights, dpsWeight, level, onUseOnly=False):
    """-> (points, [explanation lines])

    onUseOnly: the character never ATTACKS with this item, so only effects it can
    trigger on its own count. This is the ranged slot for everyone except a hunter:
    a rogue's bow is a stat stick, and "Chance to strike your ranged target" on a bow
    it never fires is worth nothing. A "Use:" line still counts -- that fires from
    the item, not from a shot.
    """
    if not procs: return 0.0, []
    speed = item.get("speed") or (SWING_2H if item.get("inv")==17 else SWING_1H)
    swings_min = 60.0/speed
    hp = player_hp(level)
    mit = MIT_RELEVANCE.get(spec,0.35); thr = THREAT_RELEVANCE.get(spec,0.1)
    wsta = weights.get("sta",0.25)
    total=0.0; why=[]

    def dmg_points(amount, per_min):
        dps = amount*per_min/60.0
        pts = dps*dpsWeight
        return pts, dps

    for line in procs:
        dmg_pts_this_line=[0.0]
        for kind,p in classify(line):
            if onUseOnly and not p.get("onUse"): continue
            if kind=="dmg" or kind=="dot":
                # An on-use nuke fires once per cooldown, not PPM_DEFAULT times a
                # minute. Electromagnetic Gigaflux Reactivator does 152-172 Nature
                # damage on a 30-MINUTE cooldown; charging it at 2 procs/min priced
                # it at 49 points, 98% of the item's whole score, and put a mail
                # helm's on-use nuke at rank 1 for a level-28 warrior. With no
                # cooldown stated, an on-use effect is assumed once per engagement.
                if p.get("onUse"):
                    rate = 60.0/max(p.get("cd") or FIGHT_SECONDS, 1.0)
                elif p.get("pct"):
                    rate = p["pct"]*swings_min
                else:
                    rate = PPM_DEFAULT
                pts,dps = dmg_points(p["amt"], rate)
                dmg_pts_this_line[0]+=pts
                total+=pts; why.append(f"{kind} {p['amt']:.0f} @ {rate:.1f}/min = {dps:.1f} dps -> {pts:.1f}")
            elif kind=="lifesteal":
                pts,dps = dmg_points(p["amt"], PPM_DEFAULT)
                heal = p["amt"]*PPM_DEFAULT/60.0
                surv = heal*FIGHT_SECONDS/HP_PER_STA*wsta*mit
                total+=pts+surv; why.append(f"lifesteal {p['amt']:.0f} -> {pts:.1f} dmg + {surv:.1f} surv")
            elif kind=="extra_attack":
                rate = (p.get("pct") or 0)*swings_min if p.get("pct") else PPM_DEFAULT
                swing = (item.get("dps") or 0)*speed or scenario_swing_damage(level)
                pts,dps = dmg_points(swing, rate)
                total+=pts; why.append(f"extra attack ({swing:.0f} dmg) @ {rate:.1f}/min -> {pts:.1f}")
            elif kind=="stat_buff":
                if p["onUse"]:
                    cd=max(p["cd"] or FIGHT_SECONDS, p["dur"])
                    up = min(1.0, p["dur"]/cd) if cd<=FIGHT_SECONDS else \
                         min(1.0, p["dur"]/FIGHT_SECONDS)*min(1.0,FIGHT_SECONDS/cd)
                else:
                    up = min(1.0, PPM_DEFAULT*p["dur"]/60.0)
                w = weights.get(p["stat"],0.0)
                pts = p["amt"]*up*w
                if p["stat"]=="sta": pts*=1.0
                total+=pts; why.append(f"{p['stat']} +{p['amt']:.0f} @ {up*100:.0f}% uptime -> {pts:.1f}")
            elif kind=="slow":
                # uptime from proc rate and duration, capped -- a 12s slow at 2 PPM
                # is up about 40% of the time, and re-procs keep it rolling
                up = min(0.85, PPM_DEFAULT*p.get("dur",12.0)/60.0 + 0.15)
                red = p["pct"]*MELEE_SHARE*up
                ehp = hp*red/max(1e-6,(1-red))
                pts = ehp/HP_PER_STA*wsta*mit
                total+=pts; why.append(f"attack-speed slow {p['pct']*100:.0f}% -> {ehp:.0f} effective hp -> {pts:.1f}")
            elif kind=="absorb":
                cd = p.get("cd") or FIGHT_SECONDS
                share = min(1.0, FIGHT_SECONDS/max(cd,1.0))   # uses per engagement
                ehp = p["amt"]*share
                pts = ehp/HP_PER_STA*wsta*mit
                total+=pts
                why.append(f"absorb {p['amt']:.0f} on {cd/60:.0f}min cd -> {share*100:.0f}% of a fight -> {pts:.1f}")
            elif kind=="stun":
                # A stun is worth nothing in this list. Bosses and most elites are
                # stun-immune, and Tidal Charm's own tooltip says "increased chance to
                # be resisted when used against targets over level 60" -- it is a PvP
                # trinket. Priced as damage avoidance it was worth 19.7 points, which
                # is the entire score of an item that has no stats at all, and 49.2
                # for Dark Iron Pulverizer's 8-second stun. Trash mobs can be stunned,
                # but that is not what a best-in-slot list is for.
                why.append(f"stun {p['dur']:.0f}s -> 0.0 (bosses are stun-immune; PvP effect)")
            elif kind=="guaranteed_crit":
                up = min(1.0, PPM_DEFAULT*p["dur"]/60.0)
                # 100% crit for the window: worth roughly one extra swing's damage
                # per swing during it, plus never missing
                dps_gain = (item.get("dps") or 0)*up
                pts = dps_gain*dpsWeight
                total+=pts; why.append(f"guaranteed crit {p['dur']:.0f}s @ {up*100:.0f}% uptime -> {pts:.1f}")
            elif kind=="aoe_threat":
                # worth (AOE_TARGETS - 1) extra instances of this line's own damage,
                # valued as threat rather than as damage
                pts = dmg_pts_this_line[0]*(AOE_TARGETS-1)*thr
                total+=pts
                why.append(f"hits ~{AOE_TARGETS:.0f} targets (AoE threat) -> {pts:.1f}")
    return total, why
