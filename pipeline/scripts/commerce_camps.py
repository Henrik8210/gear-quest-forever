"""Forever Merchant's Favor camps that sell crafted-gear recipes.

Horde: Durotar Supply and Logistics, northwest of the Crossroads in The Barrens.
Alliance: Azeroth Commerce Authority, Three Corners in Redridge Mountains.

The crafted item is often named differently from the pattern (Stormrider's
Leather Armor vs Tunic, Pants vs Kilt, Helm vs Hood). Any piece of those named
sets points at the same camp vendor.
"""

from __future__ import annotations

HORDE_WHERE = (
    "the Durotar Supply and Logistics camp northwest of the Crossroads in The Barrens"
)
ALLIANCE_WHERE = (
    "the Azeroth Commerce Authority camp at Three Corners in Redridge Mountains"
)

# profession -> (horde vendor, alliance vendor)
VENDORS = {
    "Leatherworking": ("Pawani", "Daniel Stitchsong"),
    "Blacksmithing": ("Gor'mak", "Stondry Darkhammer"),
    "Tailoring": ("Jim'bek", "Mivin Shadowweave"),
    "Enchanting": ("Beneris", "Alynsia"),
    "Engineering": ("Fizzlefuse", "Fritz Fizzle"),
}

# Crafted item names (the recipe name without Pattern / Plans / Formula / Schematic).
OUTPUTS = {
    "Leatherworking": [
        "Wisdom's Leather Belt", "Defender's Leather Belt", "Brawler's Leather Belt",
        "Totemic Leather Belt", "Trapper's Leather Belt", "Stormrider's Leather Belt",
        "Stormrider's Leather Tunic", "Trapper's Leather Tunic", "Defender's Leather Tunic",
        "Brawler's Leather Tunic", "Totemic Leather Tunic", "Wisdom's Leather Tunic",
        "Wisdom's Leather Leggings", "Trapper's Leather Legguards", "Brawler's Leather Legguards",
        "Totemic Leather Leggings", "Defender's Leather Kilt", "Stormrider's Leather Kilt",
        "Wisdom's Leather Hood", "Trapper's Leather Gloves", "Wisdom's Leather Gloves",
        "Defender's Leather Gloves", "Totemic Leather Gloves", "Stormrider's Leather Gloves",
        "Brawler's Leather Gloves", "Defender's Leather Boots", "Wisdom's Leather Boots",
        "Totemic Leather Boots", "Stormrider's Leather Boots", "Brawler's Leather Boots",
        "Trapper's Leather Boots", "Trapper's Leather Hood", "Brawler's Leather Hood",
        "Totemic Leather Hood", "Stormrider's Leather Hood", "Defender's Leather Hood",
        "Prowler's Leather Gloves", "Skycaller's Leather Gloves", "Stalker's Leather Gloves",
        "Mender's Leather Gloves", "Warden's Leather Shoulder", "Skycaller's Mail Shoulder",
        "Mender's Mail Shoulder", "Prowler's Leather Shoulder", "Skulker's Leather Gloves",
        "Skirmisher's Mail Gloves", "Warden's Leather Gloves", "Stalker's Mail Shoulder",
        "Skulker's Leather Shoulder", "Skirmisher's Mail Shoulder", "Mender's Leather Shoulder",
        "Skycaller's Leather Shoulder", "Skycaller's Mail Bracers", "Skulker's Leather Waistguard",
        "Mender's Leather Bracers", "Stalker's Mail Bracers", "Skulker's Leather Bracers",
        "Skirmisher's Mail Bracers", "Skycaller's Leather Bracers", "Warden's Leather Bracers",
        "Mender's Mail Bracers", "Skycaller's Leather Boots", "Mender's Leather Boots",
        "Skirmisher's Mail Sabatons", "Mender's Mail Sabatons", "Skycaller's Mail Sabatons",
        "Prowler's Leather Boots", "Warden's Leather Boots", "Skulker's Leather Boots",
        "Stalker's Mail Sabatons", "Prowler's Leather Waistguard", "Skycaller's Leather Waistguard",
        "Stalker's Mail Belt", "Skycaller's Mail Belt", "Mender's Mail Belt",
        "Warden's Leather Waistguard", "Mender's Leather Waistguard", "Skirmisher's Mail Belt",
        "Prowler's Leather Bracers",
    ],
    "Tailoring": [
        "Shining Boots", "Shadow Boots", "Pristine Boots", "Pearly Boots", "Flame Boots", "Silky Boots",
        "Shining Gown", "Shadow Gown", "Pristine Gown", "Pearly Gown", "Flame Gown", "Silky Gown",
        "Shining Circlet", "Shadow Circlet", "Pristine Circlet", "Pearly Circlet", "Flame Circlet", "Silky Circlet",
        "Shining Sash", "Shadow Sash", "Pristine Sash", "Pearly Sash", "Flame Sash", "Silky Sash",
        "Shining Gloves", "Shadow Gloves", "Pristine Gloves", "Pearly Gloves", "Flame Gloves", "Silky Gloves",
        "Flame Leggings", "Pearly Leggings", "Pristine Leggings", "Shadow Leggings", "Shining Leggings", "Silky Leggings",
        "Netherfroth Shoulders", "Netherflame Shoulders", "Radiant Handwraps", "Golden Handwraps",
        "Frothing Handwraps", "Fiery Handwraps", "Black Handwraps", "Netherpearl Shoulders",
        "Nethershine Shoulders", "Netherflame Cuffs", "Netherfroth Cuffs", "Nethergeld Cuffs",
        "Netherlight Cuffs", "Netherpearl Cuffs", "Nethershine Cuffs", "Black Waistcord",
        "Fiery Waistcord", "Frothing Waistcord", "Gilded Waistcord", "Golden Waistcord",
        "Radiant Waistcord", "Netherlight Shoulders", "Nethergeld Shoulders",
        "Gilded Sandals", "Frothing Sandals", "Black Sandals", "Fiery Sandals", "Golden Sandals", "Radiant Sandals",
    ],
    "Blacksmithing": [
        "Guard's Chain Belt", "Crusader's Chain Belt", "Acolyte's Chain Belt", "Protector's Chain Belt", "Veteran's Chain Belt",
        "Protector's Boots", "Guard's Boots", "Crusader's Boots", "Acolyte's Boots", "Veteran's Boots",
        "Guard's Gloves", "Crusader's Gloves", "Acolyte's Gloves", "Protector's Gloves", "Veteran's Gloves",
        "Veteran's Silvered Chain Leggings", "Protector's Silvered Chain Leggings", "Guard's Silvered Chain Leggings",
        "Crusader's Silvered Chain Leggings", "Acolyte's Silvered Chain Leggings",
        "Veteran's Silvered Chain Shirt", "Protector's Silvered Chain Shirt", "Guard's Silvered Chain Shirt",
        "Crusader's Silvered Chain Shirt", "Acolyte's Silvered Chain Shirt",
        "Veteran's Silvered Chain Helm", "Protector's Silvered Chain Helm", "Guard's Silvered Chain Helm",
        "Crusader's Silvered Chain Helm", "Acolyte's Silvered Chain Helm",
        "Justicar's Gauntlet", "Officer's Gauntlet", "Prefect's Gauntlet", "Sentinel's Gauntlet", "Warder's Gauntlet",
        "Justicar's Pauldrons", "Officer's Pauldrons", "Prefect's Pauldrons", "Sentinel's Pauldrons", "Warder's Pauldrons",
        "Justicar's Wristguards", "Prefect's Wristguard", "Warder's Wristguard", "Sentinel's Wristguard", "Officer's Wristguard",
        "Warder's Waistguard", "Justicar's Sabatons", "Officer's Sabatons", "Prefect's Sabatons", "Sentinel's Sabatons", "Warder's Sabatons",
        "Justicar's Waistguard", "Officer's Waistguard", "Prefect's Waistguard", "Sentinel's Waistguard",
        "Thorium Cestus", "Thorium Greatmace", "Enriched Thorium Breastplate", "Enriched Thorium Helm", "Enriched Thorium Leggings",
        "Legionite Glaive",
    ],
    "Enchanting": [
        "Tenets of the Silver Hand", "Polished Driftwood Icon", "Mystic Mushroom", "Soulstaff",
        "Orb of Souls", "Orb of Mystic Insight", "Glimmering Staff", "Dreamstaff",
        "Totem of Ancestral Protection", "Talons of Wrath", "Libram of Invocation",
        "Twisting Essence Jar", "Truesilver Conduit", "Radiant Staff", "Brilliant Wand",
        "Idol of the Dream", "Libram of Holy Alacrity", "Totem of Thunder",
    ],
    "Engineering": [
        "Whimsical Waistwrap", "Gizmo Girdle", "Clanking Cord", "Floppy Goggles", "Stuckbutton Goggles",
        "Dented Goggles", "Bent Goggles", "Emergency Field Cloak",
        "Satchel of Copper Bombs", "Satchel of Bronze Bombs", "Satchel of Iron Bombs", "Satchel of Dark Iron Bombs",
    ],
}

# Whole sets. The pattern name and the item name do not always match.
SET_PREFIX = {
    "Leatherworking": (
        "Brawler's ", "Defender's ", "Totemic ", "Trapper's ", "Stormrider's ", "Wisdom's ",
        "Prowler's ", "Skycaller's ", "Stalker's ", "Mender's ", "Warden's ", "Skulker's ", "Skirmisher's ",
    ),
    "Blacksmithing": (
        "Guard's ", "Crusader's ", "Acolyte's ", "Protector's ", "Veteran's ",
        "Justicar's ", "Officer's ", "Prefect's ", "Sentinel's ", "Warder's ",
        "Enriched Thorium ",
    ),
    "Tailoring": (
        "Netherfroth ", "Netherflame ", "Netherpearl ", "Nethershine ", "Nethergeld ", "Netherlight ",
        "Filigreed ",
        # Same dyes as the sold sandals / waistcords / handwraps. The item is often
        # Slippers, Cord, or Gloves instead.
        "Gilded ", "Frothing ", "Fiery ", "Black ", "Golden ", "Radiant ",
    ),
}

_EXACT = []
for _prof, _names in OUTPUTS.items():
    for _name in _names:
        _EXACT.append((_name.lower(), _prof))
_EXACT.sort(key=lambda row: len(row[0]), reverse=True)


def _options(exact_l):
    opts = [exact_l]
    if exact_l.endswith("shoulder") or exact_l.endswith("wristguard"):
        opts.append(exact_l + "s")
    return opts


def camp_profession(item_name):
    """Return the camp profession when this crafted name belongs to a camp set."""
    if not item_name:
        return None
    low = item_name.lower()
    for exact_l, prof in _EXACT:
        for opt in _options(exact_l):
            if low == opt or low.endswith(" " + opt):
                return prof
    for prof, prefixes in SET_PREFIX.items():
        for prefix in prefixes:
            if item_name.startswith(prefix):
                return prof
    return None


def camp_instructions(item_name, profession=None):
    """Full hunt sentence, or None when this craft is not a camp recipe."""
    prof = camp_profession(item_name)
    if not prof:
        return None
    if profession and profession != prof:
        return None
    horde, alliance = VENDORS[prof]
    return (
        f"Crafted with {prof}. "
        f"You can buy the recipe from {horde} at {HORDE_WHERE}, "
        f"or from {alliance} at {ALLIANCE_WHERE}."
    )
