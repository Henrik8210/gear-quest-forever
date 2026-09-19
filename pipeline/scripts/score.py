"""Score every eligible item per class/spec/level/slot, take top 3, collapse to bands."""
import json, collections, re, sys, unicodedata, os
import procs as PROCS
import relic_score as RELIC

# One point of weapon DPS versus one point of Strength, for a paladin:
#   1 Strength = 2 attack power, which buys
#       white dps      2/14           = 0.143
#       seal dps       0.022 * 2      = 0.044   (Seal of Righteousness AP coefficient)
#       judgement dps  0.225 * 2 / 10 = 0.045   (10s cooldown)
#                                     = 0.232 dps
#   1 weapon DPS = 1.000 white dps
# so 1 weapon dps is worth 1/0.232 = 4.31 Strength, independent of weapon speed.
# The old hand-set dpsWeight of 1.75 for retribution was 2.5x too low, which let
# a rare with big crit rating (Blade of Misfortune, 68.8 dps) outrank the level-60
# PvP epics (Grand Marshal's Sunderer, 77.4 dps). Scaling by each spec's own
# Strength weight keeps the physics ratio intact inside that spec's scale.
DPS_PER_STR = 4.31

from gq_paths import G, GUIDES_DIR, OUT, forever_missing_ids, tbc_only_ids
FOREVER_MISSING = forever_missing_ids()
TBC_ONLY = tbc_only_ids()
NO_GUIDES = os.environ.get("GQ_NO_GUIDES") == "1"

# ilvl -> typical RequiredLevel, median over every item that states one.
ILVL_FLOOR = json.load(open(G+"ilvl_floor.json"))

items  = json.load(open(G+"items.json"))
rand   = json.load(open(G+"items_random.json"))
srcs   = json.load(open(G+"sources.json"))
W      = json.load(open(G+"weights.json"))

CLASS_BIT={"WARRIOR":1,"PALADIN":2,"HUNTER":4,"ROGUE":8,"PRIEST":16,"SHAMAN":64,
           "MAGE":128,"WARLOCK":256,"DRUID":1024}
RACE_BIT={"Human":1,"Orc":2,"Dwarf":4,"NightElf":8,"Undead":16,"Tauren":32,
          "Gnome":64,"Troll":128,"BloodElf":512,"Draenei":1024}
ALLIANCE=RACE_BIT["Human"]|RACE_BIT["Dwarf"]|RACE_BIT["NightElf"]|RACE_BIT["Gnome"]|RACE_BIT["Draenei"]
HORDE   =RACE_BIT["Orc"]|RACE_BIT["Undead"]|RACE_BIT["Tauren"]|RACE_BIT["Troll"]|RACE_BIT["BloodElf"]
FACTION_MASK={"Alliance":ALLIANCE,"Horde":HORDE}

# A class is not playable by every race on its faction, and that matters a lot at
# low level. A Horde paladin in TBC is a Blood Elf and nothing else, so Orc, Tauren,
# Troll and Undead starting quests are as unreachable to it as Alliance ones. Using
# the blanket faction mask put Durotar and Mulgore gear in a Blood Elf's list.
R=RACE_BIT
CLASS_RACES={
 "PALADIN":{"Alliance":R["Human"]|R["Dwarf"]|R["Draenei"], "Horde":R["BloodElf"]},
 "WARRIOR":{"Alliance":R["Human"]|R["Dwarf"]|R["NightElf"]|R["Gnome"]|R["Draenei"],
            "Horde":R["Orc"]|R["Undead"]|R["Tauren"]|R["Troll"]},
 "HUNTER" :{"Alliance":R["Dwarf"]|R["NightElf"]|R["Draenei"],
            "Horde":R["Orc"]|R["Tauren"]|R["Troll"]|R["BloodElf"]},
 "ROGUE"  :{"Alliance":R["Human"]|R["Dwarf"]|R["NightElf"]|R["Gnome"],
            "Horde":R["Orc"]|R["Undead"]|R["Troll"]|R["BloodElf"]},
 "PRIEST" :{"Alliance":R["Human"]|R["Dwarf"]|R["NightElf"]|R["Draenei"],
            "Horde":R["Undead"]|R["Troll"]|R["BloodElf"]},
 "SHAMAN" :{"Alliance":R["Draenei"], "Horde":R["Orc"]|R["Tauren"]|R["Troll"]},
 "MAGE"   :{"Alliance":R["Human"]|R["Gnome"]|R["Draenei"],
            "Horde":R["Undead"]|R["Troll"]|R["BloodElf"]},
 "WARLOCK":{"Alliance":R["Human"]|R["Gnome"], "Horde":R["Orc"]|R["Undead"]|R["BloodElf"]},
 "DRUID"  :{"Alliance":R["NightElf"], "Horde":R["Tauren"]},
}

# Faction-exclusive zones. The item and quest tables gate by race, but a vendor
# standing in Darnassus is not race-restricted -- the city is. Without this, a Blood
# Elf paladin's level 1-9 list was drawing on Darnassus, Northshire and Dun Morogh.
# Only the genuinely one-faction zones are listed; contested and Outland zones are
# reachable by both and stay absent.
ALLIANCE_ZONES={"Northshire Valley","Elwynn Forest","Dun Morogh","Coldridge Valley","Kharanos",
 "Teldrassil","Shadowglen","Darnassus","Ironforge","Stormwind City","Loch Modan","Westfall",
 "Darkshore","Redridge Mountains","Duskwood","Azuremyst Isle","Bloodmyst Isle","The Exodar",
 "Ammen Vale","Dustwallow Marsh - Theramore",
 "Honor Hold","Telaar","Temple of Telhamat","Wildhammer Stronghold","Sylvanaar",
 "Toshley's Station","Allerian Stronghold","Nesingwary's Expedition","Feathermoon Stronghold",
 "Nijel's Point","Refuge Pointe","Sentinel Hill","Lakeshire","Darkshire","Menethil Harbour",
 "Menethil Harbor","Southshore","Chillwind Camp","Booty Bay - Alliance","Astranaar",
 "Auberdine","Talrendis Point","Silverwind Refuge","Forest Song","Theramore Isle"}
HORDE_ZONES={"Valley of Trials","Durotar","Razor Hill","Orgrimmar","Mulgore","Camp Narache",
 "Thunder Bluff","Deathknell","Tirisfal Glades","Brill","Undercity","Silverpine Forest",
 "Eversong Woods","Sunstrider Isle","Ghostlands","Silvermoon City","Sen'jin Village","The Barrens",
 "Tranquillien","Thrallmar","Garadar","Falcon Watch","Shadowmoon Village","Zabra'jin",
 "Thunderlord Stronghold","Mok'Nathal Village","Camp Mojache","Hammerfall","Kargath",
 "Stonard","Grom'gol Base Camp","Brackenwall Village","Splintertree Post","Zoram'gar Outpost",
 "Valormok","Crossroads","Taurajo"}
# Faction-exclusive REPUTATIONS. A whole gate class that was missing: Batskin Belt
# requires "Tranquillien - Honored", Tranquillien is the Horde hub in the Blood Elf
# Ghostlands, and an Alliance paladin can never earn it -- but the item's allowRace is
# -1 and its zone string is the sub-zone "Tranquillien", which the zone list did not
# have. Same shape as R8 and R20: the restriction is one join away from the item row.
#
# Which reputations are exclusive is DERIVED by the mirror rule (R24): for each
# reputation, its best partner by shared (slot, ilvl, kind) keys, accepted only when
# the pairing is mutual and clearly ahead of the runner-up. That isolates exactly two
# pairs out of 20 reputations -- Honor Hold <-> Thrallmar at 16 mirrored keys against a
# next-best of 8, and Kurenai <-> The Mag'har at 5 with no closer partner. Every other
# Outland reputation is genuinely shared by both factions, which is why it has no
# strong mirror. Tranquillien has no mirror at all: it is a Horde levelling hub with no
# Alliance counterpart.
#
# The one hand-verified input is which SIDE each of the five is on -- five names, each
# checkable at a glance, exactly like the PvP quartermaster seed in pvp_prefix_faction.
REP_FACTION={
 "Honor Hold":"Alliance", "Kurenai":"Alliance",
 "Thrallmar":"Horde", "The Mag'har":"Horde", "Tranquillien":"Horde",
}
# Vendor-based faction gate. Better than the zone whenever a camp hosts BOTH sides'
# quartermasters -- "Mor'shan Base Camp" holds Illiyana Moonblaze (Alliance) and Kelm
# Hargunth (Horde), so putting that zone in a faction list gated Sentinel's Medallion
# out of Alliance AND out of Horde, leaving it nowhere. Derived, not asserted: a vendor
# is claimed for a side only when its entire prefix-identified stock is that side and
# there are at least three such items. 14 vendors qualify; none stock both sides.
#
# Caretaker's Cape is Alliance while Battle Healer's Cloak is Horde -- those are
# faction pairs sold by Illiyana vs Kelm. Rune of Duty (21567/21568) and Rune of
# Perfection (21565/21566) are the SAME item IDs on both sides; both quartermasters
# sell them. sources.json must not pin npc to Illiyana or npc_ok gates Horde out of
# the only trinkets available at 20-27.
NPC_FACTION=json.load(open(G+"npc_faction.json"))
def npc_ok(src, faction):
    side=NPC_FACTION.get(src.get("npc") or "")
    return side is None or side==faction

def rep_ok(it, faction):
    for r in (it.get("reqRep") or []):
        side=REP_FACTION.get(r[0] if isinstance(r,(list,tuple)) else r)
        if side and side!=faction: return False
    return True

def zone_ok(zone, faction):
    if not zone: return True
    if faction=="Horde"    and zone in ALLIANCE_ZONES: return False
    if faction=="Alliance" and zone in HORDE_ZONES:    return False
    return True

# armour proficiency: (allowed kinds, level at which the heaviest unlocks)
ARMOR_PROF={
 "WARRIOR":{"Cloth":1,"Leather":1,"Mail":1,"Plate":40,"Shield":1,"Buckler":1,"Misc":1},
 "PALADIN":{"Cloth":1,"Leather":1,"Mail":1,"Plate":40,"Shield":1,"Buckler":1,"Misc":1,"Libram":1},
 "HUNTER" :{"Cloth":1,"Leather":1,"Mail":40,"Misc":1},
 "SHAMAN" :{"Cloth":1,"Leather":1,"Mail":40,"Shield":1,"Buckler":1,"Misc":1,"Totem":1},
 "ROGUE"  :{"Cloth":1,"Leather":1,"Misc":1},
 "DRUID"  :{"Cloth":1,"Leather":1,"Misc":1,"Idol":1},
 "PRIEST" :{"Cloth":1,"Misc":1},
 "MAGE"   :{"Cloth":1,"Misc":1},
 "WARLOCK":{"Cloth":1,"Misc":1},
}
AC_SLOTS={"Head","Shoulder","Chest","Wrist","Hands","Waist","Legs","Feet"}
# Level at which the class learns Dual Wield. None = never. Without this gate any
# off-hand-only weapon (InventoryType 22) was a legal off-hand pick from its own
# RequiredLevel -- Left-Handed Brass Knuckles, RequiredLevel 10, sat at rank 1 in a
# level-10 warrior's off hand, ten levels before the character can equip it.
# Level at which the class learns Dual Wield. None = never. A dict value is per-spec:
# for a shaman it is not a class skill at all but an ENHANCEMENT TALENT, so an
# elemental or restoration shaman can never hold a weapon in the off hand however
# high its level. 30 is when 20 points of Enhancement -- the talent's depth -- is
# reachable.
DUAL_WIELD_LEVEL={"WARRIOR":20,"ROGUE":10,"HUNTER":20,
                  "SHAMAN":{"enhancement":30}}
def dual_wield_level(cls, spec):
    v=DUAL_WIELD_LEVEL.get(cls)
    if isinstance(v,dict): return v.get(spec)
    return v

ARMOR_SLOTS=["Head","Neck","Shoulder","Back","Chest","Wrist","Hands","Waist","Legs","Feet","Finger","Trinket"]
RATING_KEYS={"hit","crit","haste","expertise","defense","dodge","parry","blockRating",
             "resilience","spellHit","spellCrit","spellHaste","hitRanged","critRanged"}

def slot_for(it, cls):
    s=it["slot"]
    if s in ARMOR_SLOTS: return s
    if s in ("OneHand","TwoHand","MainHand"): return "MainHand"
    if s in ("OffHand","Held","Shield"): return "SecondaryHand"
    if s in ("Ranged","Thrown"): return "Ranged"
    if s=="Relic": return "Ranged"
    return None

def eff_req(it):
    """The level at which this item becomes eligible: its own RequiredLevel. Nothing else.

    This used to add an obtainability gate on top -- for a BoP item, the level of
    the creature that drops it, minus two. The intent was "you cannot realistically
    kill a level 63 boss at 55", but it was wrong twice over. It contradicted the
    ranking policy, which is pure stat score regardless of how gettable something
    is; and it silently delayed 3,748 BoP items past the level Wowhead says they
    are usable from. Might of Menethil (Requires Level 60, dropped by a level 63
    Kel'Thuzad) vanished from level 60 and reappeared at 61, which is exactly the
    discontinuity Henrik spotted at the 60/61 boundary.

    The fix is narrow on purpose. When an item states a RequiredLevel, that number
    is authoritative and nothing may push it later. But 1,400-odd items -- mostly
    quest rewards and raid epics -- carry RequiredLevel 0 in this DB, which does not
    mean "usable at level 1"; it means no requirement was recorded and something
    else does the gating. For those, and only those, the source gate still stands.
    Dropping it for everything made every level-1 band pick raid epics.

    Requirements that gate *obtaining* an item -- boss level, profession skill,
    reputation -- still travel with the pick as `src`, `reqSkills` and `reqRep`, so
    the addon can show them. For an item with a stated RequiredLevel they no longer
    move it to a later level."""
    r=it["rlvl"]
    if r>0:
        return r
    # No stated requirement. Wowhead agrees these are genuinely unrestricted --
    # 1,369 items of item level 60+ have no "Requires Level" line at all -- so a
    # level 1 character really could equip one if handed it. But most are Binds
    # when Picked Up, so the only real gate is reaching the source, and taking the
    # stated 0 at face value put an item level 55 chest (Hakkari Breastplate) at
    # rank 1 for level 1. Fall back to the source gate, backstopped by the typical
    # RequiredLevel of items at that item level -- the median over the ~28.5k items
    # that do state one, so it is measured rather than picked.
    return max(srcs[str(it["id"])].get("gateLevel") or 0, ILVL_FLOOR.get(str(it["ilvl"]), 0))

# PvP rank rewards are faction-exclusive, but the gate is the quartermaster, not the
# item: every one of these carries AllowableRace = -1, so Field Marshal's Plate Helm
# and Warlord's Plate Headpiece both sat in both factions' level-60 lists. Same shape
# as the class lock living on the quest (R8) -- the restriction is one join away from
# the item row.
#
# The side of each name family is DERIVED, not remembered: for every rank-set prefix,
# look at which quartermaster the world DB says sells it. A prefix is gated only when
# every vendor row for it is on one side. "Sergeant's" has items on both and is left
# ungated; "Knight's", "Commander's", "Corporal's" and "Senior Sergeant's" have no
# vendor row at all and are also left ungated. See pvp_prefix_faction.json.
PVP_PREFIX = json.load(open(G+"pvp_prefix_faction.json"))
_PVP_ORDER = sorted(PVP_PREFIX, key=len, reverse=True)
def pvp_side(name):
    for p in _PVP_ORDER:
        if name.startswith(p): return PVP_PREFIX[p]
    return None

def eligible(it, cls, spec, level, faction, prof, wsubs):
    src=srcs[str(it["id"])]
    if not src["obtainable"]: return False
    if it.get("temporary"): return False        # conjured / duration-limited, not gear
    nm=(it.get("name") or "").lower()
    if "test copy" in nm or "animation as" in nm:
        return False
    if eff_req(it)>level: return False
    ac=it["allowClass"]
    if ac not in (-1,0) and not (ac & CLASS_BIT[cls]): return False
    # Class lock carried by the quest that grants the item, not by the item itself.
    # Vanilla tier-3 pieces have AllowableClass 32767 ("anyone") but each is handed
    # over by a class-locked quest, so without this a paladin's list happily picked
    # Warrior, Druid, Hunter, Rogue, Priest and Shaman tier 3.
    qc=src.get("questClasses") or 0
    if qc and not (qc & CLASS_BIT[cls]): return False
    ar=it["allowRace"]
    mask=(CLASS_RACES.get(cls) or {}).get(faction, FACTION_MASK[faction])
    if ar not in (-1,0) and not (ar & mask): return False
    qr=src.get("questRaces") or 0
    if qr and not (qr & mask): return False          # captured all along, never used
    if not zone_ok(src.get("zone"), faction): return False
    side=pvp_side(it["name"])
    if side and side!=faction: return False
    if not rep_ok(it, faction): return False
    if not npc_ok(src, faction): return False
    if it["cls"]==4:                                     # armour / shield / relic
        need=prof.get(it["kind"])
        if need is None or level<need: return False
    else:                                                # weapon
        if it["kind"] not in wsubs: return False
    return True

# A stat that only applies against one creature type is not that stat. "Increases
# attack power by 60 when fighting Undead" was parsed as a flat +60 AP, which put
# Gauntlets of Undead Slaying at rank 1 on Hands at level 59 for both DPS specs --
# ahead of a guaranteed epic -- on a bonus that is zero against most of what you
# fight while levelling. Counted at a third, and the condition stays in the
# instruction text so the player can judge it. 41 items carry one.
CONDITIONAL_SHARE = 1/3.0

# A relic's effect names the ABILITY it buffs, and abilities belong to specs. Without
# this, ilvl ordering alone handed every paladin spec the same three healing librams
# and gave a Balance druid healing idols. Keywords are read off the effect text itself
# ("Increases healing done by Flash of Light", "Increases the damage of your Claw and
# Rake abilites"), not invented. A relic naming an ability the spec does not have is
# not eligible for that spec; one naming nothing recognised is kept, which is the
# conservative direction.
RELIC_ABILITIES={
 "PALADIN":{
   "holy":["Flash of Light","Holy Light","Cleanse","Blessing of Light","Holy Shock"],
   "protection":["Holy Shield","Devotion Aura","block","Consecration","Judgement","Judgment"],
   "retribution":["Seal","Judgement","Judgment","Crusader Strike","Exorcism","Holy Wrath",
                  "Consecration"]},
 "DRUID":{
   "restoration":["Rejuvenation","Healing Touch","Lifebloom","Regrowth","Tree of Life"],
   "feral":["Claw","Rake","Shred","Rip","Mangle","combo point","finishing move"],
   "bear":["Maul","Swipe","Lacerate","Mangle"],
   "balance":["Moonfire","Starfire","Wrath"]},
 "SHAMAN":{
   "restoration":["Lesser Healing Wave","Healing Wave","Chain Heal","Water Shield","Riptide"],
   "elemental":["Lightning Bolt","Chain Lightning","Earth Shock","Flame Shock","Frost Shock",
                "Shock"],
   "enhancement":["Stormstrike","Windfury","Shock"]},
}
def relic_ok(it, cls, spec):
    """True if this relic's effect names an ability the spec actually uses."""
    tbl=RELIC_ABILITIES.get(cls)
    if not tbl or spec not in tbl: return True
    text=" ".join(it.get("effects") or [])
    if not text: return True
    mine=[k for k in tbl[spec] if k.lower() in text.lower()]
    if mine: return True
    every=set()
    for v in tbl.values(): every.update(v)
    return not any(k.lower() in text.lower() for k in every)   # names nothing -> keep

STAT_LABEL={"sta":"Stamina","int":"Intellect","str":"Strength","agi":"Agility",
 "spi":"Spirit","ap":"Attack Power","heal":"Healing","sp":"Spell Damage and Healing",
 "sp_from_heal":"Spell Damage","spSchool":"Spell Damage","spHoly":"Holy Damage",
 "crit":"Crit Rating","spellCrit":"Spell Crit Rating","hit":"Hit Rating","haste":"Haste",
 "defense":"Defense Rating","dodge":"Dodge Rating","blockRating":"Block Rating",
 "mp5":"Mana per 5","resArcane":"Arcane Resist","resNature":"Nature Resist",
 "resFire":"Fire Resist","resFrost":"Frost Resist","resShadow":"Shadow Resist"}
def fmt_range(lo,hi):
    """'+11-13 Healing, +4-5 Spell Damage' -- what the roll can actually come out as,
    so the addon shows the range rather than implying the jackpot."""
    parts=[]
    for k,h in sorted(hi.items(), key=lambda kv:-kv[1]):
        l=lo.get(k,h)
        lbl=STAT_LABEL.get(k,k)
        parts.append("+%d %s"%(h,lbl) if l==h else "+%d-%d %s"%(l,h,lbl))
    return ", ".join(parts)

ROLL_POLICY="bestRoll"       # bestRoll | expectedValue | chanceFloor
CHANCE_FLOOR=1.0             # used by chanceFloor policy (% for the whole suffix family)

def best_variant(it, w, level, rscale):
    """-> (score, suffixName or None, chance or None, statsUsed)

    No level scaling on rating stats. Ratings do buy more percent at low level,
    but the relative value of a primary stat point rises even faster there (base
    weapon damage and attack power are tiny), so scaling only ratings made them
    wildly overvalued below 60. Keeping every weight level-invariant is both
    simpler and closer to the truth.
    """
    base=it["stats"]
    def sc(st):
        t=0.0
        for k,v in st.items():
            wt=w.get(k,0.0)
            if not wt: continue
            t+= v*wt
        return t
    bs=sc(base)
    vs=rand.get(str(it["id"]))
    if not vs: return bs, None, None, base, None, bs, None, None
    if ROLL_POLICY=="expectedValue":
        ev=bs; tot=0.0
        for v in vs:
            merged=dict(base)
            for k,x in v["stats"].items(): merged[k]=merged.get(k,0)+x
            ev+= (sc(merged)-bs)*v["chance"]/100.0; tot+=v["chance"]
        return ev, "<random roll>", round(tot,2), base, round(tot,2), ev, None, None
    # RANK on the expected roll, DISPLAY the best one.
    #
    # bestRoll alone made every random-enchantment item compete at its jackpot against
    # fixed items competing at their actual stats. "Vice Grips of Strength" (+20 Str,
    # a 7.9% roll) outranked Edgemaster's Handguards -- a guaranteed epic with 19 hit
    # and 17 expertise -- on Hands for every level from 44 to 55. Henrik's rule is that
    # ranking ignores *obtainability*, not that it assumes luck: the stat score of a
    # random-enchant item is what you get on average, and the jackpot is the hunt
    # target, which is what the suffix and chance columns are for.
    #
    # Chances sum to ~100% per item in the Wowhead scrape (median exactly 100), so the
    # expectation is well defined. Where they fall short the missing mass is treated as
    # the base item with no suffix, which is the conservative reading.
    # Each suffix is itself a RANGE, not a number: Wowhead prints "of Healing" on
    # Shimmering Sash as "+(11 - 13) Healing Spells and +(4 - 5) Damage Spells", one
    # suffix spanning an item-level band. Henrik looted that exact item and it rolled
    # 11. So the expected roll uses the MIDPOINT of the range and the hunt target uses
    # the TOP -- previously both used the top, which assumed a best-case roll inside
    # the suffix as well as across suffixes. 35% of the 17,789 variants have a real
    # range, so this is not cosmetic.
    best=None; ev=bs; tot=0.0
    for v in vs:
        if ROLL_POLICY=="chanceFloor" and (v.get("chanceAny") or 0)<CHANCE_FLOOR: continue
        hi=v["stats"]; lo=v.get("statsMin") or hi
        mid={k:(hi[k]+lo.get(k,hi[k]))/2.0 for k in hi}
        mMid=dict(base); mHi=dict(base)
        for k,x in mid.items(): mMid[k]=mMid.get(k,0)+x
        for k,x in hi.items():  mHi[k]=mHi.get(k,0)+x
        ch=v.get("chance") or 0.0
        ev += (sc(mMid)-bs)*ch/100.0; tot+=ch
        s2=sc(mHi)
        if best is None or s2>best[0]: best=(s2,v["suffix"],v["chance"],mHi,v.get("chanceAny"),lo,hi,v.get("suffixId"))
    if not best or ev<=bs: return bs, None, None, base, None, bs, None, None
    # score = expected; suffix/chance/stats = the best roll, for the hunt;
    # 6th = what the jackpot roll would score, used to surface the hunt target on the
    # notable shelf when the average roll does not make the top 3;
    # 7th = the printable range, so the addon shows "+11-13 Healing" not just "13".
    return ev, best[1], best[2], best[3], best[4], best[0], fmt_range(best[5],best[6]), best[7]

# ---------------------------------------------------------------------------
# Obtainability exclusions. Built by obtainability.py, which traces each item's
# acquisition chain in the world DB and reports dead ends. Two tiers:
#
#   AUTO -- items whose ONLY source is a quest titled "BETA ..." / "TEST ...".
#           Unambiguous test content; excluded without review.
#   HAND -- craft dead ends (a pattern item exists but drops from nothing). This
#           rule is right but not perfectly reliable, because npc_vendor and
#           npc_trainer in this DB are incomplete. Every one is checked against
#           Wowhead before being added here.
#
# Verified against Wowhead, kept OUT:
#   15141 Onyxia Scale Breastplate  -- "This item is not available to players"
#    6730 Ironforge Chain           -- "the actual recipe ... is no longer available"
#    2867 Rough Bronze Bracers      -- "no way to make or find this item. A way to
#                                       learn the recipe was never made"
# Verified against Wowhead, kept IN (do NOT add):
#    7929 Orcish War Leggings       -- plans come from the Horde quest "The Old Ways"
#                                       in Orgrimmar; this world DB is missing that
#                                       quest reward, so the audit flagged it wrongly.
#   10020 Stormcloth Vest           -- inconclusive; only player speculation. Left in
#                                       and surfaced in the review page instead.
HAND_EXCLUDED={15141, 6730, 2867}

def load_exclusions():
    try: ob=json.load(open("obtainability.json"))
    except FileNotFoundError:
        print("  !! obtainability.json missing -- NO exclusions applied"); return set(), {}
    auto={int(k) for k in ob.get("questDeadEnd",{})}
    reasons={}
    for k,v in ob.get("questDeadEnd",{}).items(): reasons[int(k)]=v
    for i in HAND_EXCLUDED: reasons.setdefault(i,"verified unobtainable on Wowhead")
    ex=auto|HAND_EXCLUDED
    # never exclude something that also has a real source
    reach=ob.get("sources",{})
    ex={i for i in ex if str(i) not in reach or i in HAND_EXCLUDED}
    flagged={int(k):v for k,v in ob.get("craftDeadEnd",{}).items() if int(k) not in ex}
    print(f"  obtainability: excluding {len(ex)} items ({len(auto)} test-quest, {len(HAND_EXCLUDED)} hand-verified); "
          f"{len(flagged)} craft dead-ends flagged for review, not removed")
    return ex, flagged

EXCLUDED, FLAGGED = load_exclusions()

def slug(s):
    s=unicodedata.normalize("NFKD",s).encode("ascii","ignore").decode()
    return re.sub(r"_+","_",re.sub(r"[^a-z0-9]+","_",s.lower())).strip("_")

def run(cls, spec_key, levels=range(1,70), factions=("Alliance","Horde")):
    cfg=W[cls][spec_key]
    w=dict(cfg["weights"]); style=cfg["weaponStyle"]; dpsW=cfg.get("dpsWeight",0.0)
    w["apVs"]=w.get("ap",0.0)*CONDITIONAL_SHARE
    # Defaults to 0, NOT to the melee weight. Warrior carried no dpsWeightRanged key,
    # so it silently inherited dpsWeight -- a warrior's gun was scored as though its
    # damage mattered as much as its axe's. A ranged weapon is a stat stick for every
    # class but the hunter, so a class that really fights with it must say so.
    dpsWRanged=cfg.get("dpsWeightRanged", 0.0)
    mhKinds=set(cfg["mainHandKinds"]) if cfg.get("mainHandKinds") else None
    prof=ARMOR_PROF[cls]; wsubs=set(W[cls]["_weaponSubclasses"])
    notable={}; full60={}
    armorClass=cfg.get("armorClass") or {}
    pool=[it for it in items.values() if slot_for(it,cls) and it['id'] not in EXCLUDED]
    pool=[it for it in pool if it["id"] in CLASSIC_IDS and it["id"] not in TBC_ONLY]
    per={}
    for faction in factions:
        for level in levels:
            rscale=70.0/max(1,level)
            buckets=collections.defaultdict(list)
            for it in pool:
                if not eligible(it,cls,spec_key and spec_key or "",level,faction,prof,wsubs): continue
                sl=slot_for(it,cls)
                if sl=="MainHand":
                    # A spec whose core abilities REQUIRE a weapon type. Backstab,
                    # Ambush and Mutilate are dagger-only, so an assassination or
                    # subtlety rogue holding a sword loses its whole rotation -- a
                    # hard mechanical gate, like plate proficiency, not a preference.
                    if mhKinds and it["kind"] not in mhKinds: continue
                    twoh = it["inv"]==17
                    if style=="twohand" and not twoh and level>=20: continue
                    if style in ("onehand_shield","onehand_dual") and twoh: continue
                if sl=="SecondaryHand":
                    dw=dual_wield_level(cls,spec_key)
                    canDW = dw is not None and level>=dw
                    if it["cls"]==2 and it["inv"] in (13,22):
                        if not canDW: continue
                    # InventoryType 23 is "Held In Off-hand" -- an orb, tome or stein.
                    # Any class can equip one, but it DISABLES off-hand attacks, so for
                    # anyone who can dual wield it is strictly worse than a weapon.
                    # Henrik found Ritual Stein of the Wolf (+3 Agi, +3 Spi) sitting in
                    # a rogue's off hand; the hunter off hand was 189 of these against
                    # zero one-handers. Casters keep them -- a shaman holding an orb is
                    # real -- because they never make an off-hand attack anyway.
                    if it["inv"]==23 and canDW: continue
                    # Two-hand specs still get a shield list: the log has an Off Hand
                    # row, and a warrior/paladin can swap to a shield. Skipping the
                    # whole slot left Arms/Ret empty from 20 up.
                    if style=="twohand" and level>=20 and it.get("kind") not in ("Shield","Buckler"):
                        continue
                    # Fury dual-wields: the off hand holds a second one-hander, not a
                    # shield. Without this the off-hand list fills with shields, which a
                    # Fury warrior would never equip.
                    # Dual Wield is a level-20 skill. Below 20 a Fury-spec warrior
                    # still holds a shield in the off hand, so excluding shields there
                    # left the list to caster held-in-off-hand junk (Buccaneer's Orb,
                    # Ritual Stein) scoring 1.4 against a shield's 20+.
                    if style=="onehand_dual" and level>=20 and it.get("kind")in("Shield","Buckler"): continue
                s,suf,ch,st,chAny,sBest,srange,sid=best_variant(it,w,level,rscale)
                _roll_gain=sBest-s
                # Armour-class preference. A multiplier, never a filter: Protection strongly
                # favours plate, Retribution mildly, Holy is near-indifferent and will take
                # cloth when the stats are better. This was described in the review page from
                # the start but was never actually wired in -- armorClass was None for every
                # spec -- so until now only the raw `armor` stat weight distinguished them,
                # which is far too weak: plate vs leather at level 60 is ~200 armour, worth
                # 3 points to Retribution, nothing against a tier set's stat budget. That is
                # why Hunter and Rogue tier 3 were outranking Paladin tier 2.
                # Only the eight slots that actually have an armour class. Back, Neck,
                # Finger, Trinket and Ranged have none -- every class wears the same
                # cloth cloak -- so applying the Cloth multiplier to a cloak was
                # wrong. It was ranking-neutral (a uniform factor inside one slot,
                # and Back is the only non-armour slot whose kind is in the table),
                # but it made cloak scores look 5x smaller than they are.
                if sl in AC_SLOTS:
                    s *= armorClass.get(it.get("kind"), 1.0)
                # Weapon damage is worth different amounts in different hands. For a
                # hunter the RANGED weapon is the weapon -- Auto Shot and Steady Shot
                # both scale off it -- while the melee weapon is a stat stick whose
                # damage is never dealt. One dpsWeight for both would either price a
                # bow like a sword or a sword like a bow. dpsWeightRanged defaults to
                # dpsWeight, so classes that do not care are unaffected.
                if it["cls"]==2:
                    dw = dpsWRanged if sl=="Ranged" else dpsW
                    # Dual Wield halves off-hand weapon damage, and that applies to
                    # ANY weapon swinging in the off hand -- not only the one-handers
                    # duplicated there from the main-hand pool. InventoryType 22
                    # weapons (off-hand ONLY) reach this slot through slot_for, so
                    # they were being paid full weapon dps for a swing that lands at
                    # half. Shekketh Talons -- 47.9 dps, no stats at all -- scored
                    # 718 and displaced The Hungering Cold (73.0 dps, 14 stamina,
                    # 14 expertise) in every rogue spec's off hand, and the same
                    # error inflated every off-hand-only weapon for fury warriors.
                    if sl=="SecondaryHand": dw*=0.5
                    if dw: s+= it["dps"]*dw
                # Proc value, in the same points currency. See procs.py for the
                # channels (damage -> dps -> dpsWeight, stat buff -> stat x uptime,
                # mitigation -> effective hp -> stamina weight) and for every
                # scenario constant. Without this, any item whose worth is a proc --
                # Thunderfury, Flurry Axe, Hand of Justice, Felstriker -- is scored
                # as though the proc did not exist.
                #
                # The weight passed in must be the one for the hand the item is
                # actually swung in, and a proc that fires on an attack is worth
                # nothing to someone who never makes that attack.
                #
                # Henrik: "rogues doesn't need the damage on the ranged, they just
                # need stats so ranged procs etc. is not relevant for rogues on the
                # ranged. It can be for hunters of course as that is their main
                # weapon." Exactly right, and it was wrong twice over: the Ranged
                # slot was passing the MELEE dpsWeight into the proc model, so
                # Venomstrike's "Chance to strike your ranged target with a Venom
                # Shot" was priced for a rogue at dpsWeight 15.0 -- the weight of a
                # weapon it swings every 1.4 seconds -- for a bow it never fires.
                # For anyone but a hunter the ranged slot is a stat stick, so an
                # on-attack proc there scores zero. A Use: effect still counts:
                # it fires from the item, not from a shot.
                pr=it.get("procs")
                if pr:
                    procDw = dpsWRanged if sl=="Ranged" else dpsW
                    # NOT halved for the off hand. Dual Wield halves the weapon's
                    # own swing damage, but a proc that deals 100 damage deals 100
                    # damage whichever hand triggered it, and how often it triggers
                    # is already carried by the item's speed inside procs.py.
                    #
                    # Generalised: if the spec's dps weight for THIS slot is zero,
                    # the character does not attack with the item at all, so nothing
                    # that triggers on an attack can fire. That is the ranged slot
                    # for everyone but a hunter, the melee slots for a hunter (who
                    # never swings), and both weapon hands for a druid (weapon procs
                    # do not fire in cat or bear form) and for an elemental or
                    # restoration shaman. It matters beyond damage procs: a
                    # "Chance on hit: +30 Strength for 8 sec" line is priced by
                    # uptime x stat weight, not by dpsWeight, so it was scoring in
                    # full on weapons that are never swung.
                    onUseOnly = (sl in ("Ranged","MainHand","SecondaryHand")
                                 and not procDw)
                    pp,_=PROCS.value(pr,it,spec_key,w,procDw,level,onUseOnly=onUseOnly)
                    s+=pp
                # RELICS: Totem, Idol, Libram. 108 of them in the dataset and only
                # TWO carry a single stat -- their whole value is an effect line
                # ("Increases healing done by Lesser Healing Wave by up to 80"),
                # which a stat-weight model cannot price at all. Scoring them
                # normally gave every one of them 0, and `if s<=0: continue` then
                # deleted the entire slot: paladin, druid AND shaman all shipped
                # with an empty relic slot and nothing flagged it, because the
                # guide-agreement denominator only counts slots that produced a band.
                #
                # Relics improve strictly within a spell line, so ITEM LEVEL is a
                # genuinely good ordering for them, and at 60 the guide decides.
                # The score is deliberately tiny -- it is an ordering key, not a
                # value -- and scores are only ever compared inside one slot.
                if it["cls"]==4 and it["kind"] in ("Totem","Idol","Libram"):
                    if not relic_ok(it,cls,spec_key): continue
                    rs = RELIC.score_relic(it, cls, spec_key, w)
                    if rs > 0:
                        s = rs
                    elif s <= 0:
                        s = it["ilvl"] * 0.01
                if s>0: buckets[sl].append((s,it,suf,ch,st,chAny,s+_roll_gain,srange,sid))

                # A one-hander (InventoryType 13) can be held in EITHER hand. slot_for
                # returns one slot per item, so every inv-13 weapon was MainHand-only
                # and the off-hand pool was limited to the handful of items flagged
                # off-hand-only (inv 22). For a dual-wielding Fury warrior that is
                # almost the whole candidate pool missing: the guide's own off-hand
                # list is inv-13 swords and axes (The Hungering Cold, The Castigator,
                # Iblis, Maladath). Give the off hand its own copy of every one-hander.
                #
                # Off-hand weapon damage is halved by Dual Wield, so only the weapon's
                # dps contribution is scaled by 0.5 -- its stats and its procs are
                # worth the same in either hand. Dual wield itself is a level-20 skill.
                # Previously gated on style=="onehand_dual", which meant a hunter --
                # style twohand_or_onehand, because its guide offers both -- never got a
                # single one-hander in the off hand. The right condition is simply
                # "can this class dual wield at this level", whatever its main-hand style.
                # ...but only for a spec that would actually put a WEAPON there.
                # "can this class dual wield" alone was too broad: a protection
                # warrior can dual wield mechanically, so one-handers appeared on its
                # off-hand notable shelf, where the answer is always a shield.
                _dw=dual_wield_level(cls,spec_key)
                if (it["inv"]==13 and it["cls"]==2 and _dw is not None and level>=_dw
                        and style in ("onehand_dual","twohand_or_onehand")):
                    # s was built with the MAIN-hand weight; rebuild the dps part
                    # at the off-hand rate so both routes into SecondaryHand agree.
                    s2=s - (it["dps"]*dpsW if dpsW else 0.0)*0.5
                    if s2>0: buckets["SecondaryHand"].append((s2,it,suf,ch,st,chAny,s2+_roll_gain,srange,sid))
            for sl,rows in buckets.items():
                rows.sort(key=lambda r:(-r[0], r[1]["id"]))
                if sl == "Ranged":
                    rows = promote_hunter_ranged_proc(rows, cls)
                # Best item in this slot whose value is an effect the score cannot
                # price, when it did not make the top 3 on stats alone. Thunderfury
                # prints 5 Agility and 8 Stamina and scores 30.9 against a 118-point
                # field, yet Wowhead's tank guide ranks it first in slot for the proc.
                # We do not invent a number for the proc -- we surface the item next to
                # the top 3 and let the player judge.
                # search the whole slot, not just the top 8 we keep, or a proc item
                # scoring 30 against a 118-point field is never even considered
                # Keep the COMPLETE level-60 list. The override matches guide items by
                # name, and truncating to 8 hid any guide pick the model ranked 9th or
                # worse -- which is exactly the case for the items whose value is a
                # proc or a set bonus. Hand of Justice, Onyxia Tooth Pendant and
                # Wristguards of True Flight were all eligible and all invisible.
                if level==60: full60[(faction,sl)]=list(rows)
                rows=unique_name_rows(rows, 8)
                top3={r[1]["id"] for r in rows[:3]}
                top3_names={r[1]["name"] for r in rows[:3]}
                nb=[r for r in rows if r[1].get("effectDriven")
                    and r[1]["id"] not in top3 and r[1]["name"] not in top3_names
                    and r[1]["quality"]>=3][:2]
                # Random-enchantment hunt targets. Ranking moved to the EXPECTED roll,
                # which is right for "what should I wear" and wrong for "what should I
                # chase": War Torn Tunic "of Strength" is a 9.5% roll that beats
                # everything at level 13 when it lands, and averaging dropped it out of
                # the top 3 entirely. If the jackpot WOULD have made the top 3, the item
                # belongs on the notable shelf with its suffix and chance.
                cut = rows[2][0] if len(rows)>=3 else 0.0
                shown={r[1]["id"] for r in rows[:3]} | {r[1]["id"] for r in nb}
                shown_names=set(top3_names) | {r[1]["name"] for r in nb}
                nb += [r for r in rows
                       if r[2] and len(r)>6 and r[6]>cut and r[1]["id"] not in shown
                       and r[1]["name"] not in shown_names][:1]
                shown |= {r[1]["id"] for r in nb}
                shown_names |= {r[1]["name"] for r in nb}
                # Forever-only item that almost made the unique top 3 (A Bigger Shield
                # vs Aegis of Stormwind is a 0.2-point miss). Surface it once as notable.
                if cut and len(nb)<2:
                    near=[r for r in rows
                          if r[1]["id"]>=200000 and r[1]["id"] not in shown
                          and r[1]["name"] not in shown_names
                          and r[1]["quality"]>=3 and r[0]>=cut*0.98][:1]
                    nb += near
                notable[(faction,level,sl)]=nb
                per[(faction,level,sl)]=rows[:8]
    return per,cfg,notable,full60

# ---------------------------------------------------------------------------
# Level-60 override.
#
# At exactly level 60 we do not trust the model. Wowhead's Classic-era BiS guides
# for all three paladin specs are the work of people who sim and raid this content,
# and they encode things a stat-weight model structurally cannot see: tier set
# bonuses, proc quality (a world-class proc versus a mediocre one), threat
# mechanics, and hit/defense caps. procs.py narrowed that gap -- Thunderfury went
# from 30.9 to 92.2 for Protection -- but it did not close it, and inflating the
# constants until it did would be fitting the answer rather than deriving it.
#
# So at 60 the guide's order wins, and the model only gets a say when it disagrees
# by a wide margin -- Henrik's "as long as nothing in TBC can take a spot in the
# race". A non-guide item must beat the guide's own top pick by DISPLACE_MARGIN to
# claim a slot, which is deliberately hard: these guides are Classic-era, so a TBC
# item genuinely unavailable to their authors is exactly what should be able to win.
#
# Every displacement is logged. Slots the guides do not cover keep the model's
# answer, and so does every level other than 60.
DISPLACE_MARGIN = 0.20
# Only an item that did not exist in Classic may displace a guide entry. This is
# Henrik's rule taken literally: "as long as nothing in TBC can take a spot in the
# race". The guides' authors were looking at the whole of Classic itemisation, so
# when they ranked Avenger's Breastplate above Plated Abomination Ribcage -- buying
# the tier-2 set bonus my model cannot see -- that is a considered judgement and it
# stands. A TBC item is different: they never saw it.
# Membership from the cmangos Classic 1.12 world DB, 17,718 ids, spot-checked both
# directions (Thunderfury and Wraith Blade classic; King's Defender and Gronn-Bone
# Club not).
CLASSIC_IDS = set(json.load(open(G+"classic_item_ids.json")))
GUIDEFILE = os.path.join(GUIDES_DIR, os.environ.get("GQ_GUIDES","guides.json"))
GUIDES = json.load(open(GUIDEFILE)) if os.path.exists(GUIDEFILE) else {}
_displaced=[]

def guide_tiers(gl):
    """A guide list is either bare names (positional ranking, the old paladin format)
    or [tier, name] pairs carrying the guide's own Rank column. Returns
    (ordered_names, {name: tier}); tier is None for the positional format."""
    if gl and isinstance(gl[0],(list,tuple)):
        return [n for _,n in gl], {n:t for t,n in gl}
    return list(gl), None

def guide_override(spec, sl, faction, rows, cls):
    """rows = scored candidates at level 60. -> (picks, origins) or None."""
    gl=(GUIDES.get(spec) or {}).get(sl)
    if not gl: return None
    names, tiers = guide_tiers(gl)
    by={r[1]["name"]:r for r in rows}
    guide=[by[n] for n in names if n in by]
    if not guide: return None
    # With a Rank column, the tier is the guide's judgement and the order inside a
    # tier is not. Wowhead lists The Hungering Cold and Thunderfury both as "Best"
    # main-hand swords; taking them in printed order put Thunderfury second even
    # though it outscores the other by 15%. Sort by (tier, -score) so the guide
    # decides the tier and the model breaks the tie it never made.
    if tiers:
        guide.sort(key=lambda r:(tiers[r[1]["name"]], -r[0], r[1]["id"]))
    other=[r for r in rows if r[1]["name"] not in set(names)]
    picks=list(guide); origin=["guide"]*len(picks)
    other=[r for r in other if r[1]["id"] not in CLASSIC_IDS]
    # The bar is the BEST-SCORING item the guide lists in this slot, not whichever
    # one it happened to rank first. Measuring against guide[0] made the test
    # trivially easy whenever the guide's top pick is an item the model underprices:
    # Kiss of the Spider's whole value is a 20%-attack-speed on-use, which scores
    # 12.2 for Protection, so a 20% margin over *that* let TBC items in even when
    # another item on the same guide list scored four times higher. Mark of the
    # Champion scores 82.5 for Fury -- more than the displacer did.
    gbest = max(guide, key=lambda r:r[0])
    if other and guide and other[0][0] > gbest[0]*(1+DISPLACE_MARGIN):
        picks.insert(0, other[0]); origin.insert(0,"model")
        _displaced.append((spec,sl,faction,other[0][1]["name"],round(other[0][0],1),
                           gbest[1]["name"],round(gbest[0],1)))
        other=other[1:]
    while len(picks)<3 and other:
        picks.append(other[0]); origin.append("model"); other=other[1:]
    picks, origin = unique_name_pairs(picks, origin, 3)
    while len(picks)<3 and other:
        name=other[0][1]["name"]
        if name not in {r[1]["name"] for r in picks}:
            picks.append(other[0]); origin.append("model")
        other=other[1:]
    return picks[:3], origin[:3]

def promote_hunter_ranged_proc(rows, cls):
    """Ranged proc weapons (Heartseeking Crossbow) often lose to high listed DPS on
    Forever-indexed bows whose tooltips we trust less than a classic proc BiS. When
    a proc-driven ranged weapon is still in the top 8 and within 15% of the leader,
    promote it to rank 1 so it ships in picks, not as a notable."""
    if cls != "HUNTER" or not rows or len(rows) < 4:
        return rows
    lead = rows[0][0]
    if lead <= 0:
        return rows
    floor = lead * 0.85
    for i, r in enumerate(rows):
        if i < 3:
            continue
        it = r[1]
        if not it.get("effectDriven") or not it.get("procs"):
            continue
        if r[0] < floor:
            continue
        return [r] + [x for j, x in enumerate(rows) if j != i]
    return rows

def unique_name_rows(rows, n=3):
    """Keep the best-scoring id per display name so PvP rank twins do not eat the list."""
    seen=set(); out=[]
    for r in rows:
        if r[1]["id"] in FOREVER_MISSING:
            continue
        name=r[1]["name"]
        if name in seen:
            continue
        seen.add(name)
        out.append(r)
        if len(out)>=n:
            break
    return out

def unique_name_pairs(picks, origins, n=3):
    seen=set(); out_p=[]; out_o=[]
    for r, o in zip(picks, origins):
        if r[1]["id"] in FOREVER_MISSING:
            continue
        name=r[1]["name"]
        if name in seen:
            continue
        seen.add(name)
        out_p.append(r); out_o.append(o)
        if len(out_p)>=n:
            break
    return out_p, out_o


# Two-hander, or one-hander plus off-hand? For any spec that can legally do both, the
# model ranks MainHand and SecondaryHand independently, so it can name a staff as the
# best main hand AND an off-hand item as the best off hand -- a pair you cannot equip.
# Henrik: over three quarters of caster main-hand picks are staves, so this is the common
# case for priest, warlock and mage, and it is the two-hand-versus-dual-wield question
# for a hunter or an enhancement shaman.
#
# The lists stay as they are -- each slot still answers "what is the best item for this
# slot". What is added is which ROUTE wins, so the addon can grey the row that does not
# apply instead of showing an impossible combination.
AMBIGUOUS_STYLES = {"twohand_or_onehand"}

def route_for(per, faction, level):
    """-> (route, twoHandScore, pairScore) or None when the question does not arise."""
    mh = per.get((faction, level, "MainHand")) or []
    oh = per.get((faction, level, "SecondaryHand")) or []
    if not mh:
        return None
    two = max([r[0] for r in mh if r[1]["inv"] == 17], default=None)
    one = max([r[0] for r in mh if r[1]["inv"] != 17], default=None)
    off = max([r[0] for r in oh], default=0.0)
    # If only one route appears among the candidates at all, that IS the answer -- it
    # means nothing of the other kind scores well enough to reach the list. Returning
    # "no opinion" here left priest holy without a route for thirteen straight levels.
    if two is None and one is None: return None
    if one is None: return "twohand", round(two,2), None
    if two is None: return "onehand", None, round(one+off,2)
    pair = one + off
    return ("twohand" if two >= pair else "onehand"), round(two, 2), round(pair, 2)

def collapse(per, factions, slots, levels):
    """merge adjacent levels whose top-3 pick is identical"""
    bands=[]
    for faction in factions:
        for sl in slots:
            run_key=None; start=None; prev=None
            for lv in list(levels)+[None]:
                rows=per.get((faction,lv,sl),[]) if lv else []
                key=tuple((r[1]["id"],r[2]) for r in rows[:3]) if rows else None
                if key!=run_key:
                    if run_key: bands.append((faction,sl,start,prev,run_key,per[(faction,prev,sl)][:8]))
                    run_key=key; start=lv
                prev=lv
    return bands

if __name__=="__main__":
    cls=os.environ.get("GQ_CLASS","PALADIN")
    out={}
    for spec in [k for k in W[cls] if not k.startswith("_")]:
        # Stop at 69. Level 70 is deliberately NOT generated: at 70 the things that
        # decide BiS -- gem sockets, tier set bonuses, libram/relic effects, weapon
        # speed breakpoints, phase tier, PvE-vs-PvP intent -- are all invisible to a
        # linear stat-weight model, and Henrik already has professionally curated
        # Phase 3 lists for 70 in Data.lua. Generated picks there would only
        # compete with better data. Measured: 0/44 exact, 0.55/3 overlap.
        # Forever / Classic: stop at 60 (was 69 for TBC Anniversary).
        # Score 1-9 per real spec (not only levelling_1_9) so enhancement/arms/etc.
        # get their own early BiS. Collapse 1-9 and 10-60 separately so a stable
        # top-3 cannot fuse into a band that crosses the talent breakpoint.
        level_ranges = [range(1,10)] if spec=="levelling_1_9" else [range(1,10), range(10,61)]
        out[spec]=None
        for lv in level_ranges:
            per,cfg,notable,full60=run(cls,spec,lv)
            if out[spec] is None:
                out[spec]={"label":cfg["label"],"bands":[]}
            slots=sorted({k[2] for k in per})
            bands=collapse(per,("Alliance","Horde"),slots,lv)
            early_band = max(lv)==9
            def emit(faction,sl,lo,hi,rows,origins=None, _spec=spec, _notable=notable):
                out[_spec]["bands"].append({"faction":faction,"slot":sl,"lo":lo,"hi":hi,
                  "picks":[{"id":r[1]["id"],"name":r[1]["name"],"q":r[1]["quality"],
                            "ilvl":r[1]["ilvl"],"rlvl":r[1]["rlvl"],"req":eff_req(r[1]),"bind":r[1].get("bonding"),"kind":r[1]["kind"],
                            "score":round(r[0],2),"suffix":r[2],"chance":r[3],"chanceAny":r[5],
                            "suffixRange":(r[7] if len(r)>7 else None),"suffixId":(r[8] if len(r)>8 else None),
                            "dps":r[1]["dps"],"speed":r[1]["speed"],
                            "stats":r[4],"src":srcs[str(r[1]["id"])],"seasonal":srcs[str(r[1]["id"])].get("seasonal",False),
                            "effects":r[1].get("effects") or [],
                            "reqSkills":r[1].get("reqSkills") or [],"reqRep":r[1].get("reqRep") or []} for r in rows]})
                if origins: out[_spec]["bands"][-1]["origins"]=origins
                if sl in ("MainHand","SecondaryHand") and cfg["weaponStyle"] in AMBIGUOUS_STYLES:
                    rt=route_for(per,faction,hi)
                    if rt:
                        out[_spec]["bands"][-1]["route"]=rt[0]
                        out[_spec]["bands"][-1]["routeTwoHand"]=rt[1]
                        out[_spec]["bands"][-1]["routeOneHand"]=rt[2]
                nbs=_notable.get((faction,hi,sl)) or []
                bis=out[_spec]["bands"][-1]["picks"][:3]
                shown={p["id"] for p in bis}
                cut_score=bis[-1]["score"] if bis else 0
                nbs=[r for r in nbs if r[1]["id"] not in shown and r[0] < cut_score]
                if nbs:
                    out[_spec]["bands"][-1]["notableEffects"]=[{
                      "id":r[1]["id"],"name":r[1]["name"],"q":r[1]["quality"],
                      "ilvl":r[1]["ilvl"],"rlvl":r[1]["rlvl"],"kind":r[1]["kind"],
                      "score":round(r[0],2),"stats":r[4],"effects":r[1].get("procs") or r[1].get("effects") or [],
                      "suffix":r[2],"chance":r[3],"chanceAny":r[5],
                      "suffixRange":(r[7] if len(r)>7 else None),"suffixId":(r[8] if len(r)>8 else None),
                      "jackpot":round(r[6],2) if len(r)>6 else None,
                      "src":srcs[str(r[1]["id"])]} for r in nbs]

            for faction,sl,lo,hi,key,rows in bands:
                if early_band or spec=="levelling_1_9":
                    emit(faction,sl,lo,hi,rows); continue
                if NO_GUIDES or not (lo<=60<=hi):
                    emit(faction,sl,lo,hi,rows); continue
                r60=full60.get((faction,sl)) or per.get((faction,60,sl)) or rows
                ov=guide_override(spec,sl,faction,r60,cls)
                if lo<60: emit(faction,sl,lo,59,per.get((faction,59,sl)) or rows)
                if ov: emit(faction,sl,60,60,ov[0],ov[1])
                else:   emit(faction,sl,60,60,r60[:8])
        print(f"{spec:<16} slots={len(slots):<3} bands={len(out[spec]['bands'])}")
    if _displaced:
        print(f"level-60 guide override: {len(_displaced)} slot(s) where the model beat the guide by >{int(DISPLACE_MARGIN*100)}%")
        for d in _displaced[:14]:
            print(f"    {d[0]:<12}{d[2]:<9}{d[1]:<14}{d[3]} ({d[4]}) displaced {d[5]} ({d[6]})")
    json.dump(out,open(os.path.join(OUT, os.environ.get("GQ_OUT","paladin.json")),"w"))
    print("wrote "+os.path.join(OUT, os.environ.get("GQ_OUT","paladin.json")))
