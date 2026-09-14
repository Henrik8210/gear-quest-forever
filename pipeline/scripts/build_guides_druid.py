"""guides_druid.json from Henrik's four Wowhead Classic druid guides, keeping the
Rank column (R19). One guide per spec, unlike hunter.

Tier: base word, +1 if the rank carries a qualifier restricting WHEN it applies
(a set-piece count, a DPS/mitigation skew, a hit requirement, a race). A qualifier
about availability -- Legendary, Contested -- does not demote.
"""
import json, re, collections
items=json.load(open("items.json")); NAMES={it["name"] for it in items.values()}

# Three restoration entries are RANDOM-SUFFIX items and the guide prints the rolled
# name: "Archivist Cape of Healing", "Atal'ai Gloves of Healing", "Drakestone of
# Healing". No such item exists -- the items are "Archivist Cape" (16 rolls),
# "Atal'ai Gloves" (14) and "Drakestone" (17), one of which is "of Healing". The
# guide list stores the BASE name, which is what the scorer matches on; which roll
# to chase is then the notable shelf's job (R21).

BASE={"insane":0,"best":1,"close second":2,"alternative best":2,"best mitigation":2,
      "great":3,"good":4,"okay":5,"optional":5,"mediocre":6,
      "alternative":6,"hit alternative":6,"hit option":6,"mitigation alternative":6,
      "mit skewed alternative":6,"situational":7}
RESTRICT=re.compile(r"\b(pvp|dps|hit|mit|mitigation|t2|t3|\d/\d|set bonus|pet damage|orc|human|"
                    r"dwarf|troll|tauren|undead|gnome|night ?elf|draenei|blood ?elf|dragonkin|beast|demon)\b")
NEUTRAL=re.compile(r"\b(legendary|contested)\b")
def tier(label):
    l=re.sub(r"\s+"," ",label.strip().lower())
    l=NEUTRAL.sub("",l).strip(" -&")
    demote=1 if RESTRICT.search(l) else 0
    core=re.split(r"\s*[-(&]\s*",l)[0].strip()
    core=RESTRICT.sub("",core).strip(" -&+")
    core=re.sub(r"\s+"," ",core)
    if core in BASE: return BASE[core]+demote
    if l.strip() in BASE: return BASE[l.strip()]+demote
    raise SystemExit("unknown rank label: %r (core %r)"%(label,core))

SLOT={"head":"Head","shoulder":"Shoulder","shoulders":"Shoulder","back":"Back","chest":"Chest",
 "wrist":"Wrist","wrists":"Wrist","hand":"Hands","hands":"Hands","waist":"Waist","leg":"Legs",
 "legs":"Legs","foot":"Feet","feet":"Feet","neck":"Neck","ring":"Finger","rings":"Finger",
 "ring (x2)":"Finger","trinket":"Trinket","trinkets":"Trinket","idol":"Ranged",
 "idol/relic":"Ranged","relic":"Ranged","main hand":"MainHand","two hand":"MainHand",
 "two-hand":"MainHand","main hand (two-handed)":"MainHand","main hand (one-handed)":"MainHand",
 "weapon":"MainHand","off hand":"SecondaryHand","off-hand":"SecondaryHand"}

RAW={}
RAW["bear"]="""
Head | Best | Field Marshal's Dragonhide Helmet / Warlord's Dragonhide Helmet
Head | Best (DPS) | Wolfshead Helm
Head | Optional | Southwind Helm
Shoulder | Best | Mantle of Wicked Revenge
Shoulder | Optional | Chitinous Shoulderguards
Back | Best | Cloak of the Fallen God
Back | Optional (Hit) | Cloak of Concentrated Hatred
Back | Optional | Shroud of Dominion
Back | Optional | Puissant Cape
Chest | Best | Ghoul Skin Tunic
Chest | Optional | Vest of Swift Execution
Wrist | Best | Qiraji Execution Bracers
Wrist | Optional | Wristguards of Stability
Hands | Best | Marshal's Dragonhide Gauntlets / General's Dragonhide Gloves
Hands | Optional | Gloves of Enforcement
Hands | Optional | Gloves of the Hidden Temple
Hands | Optional | Devilsaur Gauntlets
Waist | Best | Belt of Never-ending Agony
Waist | Optional | Belt of Preserved Heads
Legs | Best | Leggings of Apocalypse
Legs | Optional | Devilsaur Leggings
Feet | Best | Boots of the Vanguard
Feet | Best | Boots of the Shadow Flame
Neck | Best | Stormrage's Talisman of Seething
Neck | Best (DPS) | Prestor's Talisman of Connivery
Neck | Optional | Barbed Choker
Neck | Optional | Onyxia Tooth Pendant
Ring | Best | Band of Unnatural Forces
Ring | Best | Signet Ring of the Bronze Dragonflight
Ring | Best | Band of Accuria
Ring | Optional | Quick Strike Ring
Ring | Optional | Ring of the Qiraji Fury
Ring | Optional | Master Dragonslayer's Ring
Ring | Optional | Circle of Applied Force
Trinket | Best | Kiss of the Spider
Trinket | Best | Slayer's Crest
Trinket | Optional | Drake Fang Talisman
Trinket | Optional | Earthstrike
Main Hand | Best | Manual Crowd Pummeler
Main Hand | Best | Atiesh, Greatstaff of the Guardian
Main Hand | Mit skewed alternative | Blessed Qiraji War Hammer
Main Hand | Mit skewed alternative | Hammer of Bestial Fury
Idol | Best | Idol of Brutality
"""
RAW["feral"]="""
Head | Best | Wolfshead Helm
Head | Optional | Southwind Helm
Shoulder | Best | Mantle of Wicked Revenge
Shoulder | Optional | Chitinous Shoulderguards
Back | Best | Cloak of Concentrated Hatred
Back | Best | Shroud of Dominion
Back | Optional | Cloak of the Fallen God
Back | Optional | Puissant Cape
Chest | Best | Vest of Swift Execution
Chest | Optional | Ghoul Skin Tunic
Wrist | Best | Qiraji Execution Bracers
Wrist | Optional | Wristguards of Stability
Hands | Best | Gloves of Enforcement
Hands | Best | Devilsaur Gauntlets
Waist | Best | Belt of Never-ending Agony
Waist | Optional | Belt of Preserved Heads
Legs | Best | Leggings of Apocalypse
Legs | Optional | Marshal's Dragonhide Legguards
Legs | Optional | General's Dragonhide Leggings
Legs | Optional | Devilsaur Leggings
Feet | Best | Boots of the Vanguard
Feet | Optional | Boots of the Shadow Flame
Neck | Best | Prestor's Talisman of Connivery
Neck | Optional | Stormrage's Talisman of Seething
Neck | Optional | Barbed Choker
Neck | Optional | Onyxia Tooth Pendant
Ring | Best | Band of Unnatural Forces
Ring | Best | Signet Ring of the Bronze Dragonflight
Ring | Best | Band of Accuria
Ring | Optional | Quick Strike Ring
Ring | Optional | Ring of the Qiraji Fury
Ring | Optional | Master Dragonslayer's Ring
Ring | Optional | Circle of Applied Force
Trinket | Best | Slayer's Crest
Trinket | Best | Drake Fang Talisman
Trinket | Best | Mark of the Champion
Trinket | Best | Kiss of the Spider
Trinket | Optional | Badge of the Swarmguard
Trinket | Optional | Earthstrike
Main Hand | Best | Manual Crowd Pummeler
Main Hand | Best | Atiesh, Greatstaff of the Guardian
Idol | Best | Idol of Ferocity
"""
RAW["restoration"]="""
Head | Best - 8/8 T2 | Stormrage Cover
Head | Best - 4/8 T3 | Crystal Adorned Crown
Head | Best - 8/8 T3 | Dreamwalker Headpiece
Head | Great | Deviate Growth Cap
Head | Great | Don Rigoberto's Lost Hat
Head | Great | Creeping Vine Helm
Head | Good | Zulian Headdress
Head | Optional | Cassandra's Grace
Head | Optional | Crimson Felt Hat
Shoulder | Best - 8/8 T2 | Stormrage Pauldrons
Shoulder | Best - 4/8 T3 | Wild Growth Spaulders
Shoulder | Best - 8/8 T3 | Dreamwalker Spaulders
Shoulder | Great | Ternary Mantle
Shoulder | Great | Animist's Spaulders
Shoulder | Good | Living Shoulders
Shoulder | Good | Mantle of Lost Hope
Shoulder | Good | Mantle of the Scarlet Crusade
Back | Best | Cloak of Suturing
Back | Great | Cloak of Clarity
Back | Great | Hide of the Wild
Back | Great | Shroud of Pure Thought
Back | Great | Drape of Benediction
Back | Good | Hakkari Loa Cloak
Back | Good | Archivist Cape
Back | Good | Cloak of the Cosmos
Back | Good | Battle Healer's Cloak / Caretaker's Cape
Back | Hit Option | Shroud of Arcane Mastery
Chest | Best - 8/8 T2 | Stormrage Chestguard
Chest | Best - 4/8 T3 | Dreamwalker Tunic
Chest | Great | Robes of the Guardian Saint
Chest | Great | Robes of the Exalted
Chest | Optional | Forest's Embrace
Wrist | Best - 8/8 T2 | Stormrage Bracers
Wrist | Best - 4/8 T3 | Dreamwalker Wristguards
Wrist | Great | Bracelets of Royal Redemption
Wrist | Good | Zandalar Haruspex's Bracers
Wrist | Good | Dryad's Wrist Bindings
Wrist | Optional | Bracers of Prosperity
Wrist | Optional | Bleak Howler Armguards
Wrist | Optional | Sublime Wristguards
Hands | Best - 8/8 T2 | Stormrage Handguards
Hands | Best - 4/8 T3 | Dreamwalker Handguards
Hands | Great | Wasphide Gauntlets
Hands | Good | Gloves of Dark Wisdom
Hands | Good | Gloves of the Messiah
Hands | Good | Gloves of Restoration
Hands | Good | Hands of the Exalted Herald
Hands | Good | Hands of Power
Hands | Good | Atal'ai Gloves
Waist | Best - 8/8 T2 | Stormrage Belt
Waist | Best - 4/8 T3 | Dreamwalker Girdle
Waist | Great | Corehound Belt
Waist | Great | Regenerating Belt of Vek'nilash
Waist | Great | Grasp of the Old God
Waist | Good | Eyestalk Cord
Waist | Good | Firemaw's Clutch
Waist | Good | Whipvine Cord
Waist | Hit Option | Angelista's Grasp
Waist | Hit Option | Ban'thok Sash
Legs | Best - 8/8 T2 | Stormrage Legguards
Legs | Best - 4/8 T3 | Empowered Leggings
Legs | Best - 8/8 T3 | Dreamwalker Legguards
Legs | Great | Salamander Scale Pants
Legs | Great | Ghoul Skin Leggings
Legs | Great | Padre's Trousers
Legs | Great | Senior Designer's Pantaloons
Legs | Great | Ritualistic Legguards
Feet | Best - 8/8 T2 | Stormrage Boots
Feet | Best - 4/8 T3 | Boots of Pure Thought
Feet | Best - 8/8 T3 | Dreamwalker Boots
Feet | Great | Verdant Footpads
Feet | Great | Treads of the Wandering Nomad
Feet | Great | Snowblind Shoes
Feet | Great | Betrayer's Boots
Feet | Optional | Waterspout Boots
Feet | Optional | Faith Healer's Boots
Feet | Optional | Boots of the Full Moon
Neck | Best | Necklace of Necropsy
Neck | Best | Amulet of the Fallen God
Neck | Great | Amulet of the Shifting Sands
Neck | Great | Jin'do's Evil Eye
Neck | Good | Animated Chain Necklace
Neck | Optional | Pendant of the Fallen Dragon
Neck | Optional | Choker of Enlightenment
Neck | Optional | Amulet of the Redeemed
Ring | Best | Band of Unanswered Prayers
Ring | Best | Pure Elementium Band
Ring | Best | Ring of the Martyr
Ring | Great | Cauterizing Band
Ring | Good | Primalist's Seal
Ring | Good | Primalist's Band
Ring | Good | Rosewine Circle
Ring | Good | Band of Mending
Ring | Good | Fordring's Seal
Ring | Good | Ring of Blackrock
Ring | Hit Option | Rune Band of Wizardry
Trinket | Best | Wushoolay's Charm of Nature
Trinket | Best | Eye of the Dead
Trinket | Best | Rejuvenating Gem
Trinket | Best | Hibernation Crystal
Trinket | Great | Zandalarian Hero Charm
Trinket | Great | Royal Seal of Eldre'Thalas
Trinket | Great | Briarwood Reed
Trinket | Great | Draconic Infused Emblem
Trinket | Great | Scarab Brooch
Trinket | Optional | Second Wind
Trinket | Optional | Burst of Knowledge
Main Hand | Best | Hammer of the Twisting Nether
Main Hand | Great | Scepter of the False Prophet
Main Hand | Great | The Widow's Embrace
Main Hand | Great | High Warlord's Battle Mace / Grand Marshal's Warhammer
Main Hand | Great | Fang of Korialstrasz
Main Hand | Good | Lok'amir il Romathis
Main Hand | Good | Claw of Chromaggus
Main Hand | Good | Jin'do's Hexxer
Main Hand | Optional | Aurastone Hammer
Main Hand | Optional | The Hammer of Grace
Off Hand | Best | Sapphiron's Right Eye
Off Hand | Great | Noth's Frigid Heart
Off Hand | Great | Sartura's Might
Off Hand | Great | Lei of the Lifegiver
Off Hand | Optional | Grand Marshal's Tome of Restoration
Off Hand | Optional | Tome of Divine Right
Off Hand | Optional | Drakestone
Off Hand | Optional | Brightly Glowing Stone
Off Hand | Hit Option | Scepter of Interminable Focus
Two Hand | Best - Legendary | Atiesh, Greatstaff of the Guardian
Two Hand | Best | Spire of Twilight
Two Hand | Great | Blessed Qiraji Augur Staff
Two Hand | Optional | Staff of Rampant Growth
Two Hand | Optional | Will of Arlokk
Two Hand | Optional | Redemption
Two Hand | Optional | Guiding Stave of Wisdom
Two Hand | Optional | Staff of Metanoia
Idol | Best | Idol of Health
Idol | Best | Idol of Rejuvenation
Idol | Optional | Idol of Longevity
"""
RAW["balance"]="""
Head | Best | Mish'undare, Circlet of the Mind Flayer
Head | Best | Preceptor's Hat
Head | Great | Spellweaver's Turban
Head | Mediocre | The Hexxer's Cover
Neck | Best | Gem of Trapped Innocents
Neck | Best | Amulet of Vek'nilash
Neck | Great | Choker of the Fire Lord
Neck | Mediocre | Malice Stone Pendant
Neck | Mediocre | Pristine Enchanted South Seas Kelp
Shoulder | Best | Rime Covered Mantle
Shoulder | Good | Mantle of the Blackwing Cabal
Shoulder | Mediocre | Abyssal Cloth Amice
Shoulder | Mediocre | Adventurer's Shoulders
Back | Best | Cloak of the Necropolis
Back | Great | Cloak of the Devoured
Back | Good | Cloak of Consumption
Back | Mediocre | Cloak of the Brood Lord
Back | Mediocre | Veil of Eclipse
Chest | Best | Garb of Royal Ascension
Chest | Best | Bloodvine Vest
Chest | Best | Crystal Webbed Robe
Chest | Great | Robe of Undead Cleansing
Chest | Good | Jade Inlaid Vestments
Wrist | Best | Rockfury Bracers
Wrist | Great | Bracers of Arcane Accuracy
Wrist | Mediocre | Burrower Bracers
Wrist | Mediocre | The Soul Harvester's Bindings
Wrist | Mediocre | Bracers of Undead Cleansing
Hands | Best | Dark Storm Gauntlets
Hands | Mediocre | Gloves of Undead Cleansing
Hands | Mediocre | Gloves of Ebru
Hands | Mediocre | Bloodtinged Gloves
Hands | Mediocre | Slaghide Gauntlets
Waist | Best | Eyestalk Waist Cord
Waist | Mediocre | Firemaw's Clutch
Waist | Mediocre | Mana Igniting Cord
Waist | Mediocre | Belt of Untapped Power
Waist | Mediocre | Angelista's Grasp
Legs | Best | Bloodvine Leggings
Legs | Best | Leggings of Polarity
Legs | Good | Leggings of the Black Blizzard
Legs | Mediocre | Flarecore Leggings
Feet | Best | Bloodvine Boots
Feet | Great | Boots of Epiphany
Feet | Great | Boots of Fright
Feet | Great | Snowblind Shoes
Feet | Good | Betrayer's Boots
Ring | Best | Ring of the Fallen God
Ring | Best | Band of the Inevitable
Ring | Great | Seal of the Damned
Ring | Good | Band of Forced Concentration
Ring | Good | Ritssyn's Ring of Chaos
Trinket | Best | Mark of the Champion
Trinket | Best | Neltharion's Tear
Trinket | Best | The Restrained Essence of Sapphiron
Trinket | Mediocre | Zandalarian Hero Charm
Trinket | Mediocre | Rune of the Dawn
Main Hand | Best | Brimstone Staff
Main Hand | Great | Soulseeker
Main Hand | Mediocre | Blessed Qiraji Acolyte Staff
Main Hand | Mediocre | Staff of the Shadow Flame
Main Hand | Best | The End of Dreams
Main Hand | Good | Lok'amir il Romathis
Main Hand | Good | Midnight Haze
Main Hand | Mediocre | Claw of Chromaggus
Off Hand | Best | Sapphiron's Left Eye
Off Hand | Great | Royal Scepter of Vek'lor
Off Hand | Mediocre | Jin'do's Bag of Whammies
Off Hand | Mediocre | Scepter of Interminable Focus
Off Hand | Mediocre | Talon of Furious Concentration
"""

out={}; unmatched=collections.defaultdict(list)
for spec,raw in RAW.items():
    d={}
    for line in raw.strip().splitlines():
        slot,rank,names=[x.strip() for x in line.split("|",2)]
        sl=SLOT[slot.lower()]
        t=tier(rank)
        for nm in [x.strip() for x in names.split(" / ")]:
            if nm not in NAMES: unmatched[spec].append(nm); continue
            cur=d.setdefault(sl,[])
            prev=[i for i,(t0,n0) in enumerate(cur) if n0==nm]
            if prev:
                if t<cur[prev[0]][0]: cur[prev[0]]=(t,nm)
            else: cur.append((t,nm))
    out[spec]={sl:[[t,n] for t,n in v] for sl,v in d.items()}

json.dump(out,open("guides_druid.json","w"),indent=1,ensure_ascii=False)
for spec,d in out.items():
    print("== %-12s %d entries, %d slots"%(spec,sum(len(v) for v in d.values()),len(d)))
if unmatched:
    for s,v in unmatched.items(): print("UNMATCHED %s (%d): %s"%(s,len(v),v))
