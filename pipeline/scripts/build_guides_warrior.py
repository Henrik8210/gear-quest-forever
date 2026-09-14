"""Rebuild guides_warrior.json from Henrik's two supplied Wowhead guides, KEEPING the
Rank column. The first pass stored a flat ordered list, which threw the tier away and
made list position the only signal -- so Thunderfury, tied "Best" with The Hungering
Cold in both hands, came second purely because it was printed second."""
import json, re

items=json.load(open("items.json"))
NAMES={it["name"] for it in items.values()}

# Rank label -> tier. Lower is better. Ties are broken by the model's own score.
#   "Best Mitigation" is not a worse tier, it is a different axis -- and a tank's own
#   weights already favour mitigation, so leaving it in tier 1 lets the score sort it.
# An UNQUALIFIED "Best" is the guide's primary recommendation. "Best Mitigation",
# "Alternative Best" and "Close Second" are qualified -- best *if* you are optimising
# for that one thing -- so they sit just below it. Leaving them level with plain Best
# and letting the score decide put Cryptfiend Silk Cloak above Cloak of the Fallen
# God for Protection, because a stamina-weighted model always prefers the mitigation
# piece; that is the model overruling a judgement the guide did make.
# A race qualifier ("Best (Human)", "Best (Contested)") is not a downgrade.
TIER={
 "insane":0,
 "best":1,
 "close second":2,"alternative best":2,"best mitigation":2,
 "great":3,
 "good":4,
 "alternative":5,"hit alternative":5,"mitigation alternative":5,
 "situational":6,
}
def tier(label):
    l=re.sub(r"\(.*?\)","",label).strip().lower()   # "Best (Human)" -> "best"
    l=re.sub(r"\s+"," ",l)
    if l in TIER: return TIER[l]
    raise SystemExit("unknown rank label: %r"%label)

def rows(block):
    """'SLOT | RANK | NAME' lines -> {slot: [(tier,name)]}. A row naming a faction
    pair with ' / ' is two items at the same tier."""
    out={}
    for line in block.strip().splitlines():
        line=line.strip()
        if not line or "|" not in line: continue
        slot,rank,name=[x.strip() for x in line.split("|",2)]
        for nm in [x.strip() for x in name.split(" / ")]:
            nm=re.sub(r"\s*\((?:Str|Agi)\)$","",nm)      # ring variants, same item
            if nm not in NAMES: raise SystemExit("unmatched item: %r"%nm)
            out.setdefault(slot,[]).append((tier(rank),nm))
    return out

TANK_ARMOUR="""
Head | Best | Conqueror's Crown
Head | Best Mitigation | Dreadnaught Helmet
Head | Great | Field Marshal's Plate Helm
Head | Great | Warlord's Plate Headpiece
Head | Great | Helm of Endless Rage
Head | Good | Helm of Domination
Neck | Best | Sadist's Collar
Neck | Best (Contested) | Stormrage's Talisman of Seething
Neck | Great | Pendant of the Qiraji Guardian
Neck | Great | Pendant of the Shifting Sands
Neck | Great | Amulet of the Darkmoon
Neck | Best Mitigation | Mark of C'Thun
Neck | Hit Alternative | Onyxia Tooth Pendant
Shoulder | Best | Conqueror's Spaulders
Shoulder | Great | Field Marshal's Plate Shoulderguards
Shoulder | Great | Warlord's Plate Shoulders
Shoulder | Great | Dreadnaught Pauldrons
Shoulder | Great | Drake Talon Pauldrons
Shoulder | Best Mitigation | Pauldrons of the Unrelenting
Back | Best | Cloak of the Fallen God
Back | Close Second | Cloak of the Golden Hive
Back | Great | Cloak of the Scourge
Back | Great | Cloak of Concentrated Hatred
Back | Hit Alternative | Drape of Unyielding Strength
Back | Best Mitigation | Elementium Threaded Cloak
Back | Best Mitigation | Cryptfiend Silk Cloak
Chest | Best | Conqueror's Breastplate
Chest | Great | Dreadnaught Breastplate
Chest | Great | Field Marshal's Plate Armor
Chest | Great | Warlord's Plate Armor
Chest | Great | Breastplate of Annihilation
Chest | Good | Zandalar Vindicator's Breastplate
Wrist | Best | Dreadnaught Bracers
Wrist | Great | Bracers of Brutality
Wrist | Great | Bracelets of Wrath
Wrist | Great | Hive Defiler Wristguards
Wrist | Good | Berserker Bracers
Wrist | Good | Zandalar Vindicator's Armguards
Wrist | Hit Alternative | Qiraji Execution Bracers
Hands | Best (Human) | Gauntlets of Annihilation
Hands | Best (Human) | Gauntlets of Steadfast Determination
Hands | Alternative Best | Edgemaster's Handguards
Hands | Alternative Best | Aged Core Leather Gloves
Hands | Great | Marshal's Plate Gauntlets
Hands | Great | General's Plate Gauntlets
Hands | Best Mitigation | Dreadnaught Gauntlets
Waist | Best | Girdle of the Mentor
Waist | Great | Onslaught Girdle
Waist | Great | Triad Girdle
Waist | Best Mitigation | Royal Qiraji Belt
Waist | Best Mitigation | Dreadnaught Waistguard
Legs | Best | Conqueror's Legguards
Legs | Great | Marshal's Plate Legguards
Legs | Great | General's Plate Leggings
Legs | Best Mitigation | Dreadnaught Legplates
Feet | Best | Dreadnaught Sabatons
Feet | Great | Conqueror's Greaves
Feet | Great | Marshal's Plate Boots
Feet | Great | General's Plate Boots
Feet | Great | Chromatic Boots
Feet | Hit Alternative | Boots of the Fallen Hero
Finger | Best | Master Dragonslayer's Ring
Finger | Best | Circle of Applied Force
Finger | Best | Ring of the Godslayer
Finger | Best Mitigation | Archimtiros' Ring of Reckoning
Finger | Mitigation Alternative | Ring of the Dreadnaught
Finger | Mitigation Alternative | Signet of the Fallen Defender
Finger | Mitigation Alternative | Ring of Emperor Vek'lor
Finger | Mitigation Alternative | Signet Ring of the Bronze Dragonflight (Str)
Finger | Hit Alternative | Signet Ring of the Bronze Dragonflight (Agi)
Finger | Hit Alternative | Band of Accuria
Finger | Hit Alternative | Don Julio's Band
Trinket | Best | Kiss of the Spider
Trinket | Best | Mark of the Champion
Trinket | Great | Earthstrike
Trinket | Great | Drake Fang Talisman
Trinket | Great | Jom Gabbar
Trinket | Great | Diamond Flask
Trinket | Great | Hand of Justice
Trinket | Situational | Lifegiving Gem
Trinket | Situational | Nat Pagle's Broken Reel
"""

TANK_WEAPONS="""
MainHand | Best | The Hungering Cold
MainHand | Best | Thunderfury, Blessed Blade of the Windseeker
MainHand | Great | Iblis, Blade of the Fallen Seraph
MainHand | Great | Widow's Remorse
MainHand | Good | Grand Marshal's Swiftblade / High Warlord's Quickblade
MainHand | Good | Warblade of the Hakkari
MainHand | Good | Ravencrest's Legacy
MainHand | Good | Maladath, Runed Blade of the Black Flight
MainHand | Good | Blackguard
MainHand | Best | Kingsfall
MainHand | Best | Death's Sting
MainHand | Best | Harbinger of Doom
MainHand | Great | Maexxna's Fang
MainHand | Great | Blessed Qiraji Pugio
MainHand | Good | Shadowsong's Sorrow
MainHand | Good | Grand Marshal's Dirk / High Warlord's Razor
SecondaryHand | Best | The Face of Death
SecondaryHand | Great | Grand Marshal's Aegis / High Warlord's Shield Wall
SecondaryHand | Great | The Plague Bearer
SecondaryHand | Good | Blessed Qiraji Bulwark
SecondaryHand | Good | Elementium Reinforced Bulwark
SecondaryHand | Situational | Force Reactive Disk
Ranged | Best | Crossbow of Imminent Doom
Ranged | Best | Soulstring
Ranged | Best | Toxin Injector
Ranged | Best | Heartstriker
Ranged | Great | Dragonbreath Hand Cannon
Ranged | Great | Mandokir's Sting
Ranged | Great | Polished Ironwood Crossbow
Ranged | Great | Blastershot Launcher
Ranged | Hit Alternative | Striker's Mark
Ranged | Hit Alternative | Blackcrow
Ranged | Hit Alternative | Satyr's Bow
"""

FURY="""
Head | Best | Lionheart Helm
Head | Great | Helm of Endless Rage
Head | Great | Conqueror's Crown
Head | Great | Southwind Helm
Head | Great | Crown of Destruction
Head | Great | Field Marshal's Plate Helm
Head | Great | Warlord's Plate Headpiece
Head | Great | Lizardscale Eyepatch
Head | Good | Lieutenant Commander's Plate Helm
Head | Good | Champion's Plate Helm
Neck | Best | Stormrage's Talisman of Seething
Neck | Great | Barbed Choker
Neck | Great | The Eye of Hakkar
Neck | Great | Onyxia Tooth Pendant
Neck | Good | Fury of the Forgotten Swarm
Shoulder | Best | Conqueror's Spaulders
Shoulder | Best | Mantle of Wicked Revenge
Shoulder | Great | Field Marshal's Plate Shoulderguards
Shoulder | Great | Warlord's Plate Shoulders
Shoulder | Great | Drake Talon Pauldrons
Shoulder | Good | Lieutenant Commander's Plate Shoulders
Shoulder | Good | Champion's Plate Shoulders
Back | Best | Shroud of Dominion
Back | Great | Cloak of the Fallen God
Back | Great | Cloak of Draconic Might
Back | Great | Cloak of Concentrated Hatred
Back | Great | Drape of Unyielding Strength
Back | Great | Puissant Cape
Chest | Best | Plated Abomination Ribcage
Chest | Best | Ghoul Skin Tunic
Chest | Great | Breastplate of Annihilation
Chest | Great | Conqueror's Breastplate
Chest | Great | Vest of Swift Execution
Chest | Good | Savage Gladiator Chain
Wrist | Best | Wristguards of Vengeance
Wrist | Best | Hive Defiler Wristguards
Wrist | Great | Qiraji Execution Bracers
Wrist | Great | Bracers of Brutality
Wrist | Good | Deeprock Bracers
Hands | Best (Human/Orc) | Gauntlets of Annihilation
Hands | Best (Other Races) | Edgemaster's Handguards
Hands | Great | Gloves of Enforcement
Hands | Good | Sacrificial Gauntlets
Waist | Best | Girdle of the Mentor
Waist | Best | Onslaught Girdle
Waist | Great | Belt of Never-ending Agony
Waist | Great | Triad Girdle
Waist | Good | Zandalar Vindicator's Belt
Legs | Best | Legplates of Carnage
Legs | Great | Leggings of Apocalypse
Legs | Good | Conqueror's Legguards
Legs | Good | Titanic Leggings
Legs | Good | Marshal's Plate Legguards
Legs | Good | General's Plate Leggings
Legs | Good | Scaled Sand Reaver Leggings
Feet | Best | Chromatic Boots
Feet | Great | Boots of the Vanguard
Feet | Great | Boots of the Fallen Hero
Feet | Great | Marshal's Plate Boots
Feet | Great | General's Plate Boots
Feet | Great | Slime Kickers
Finger | Insane | Band of Unnatural Forces
Finger | Best | Quick Strike Ring
Finger | Best | Ring of the Qiraji Fury
Finger | Best | Circle of Applied Force
Finger | Great | Master Dragonslayer's Ring
Finger | Great | Don Julio's Band
Finger | Great | Band of Earthen Might
Finger | Great | Signet of Unyielding Strength
Finger | Great | Signet Ring of the Bronze Dragonflight
Finger | Hit Alternative | Band of Accuria
Trinket | Insane | Kiss of the Spider
Trinket | Best | Mark of the Champion
Trinket | Best | Slayer's Crest
Trinket | Great | Diamond Flask
Trinket | Great | Jom Gabbar
Trinket | Good | Earthstrike
Trinket | Good | Drake Fang Talisman
Trinket | Good | Hand of Justice
Trinket | Situational | Badge of the Swarmguard
Trinket | Situational | Fetish of the Sand Reaver
Ranged | Best | Nerubian Slavemaker
Ranged | Best | Soulstring
Ranged | Best | Larvae of the Great Worm
Ranged | Great | Crossbow of Imminent Doom
Ranged | Great | Striker's Mark
Ranged | Great | Gurubashi Dwarf Destroyer
Ranged | Great | Bloodseeker
Ranged | Great | Blastershot Launcher
Ranged | Great | The Purifier
"""

FURY_WEAPONS="""
MainHand | Best | Gressil, Dawn of Ruin
MainHand | Best | Hatchet of Sundered Bone
MainHand | Great | The Castigator
MainHand | Great | Empyrean Demolisher
MainHand | Great | Misplaced Servo Arm
MainHand | Great | Iblis, Blade of the Fallen Seraph
MainHand | Great | High Warlord's Cleaver
MainHand | Great | Blessed Qiraji War Axe
MainHand | Great | The Hungering Cold
MainHand | Great | Crul'shorukh, Edge of Chaos
MainHand | Good | Grand Marshal's Longsword
MainHand | Good | Chromatically Tempered Sword
MainHand | Good | Ancient Qiraji Ripper
MainHand | Good | Deathbringer
SecondaryHand | Best | The Hungering Cold
SecondaryHand | Great | The Castigator
SecondaryHand | Great | Iblis, Blade of the Fallen Seraph
SecondaryHand | Great | High Warlord's Cleaver
SecondaryHand | Great | Crul'shorukh, Edge of Chaos
SecondaryHand | Great | Blessed Qiraji War Axe
SecondaryHand | Good | Grand Marshal's Swiftblade
SecondaryHand | Good | Chromatically Tempered Sword
SecondaryHand | Good | Maladath, Runed Blade of the Black Flight
SecondaryHand | Good | Misplaced Servo Arm
SecondaryHand | Good | Anubisath Warhammer
SecondaryHand | Good | Ancient Qiraji Ripper
SecondaryHand | Good | Brutality Blade
SecondaryHand | Good | Doom's Edge
SecondaryHand | Good | Zulian Hacker
SecondaryHand | Good | Sickle of Unyielding Strength
"""

# Arms: no two-hand table exists in either guide, so its MainHand list is carried
# over from the Classic-era DPS guide's Two-Hand section, all at one tier.
ARMS_2H=["Might of Menethil","Bonereaver's Edge","Dark Edge of Insanity",
         "High Warlord's Greatsword","High Warlord's Battle Axe"]

def merge(*blocks):
    out={}
    for b in blocks:
        for sl,rs in rows(b).items():
            cur=out.setdefault(sl,[])
            for t,nm in rs:
                prev=[i for i,(t0,n0) in enumerate(cur) if n0==nm]
                if prev:                       # same item in two tables: keep the better tier
                    i=prev[0]
                    if t<cur[i][0]: cur[i]=(t,nm)
                else: cur.append((t,nm))
    return out

fury=merge(FURY,FURY_WEAPONS)
tank=merge(TANK_ARMOUR,TANK_WEAPONS)
arms=merge(FURY)                                # armour + Ranged only
arms.pop("MainHand",None); arms.pop("SecondaryHand",None)
arms["MainHand"]=[(1,n) for n in ARMS_2H]

g={"arms":arms,"fury":fury,"protection":tank}
json.dump({s:{sl:[[t,n] for t,n in v] for sl,v in d.items()} for s,d in g.items()},
          open("guides_warrior.json","w"), indent=1, ensure_ascii=False)
for s,d in g.items():
    print("==",s,sum(len(v) for v in d.values()),"entries")
    for sl,v in d.items():
        import collections
        print("   %-14s %2d  tiers %s"%(sl,len(v),dict(sorted(collections.Counter(t for t,_ in v).items()))))
