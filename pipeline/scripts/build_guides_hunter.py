"""guides_hunter.json from the one Wowhead Classic hunter DPS guide Henrik supplied,
keeping the Rank column (R19). One list serves all three specs, as he said.

Tier scale. Base tier from the rank word; +1 if the rank carries a qualifier that
restricts WHEN it applies (PvP, race, creature type, set bonus, pet damage). A
qualifier about contention or availability ("Contested") does not demote -- that is
obtainability, which never affects ranking.
"""
import json, re, collections

items=json.load(open("items.json"))
NAMES={it["name"] for it in items.values()}

BASE={"insane":0,"best":1,"close second":2,"alternative best":2,"best mitigation":2,
      "great":3,"good":4,"okay":5,"mediocre":6,
      "alternative":6,"hit alternative":6,"mitigation alternative":6,"situational":7}
# qualifiers that restrict when the pick applies -> one tier down
RESTRICT=re.compile(r"\b(pvp|orc|human|dwarf|troll|tauren|undead|gnome|night ?elf|draenei|blood ?elf|"
                    r"dragonkin|undead|beast|demon|set bonus|pet damage|alliance|horde)\b")
NEUTRAL=re.compile(r"\bcontested\b")

def tier(label):
    l=re.sub(r"\s+"," ",label.strip().lower())
    l=NEUTRAL.sub("",l)
    demote = 1 if RESTRICT.search(l) else 0
    core=re.sub(r"[-+(].*$","",l).strip()
    core=RESTRICT.sub("",core).strip(" -+")
    core=re.sub(r"\s+"," ",core)
    if core not in BASE: raise SystemExit("unknown rank label: %r (core %r)"%(label,core))
    return BASE[core]+demote

SLOT={"head":"Head","shoulder":"Shoulder","back":"Back","chest":"Chest","wrist":"Wrist",
      "hand":"Hands","hands":"Hands","waist":"Waist","leg":"Legs","legs":"Legs",
      "foot":"Feet","feet":"Feet","neck":"Neck","ring":"Finger","trinket":"Trinket",
      "ranged":"Ranged","two-hand":"MainHand","main hand":"MainHand","off-hand":"SecondaryHand"}

RAW="""
Head | Best | Cryptstalker Headpiece
Head | Best PvP | Field Marshal's Chain Helm
Head | Best PvP | Warlord's Chain Helmet
Head | Great PvP | Lieutenant Commander's Chain Helm
Head | Great PvP | Champion's Chain Helm
Head | Great | Striker's Diadem
Head | Great | Giantstalker's Helmet
Head | Great | Bloodstained Coif
Head | Great | Beastmaster's Cap
Head | Good | Blooddrenched Mask
Head | Okay | Backwood Helm
Head | Okay | Crown of Tyranny
Shoulder | Best | Cryptstalker Spaulders
Shoulder | Great | Field Marshal's Chain Spaulders
Shoulder | Great | Warlord's Chain Shoulders
Shoulder | Great | Dragonstalker's Spaulders
Shoulder | Great | Mantle of Wicked Revenge
Shoulder | Good | Chitinous Shoulderguards
Shoulder | Good | Barrage Shoulders
Shoulder | Good | Lieutenant Commander's Chain Shoulders
Shoulder | Good | Champion's Chain Shoulders
Shoulder | Good | Giantstalker's Epaulets
Shoulder | Good | Truestrike Shoulders
Shoulder | Okay | Wyrmhide Spaulders
Shoulder | Okay | Wyrmtongue Shoulders
Back | Best | Cloak of the Fallen God
Back | Best | Shroud of Dominion
Back | Good | Cloak of the Unseen Path
Back | Good | Cloak of Concentrated Hatred
Back | Good | Earthweave Cloak
Back | Good | Cloak of the Shrouded Mists
Back | Good | Cape of the Black Baron
Back | Good | Cloak of Draconic Might
Back | Good | Zulian Tigerhide Cloak
Back | Okay | Dark Phantom Cape
Back | Okay | Blackveil Cape
Chest | Best | Cryptstalker Tunic
Chest | Good | Striker's Hauberk
Chest | Mediocre | Dragonstalker's Breastplate
Chest | Mediocre | Field Marshal's Chain Breastplate
Chest | Mediocre | Warlord's Chain Chestpiece
Chest | Mediocre | Legionnaire's Chain Hauberk
Wrist | Best | Cryptstalker Wristguards
Wrist | Great | Wristguards of True Flight
Wrist | Great | Dragonstalker's Bracers
Wrist | Good | Giantstalker's Bracers
Wrist | Okay | Primal Batskin Bracers
Wrist | Okay | Beastmaster's Bindings
Wrist | Okay | Slashclaw Bracers
Wrist | Okay | Bracers of the Eclipse
Hand | Best | Marshal's Chain Grips
Hand | Best | General's Chain Gloves
Hand | Great | Cryptstalker Handguards
Hand | Great | Vek'lor's Gloves of Devastation
Hand | Good | Dragonstalker's Gauntlets
Hand | Good | Giantstalker's Gloves
Hand | Good | Gloves of the Tormented
Hand | Good | Devilsaur Gauntlets
Waist | Best | Cryptstalker Girdle
Waist | Great | Ossirian's Binding
Waist | Good | Dragonstalker's Belt
Waist | Good | Giantstalker's Belt
Waist | Good | Zandalar Predator's Belt
Waist | Good | Warpwood Binding
Waist | Good | Marksman's Girdle
Leg | Best | Leggings of Apocalypse
Leg | Best | Cryptstalker Legguards
Leg | Great | Sentinel's Chain Leggings
Leg | Great | Outrider's Chain Leggings
Leg | Great | Marshal's Chain Legguards
Leg | Great | General's Chain Legguards
Leg | Good | Dragonstalker's Legguards
Leg | Good | Striker's Leggings
Leg | Good | Giantstalker's Leggings
Leg | Good | Bloodstained Legplates
Leg | Good | Beastmaster's Pants
Leg | Okay | Devilsaur Leggings
Foot | Best | Cryptstalker Boots
Foot | Great | Marshal's Chain Boots
Foot | Great | General's Chain Sabatons
Foot | Great | Striker's Footguards
Foot | Good | Dragonstalker's Greaves
Foot | Good | Giantstalker's Boots
Foot | Good + Pet Damage | Beastmaster's Boots
Foot | Okay | Mongoose Boots
Foot | Okay | Bloodstained Greaves
Foot | Okay | Windreaver Greaves
Neck | Best | Prestor's Talisman of Connivery
Neck | Great | Stormrage's Talisman of Seething
Neck | Great | Onyxia Tooth Pendant
Neck | Good | Barbed Choker
Neck | Good | Mark of Fordring
Neck | Okay | Imperial Jewel
Neck | Okay | Will of the Martyr
Ring | Best | Band of Unnatural Forces
Ring | Best | Band of Reanimation
Ring | Best | Ring of the Cryptstalker
Ring | Great | Signet Ring of the Bronze Dragonflight
Ring | Great | Band of Accuria
Ring | Great | Ring of the Godslayer
Ring | Good | Ring of the Qiraji Fury
Ring | Good | Don Julio's Band
Ring | Good | Master Dragonslayer's Ring
Ring | Good + Set Bonus | Band of Jin
Ring | Good + Set Bonus | Seal of Jin
Ring | Okay | Tarnished Elven Ring
Ring | Okay | Blackstone Ring
Ring | Okay | Painweaver Band
Trinket | Best | Mark of the Champion
Trinket | Best | Renataki's Charm of Beasts
Trinket | Best | Drake Fang Talisman
Trinket | Great | Kiss of the Spider
Trinket | Great | Jom Gabbar
Trinket | Good | Blackhand's Breadth
Trinket | Good | Seal of the Dawn
Ranged | Best | Nerubian Slavemaker
Ranged | Good | Ashjre'thul, Crossbow of Smiting
Ranged | Good | Soulstring
Ranged | Good | Larvae of the Great Worm
Ranged | Mediocre | Grand Marshal's Hand Cannon
Ranged | Mediocre | High Warlord's Street Sweeper
Ranged | Mediocre | Grand Marshal's Repeater
Ranged | Mediocre | High Warlord's Crossbow
Two-Hand | Best | The Eye of Nerub
Two-Hand | Great (Orc) | Severance
Two-Hand | Great | Barb of the Sand Reaver
Two-Hand | Great | Corrupted Ashbringer
Two-Hand | Good (dragonkin) | Gri'lek's Carver
Two-Hand | Good | Claymore of Unholy Might
Main Hand | Best - Contested | Kingsfall
Main Hand | Best | Harbinger of Doom
Main Hand | Good | Iblis, Blade of the Fallen Seraph
Main Hand | Good | Blessed Qiraji Pugio
Main Hand | Good | Hatchet of Sundered Bone
Off-Hand | Best | Claw of the Frost Wyrm
Off-Hand | Best - Contested | Kingsfall
Off-Hand | Good | Hatchet of Sundered Bone
Off-Hand | Good | Harbinger of Doom
Off-Hand | Good | Iblis, Blade of the Fallen Seraph
Off-Hand | Good | Blessed Qiraji Pugio
"""

out={}; unmatched=[]
for line in RAW.strip().splitlines():
    slot,rank,name=[x.strip() for x in line.split("|",2)]
    sl=SLOT[slot.lower()]
    if name not in NAMES: unmatched.append(name); continue
    t=tier(rank)
    cur=out.setdefault(sl,[])
    prev=[i for i,(t0,n0) in enumerate(cur) if n0==name]
    if prev:
        if t<cur[prev[0]][0]: cur[prev[0]]=(t,name)
    else: cur.append((t,name))

if unmatched:
    print("UNMATCHED (%d): %s"%(len(unmatched),unmatched))
one={sl:[[t,n] for t,n in v] for sl,v in out.items()}
json.dump({"beast_mastery":one,"marksmanship":one,"survival":one},
          open("guides_hunter.json","w"),indent=1,ensure_ascii=False)
for sl,v in out.items():
    print("  %-14s %2d  tiers %s"%(sl,len(v),dict(sorted(collections.Counter(t for t,_ in v).items()))))
