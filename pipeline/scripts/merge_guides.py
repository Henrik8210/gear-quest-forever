import json, re, collections

items = json.load(open("items.json"))
names = set()
for it in items.values():
    names.add(it["name"])

def rejoin(lst):
    """Fix comma-split item names like 'Gressil','Dawn of Ruin'."""
    out=[]; i=0
    while i < len(lst):
        cur = lst[i].strip()
        if cur in names:
            out.append(cur); i+=1; continue
        joined=None
        for k in (1,2):
            if i+k < len(lst):
                cand = ", ".join(x.strip() for x in lst[i:i+k+1])
                if cand in names:
                    joined=(cand,k); break
        if joined:
            out.append(joined[0]); i += joined[1]+1
        else:
            out.append(cur); i+=1
    return out

# --- Henrik's supplied guides -------------------------------------------------
TANK = {
"Head":"Conqueror's Crown, Dreadnaught Helmet, Field Marshal's Plate Helm, Warlord's Plate Headpiece, Helm of Endless Rage, Helm of Domination",
"Neck":"Sadist's Collar, Stormrage's Talisman of Seething, Pendant of the Qiraji Guardian, Pendant of the Shifting Sands, Amulet of the Darkmoon, Mark of C'Thun, Onyxia Tooth Pendant",
"Shoulder":"Conqueror's Spaulders, Field Marshal's Plate Shoulderguards, Warlord's Plate Shoulders, Dreadnaught Pauldrons, Drake Talon Pauldrons, Pauldrons of the Unrelenting",
"Back":"Cloak of the Fallen God, Cloak of the Golden Hive, Cloak of the Scourge, Cloak of Concentrated Hatred, Drape of Unyielding Strength, Elementium Threaded Cloak, Cryptfiend Silk Cloak",
"Chest":"Conqueror's Breastplate, Dreadnaught Breastplate, Field Marshal's Plate Armor, Warlord's Plate Armor, Breastplate of Annihilation, Zandalar Vindicator's Breastplate",
"Wrist":"Dreadnaught Bracers, Bracers of Brutality, Bracelets of Wrath, Hive Defiler Wristguards, Berserker Bracers, Zandalar Vindicator's Armguards, Qiraji Execution Bracers",
"Hands":"Gauntlets of Annihilation, Gauntlets of Steadfast Determination, Edgemaster's Handguards, Aged Core Leather Gloves, Marshal's Plate Gauntlets, General's Plate Gauntlets, Dreadnaught Gauntlets",
"Waist":"Girdle of the Mentor, Onslaught Girdle, Triad Girdle, Royal Qiraji Belt, Dreadnaught Waistguard",
"Legs":"Conqueror's Legguards, Marshal's Plate Legguards, General's Plate Leggings, Dreadnaught Legplates",
"Feet":"Dreadnaught Sabatons, Conqueror's Greaves, Marshal's Plate Boots, General's Plate Boots, Chromatic Boots, Boots of the Fallen Hero",
"Finger":"Master Dragonslayer's Ring, Circle of Applied Force, Ring of the Godslayer, Archimtiros' Ring of Reckoning, Ring of the Dreadnaught, Signet of the Fallen Defender, Ring of Emperor Vek'lor, Signet Ring of the Bronze Dragonflight, Band of Accuria, Don Julio's Band",
"Trinket":"Kiss of the Spider, Mark of the Champion, Earthstrike, Drake Fang Talisman, Jom Gabbar, Diamond Flask, Hand of Justice, Lifegiving Gem, Nat Pagle's Broken Reel",
"MainHand":"The Hungering Cold, Thunderfury, Blessed Blade of the Windseeker, Iblis, Blade of the Fallen Seraph, Widow's Remorse, Grand Marshal's Swiftblade, High Warlord's Quickblade, Warblade of the Hakkari, Ravencrest's Legacy, Maladath, Runed Blade of the Black Flight, Blackguard, Kingsfall, Death's Sting, Harbinger of Doom, Maexxna's Fang, Blessed Qiraji Pugio, Shadowsong's Sorrow, Grand Marshal's Dirk, High Warlord's Razor",
"SecondaryHand":"The Face of Death, Grand Marshal's Aegis, High Warlord's Shield Wall, The Plague Bearer, Blessed Qiraji Bulwark, Elementium Reinforced Bulwark, Force Reactive Disk",
"Ranged":"Crossbow of Imminent Doom, Soulstring, Toxin Injector, Heartstriker, Dragonbreath Hand Cannon, Mandokir's Sting, Polished Ironwood Crossbow, Blastershot Launcher, Striker's Mark, Blackcrow, Satyr's Bow",
}
FURY = {
"Head":"Lionheart Helm, Helm of Endless Rage, Conqueror's Crown, Southwind Helm, Crown of Destruction, Field Marshal's Plate Helm, Warlord's Plate Headpiece, Lizardscale Eyepatch, Lieutenant Commander's Plate Helm, Champion's Plate Helm",
"Neck":"Stormrage's Talisman of Seething, Barbed Choker, The Eye of Hakkar, Onyxia Tooth Pendant, Fury of the Forgotten Swarm",
"Shoulder":"Conqueror's Spaulders, Mantle of Wicked Revenge, Field Marshal's Plate Shoulderguards, Warlord's Plate Shoulders, Drake Talon Pauldrons, Lieutenant Commander's Plate Shoulders, Champion's Plate Shoulders",
"Back":"Shroud of Dominion, Cloak of the Fallen God, Cloak of Draconic Might, Cloak of Concentrated Hatred, Drape of Unyielding Strength, Puissant Cape",
"Chest":"Plated Abomination Ribcage, Ghoul Skin Tunic, Breastplate of Annihilation, Conqueror's Breastplate, Vest of Swift Execution, Savage Gladiator Chain",
"Wrist":"Wristguards of Vengeance, Hive Defiler Wristguards, Qiraji Execution Bracers, Bracers of Brutality, Deeprock Bracers",
"Hands":"Gauntlets of Annihilation, Edgemaster's Handguards, Gloves of Enforcement, Sacrificial Gauntlets",
"Waist":"Girdle of the Mentor, Onslaught Girdle, Belt of Never-ending Agony, Triad Girdle, Zandalar Vindicator's Belt",
"Legs":"Legplates of Carnage, Leggings of Apocalypse, Conqueror's Legguards, Titanic Leggings, Marshal's Plate Legguards, General's Plate Leggings, Scaled Sand Reaver Leggings",
"Feet":"Chromatic Boots, Boots of the Vanguard, Boots of the Fallen Hero, Marshal's Plate Boots, General's Plate Boots, Slime Kickers",
"Finger":"Band of Unnatural Forces, Quick Strike Ring, Ring of the Qiraji Fury, Circle of Applied Force, Master Dragonslayer's Ring, Don Julio's Band, Band of Earthen Might, Signet of Unyielding Strength, Signet Ring of the Bronze Dragonflight, Band of Accuria",
"Trinket":"Kiss of the Spider, Mark of the Champion, Slayer's Crest, Diamond Flask, Jom Gabbar, Earthstrike, Drake Fang Talisman, Hand of Justice, Badge of the Swarmguard, Fetish of the Sand Reaver",
"MainHand":"Gressil, Dawn of Ruin, The Castigator, Empyrean Demolisher, Misplaced Servo Arm, Iblis, Blade of the Fallen Seraph, Grand Marshal's Longsword, Chromatically Tempered Sword, Ancient Qiraji Ripper, Hatchet of Sundered Bone, High Warlord's Cleaver, Blessed Qiraji War Axe, Crul'shorukh, Edge of Chaos, Deathbringer",
"SecondaryHand":"The Hungering Cold, The Castigator, Iblis, Blade of the Fallen Seraph, Grand Marshal's Swiftblade, Chromatically Tempered Sword, Maladath, Runed Blade of the Black Flight, Misplaced Servo Arm, Anubisath Warhammer, Ancient Qiraji Ripper, Brutality Blade, High Warlord's Cleaver, Crul'shorukh, Edge of Chaos, Blessed Qiraji War Axe, Doom's Edge, Zulian Hacker, Sickle of Unyielding Strength",
"Ranged":"Nerubian Slavemaker, Soulstring, Larvae of the Great Worm, Crossbow of Imminent Doom, Striker's Mark, Gurubashi Dwarf Destroyer, Bloodseeker, Blastershot Launcher, The Purifier",
}

def parse(d):
    return {sl: rejoin([x.strip() for x in s.split(",")]) for sl, s in d.items()}

tank, fury = parse(TANK), parse(FURY)

g = json.load(open("guides_warrior.json"))
# 1. repair existing comma-split names
for spec in g:
    for sl in g[spec]:
        g[spec][sl] = rejoin(g[spec][sl])

def union(spec, src, slots=None, skip=()):
    for sl, lst in src.items():
        if slots and sl not in slots: continue
        if sl in skip: continue
        tgt = g[spec].setdefault(sl, [])
        for n in lst:
            if n not in tgt: tgt.append(n)

ARMOUR = [s for s in FURY if s not in ("MainHand","SecondaryHand")]
# arms: keep MainHand two-handers only (spec is 2H); take everything else from fury
union("arms", fury, slots=ARMOUR)
# fury: full merge
union("fury", fury)
# protection: tank guide; off-hand weapons excluded (shield spec) -> SecondaryHand = shields only
union("protection", tank)

unmatched = collections.defaultdict(list)
for spec in g:
    for sl, lst in g[spec].items():
        for n in lst:
            if n not in names: unmatched[spec].append((sl,n))

json.dump(g, open("guides_warrior.json","w"), indent=1, ensure_ascii=False)
for spec in g:
    print("==", spec, sum(len(v) for v in g[spec].values()))
    for sl,v in g[spec].items(): print("   ", sl, len(v))
print()
for spec, u in unmatched.items():
    print("UNMATCHED", spec, len(u))
    for sl,n in u: print("   ", sl, "|", n)
