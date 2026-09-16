local _, GQ = ...

GQ.Data = GQ.Data or {}

-- Curated BiS lists (user-defined order via curatedRank 1 = best).
-- Early Alliance mail melee bands. Item required level gates obtain checks in Equip.lua.

local ALLIANCE = { Alliance = true }
local ALLIANCE_MAIL = { WARRIOR = true, PALADIN = true }
local EARLY_MIN = 1
local EARLY_MAX = 8
local LEVEL1_MAX = 1
local LEVEL2_MIN = 2
local LEVEL2_MAX = 2
local LEVEL3_MIN = 3
local LEVEL3_MAX = 3
local EARLY4_MAX = 4
local LEVEL5_MIN = 5
local LEVEL5_MAX = 10
local LEVEL6_MIN = 6
local LEVEL6_MAX = 12
local LEVEL7_MIN = 7
local LEVEL7_MAX = 12
local LEVEL8_MIN = 8
local LEVEL8_MAX = 12
local LEVEL9_MIN = 9
local LEVEL9_MAX = 14
local LEVEL10_MIN = 10
local LEVEL10_MAX = 16
local SPEC_HOLY = { holy = true }
local SPEC_PROTECTION = { protection = true }
local SPEC_RETRIBUTION = { retribution = true }
local SPEC_SHADOW = { shadow = true }
local MAIL_MELEE = ALLIANCE_MAIL
local SPEC_MELEE = { retribution = true, protection = true }
local SPEC_RET = { retribution = true }
local SPEC_PROT = { protection = true }

-- Second ring-slot milestone: level 10 band adds more Finger upgrades.
GQ.Data.RING_SLOT_2_MILESTONE_LEVEL = 10

-- Crafted output names for trainer matching when GetItemInfo is not cached yet.
local PROFESSION_ITEM_NAMES = {
    [10421] = "Rough Copper Vest",
    [2853] = "Copper Bracers",
    [3469] = "Copper Chain Boots",
    [2852] = "Copper Chain Pants",
    [3471] = "Copper Chain Vest",
    [2851] = "Copper Chain Belt",
    [2580] = "Reinforced Linen Cape",
    [2570] = "Linen Cloak",
    [3472] = "Runed Copper Gauntlets",
    [2310] = "Embossed Leather Cloak",
    [3473] = "Runed Copper Pants",
    [3474] = "Gemmed Copper Gauntlets",
    [3488] = "Copper Battle Axe",
    [21931] = "Woven Copper Ring",
}

local MIDSUMMER_CROWN =
    "During the Midsummer Fire Festival, complete A Thief's Reward in a capital city after stealing the opposing faction's bonfire flames (or turn in if you finished in a previous year). Usable from level 1."

GQ.Data.entries = {
    -- Head — all classes / factions (seasonal)
    {
        id = "early4_all_head_crown_fire_festival",
        itemId = 23323,
        slot = "Head",
        minLevel = EARLY_MIN,
        maxLevel = EARLY_MAX,
        curatedRank = 1,
        sourceType = "seasonal_quest",
        instructions = MIDSUMMER_CROWN,
        zone = "Capital Cities",
        questName = "A Thief's Reward",
    },

    -- Level 1 band — Alliance mail melee (warrior / paladin)
    {
        id = "early1_back_linen_cloak",
        itemId = 2570,
        slot = "Back",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Learn Linen Cloak from a Tailoring trainer and craft at a loom (Tailoring 1). Requires Linen Cloth from humanoid drops or vendors.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_back_flimsy_chain_cloak",
        itemId = 2652,
        slot = "Back",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Cloak is a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_back_loose_chain_cloak",
        itemId = 2644,
        slot = "Back",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Loose Chain Cloak (req 1) is a grey world drop from low-level humanoids in Alliance starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_chest_frostmane_chain_vest",
        itemId = 2109,
        slot = "Chest",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Kill Grik'nir the Cold in Frostmane Hovel (Coldridge Valley, Dun Morogh). Frostmane Chain Vest is a low-chance (~1%) loot drop — not a quest reward. You kill him for Ice and Fire anyway.",
        zone = "Dun Morogh",
        npc = "Grik'nir the Cold",
        questName = "Ice and Fire",
    },
    {
        id = "early1_chest_tarnished_chain_vest",
        itemId = 2379,
        slot = "Chest",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Vest from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early1_chest_flimsy_chain_vest",
        itemId = 2656,
        slot = "Chest",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Vest is a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_wrist_tarnished_chain_bracers",
        itemId = 2384,
        slot = "Wrist",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Bracers from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early1_wrist_slightly_rusted_bracers",
        itemId = 24131,
        slot = "Wrist",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete Replenishing the Healing Crystals on Azuremyst Isle and choose Slightly Rusted Bracers over the other rewards.",
        zone = "Azuremyst Isle",
        npc = "Proenitus",
        questName = "Replenishing the Healing Crystals",
    },
    {
        id = "early1_wrist_flimsy_chain_bracers",
        itemId = 2651,
        slot = "Wrist",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Bracers are a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_mainhand_bastard_sword",
        itemId = 1194,
        slot = "MainHand",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy a Bastard Sword from Janos Hammerknuckle in Northshire Abbey. Train Two-Handed Swords from a weapon master first.",
        zone = "Elwynn Forest",
        npc = "Janos Hammerknuckle",
    },
    {
        id = "early1_mainhand_broad_axe",
        itemId = 2479,
        slot = "MainHand",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy a Broad Axe from Janos Hammerknuckle in Northshire Abbey. Train Two-Handed Axes from a weapon master first.",
        zone = "Elwynn Forest",
        npc = "Janos Hammerknuckle",
    },
    {
        id = "early1_mainhand_scratched_claymore",
        itemId = 2128,
        slot = "MainHand",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Scratched Claymore is a grey two-handed sword world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_offhand_cracked_buckler",
        itemId = 2212,
        slot = "SecondaryHand",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Cracked Buckler is a grey shield world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_offhand_large_round_shield",
        itemId = 2129,
        slot = "SecondaryHand",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy a Large Round Shield from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early1_offhand_small_shield",
        itemId = 2133,
        slot = "SecondaryHand",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy a Small Shield from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early1_feet_outfitter_boots",
        itemId = 2691,
        slot = "Feet",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Skirmish at Echo Ridge in Northshire and choose Outfitter Boots over the other quest rewards.",
        zone = "Elwynn Forest",
        npc = "Marshal McBride",
        questName = "Skirmish at Echo Ridge",
    },
    {
        id = "early1_feet_tarnished_chain_boots",
        itemId = 2383,
        slot = "Feet",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Boots from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early1_feet_flimsy_chain_boots",
        itemId = 2650,
        slot = "Feet",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Boots are a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_legs_tarnished_chain_leggings",
        itemId = 2381,
        slot = "Legs",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Leggings from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early1_legs_flimsy_chain_pants",
        itemId = 2654,
        slot = "Legs",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Pants are a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_legs_loose_chain_pants",
        itemId = 2646,
        slot = "Legs",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Loose Chain Pants (req 3) are uncommon mail world drops from humanoids in Elwynn Forest.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_waist_tarnished_chain_belt",
        itemId = 2380,
        slot = "Waist",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Belt from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early1_waist_flimsy_chain_belt",
        itemId = 2649,
        slot = "Waist",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Belt is a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_waist_rustic_belt",
        itemId = 2172,
        slot = "Waist",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete A New Threat in Coldridge Valley and choose Rustic Belt over the other quest rewards.",
        zone = "Dun Morogh",
        questName = "A New Threat",
    },
    {
        id = "early1_hands_tarnished_chain_gloves",
        itemId = 2385,
        slot = "Hands",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Gloves from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early1_hands_loose_chain_gloves",
        itemId = 2645,
        slot = "Hands",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Loose Chain Gloves (req 2) are uncommon mail world drops from humanoids in Elwynn Forest.",
        zone = "Elwynn Forest",
    },
    {
        id = "early1_hands_flimsy_chain_gloves",
        itemId = 2653,
        slot = "Hands",
        minLevel = EARLY_MIN,
        maxLevel = LEVEL1_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Gloves are a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Level 2 band — Alliance mail melee (warrior / paladin)
    {
        id = "early2_back_linen_cloak",
        itemId = 2570,
        slot = "Back",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Learn Linen Cloak from a Tailoring trainer and craft at a loom (Tailoring 1). Requires Linen Cloth from humanoid drops or vendors.",
        zone = "Elwynn Forest",
    },
    {
        id = "early2_back_goat_fur_cloak",
        itemId = 2905,
        slot = "Back",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Goat Fur Cloak drops from goats and other beasts in Dun Morogh.",
        zone = "Dun Morogh",
    },
    {
        id = "early2_back_flimsy_chain_cloak",
        itemId = 2652,
        slot = "Back",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Cloak is a grey world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early2_chest_rough_copper_vest",
        itemId = 10421,
        slot = "Chest",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Rough Copper Vest from a blacksmith trainer and craft at an anvil (Blacksmithing 1, requires level 2). Best mail chest at this level.",
        zone = "Elwynn Forest",
        npc = "Smith Argus",
    },
    {
        id = "early2_chest_mountaineer_chestpiece",
        itemId = 2898,
        slot = "Chest",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Mountaineer Chestpiece (req 2) drops from low-level mobs such as Ice Claw Bears in Dun Morogh.",
        zone = "Dun Morogh",
    },
    {
        id = "early2_chest_frostmane_chain_vest",
        itemId = 2109,
        slot = "Chest",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Kill Grik'nir the Cold in Frostmane Hovel (Coldridge Valley, Dun Morogh). Frostmane Chain Vest is a low-chance (~1%) loot drop — not a quest reward. You kill him for Ice and Fire anyway.",
        zone = "Dun Morogh",
        npc = "Grik'nir the Cold",
        questName = "Ice and Fire",
    },
    {
        id = "early2_wrist_copper_bracers",
        itemId = 2853,
        slot = "Wrist",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Copper Bracers from a blacksmith trainer and craft at an anvil (Blacksmithing 1, requires level 2).",
        zone = "Elwynn Forest",
        npc = "Smith Argus",
    },
    {
        id = "early2_wrist_tarnished_chain_bracers",
        itemId = 2384,
        slot = "Wrist",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Bracers from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early2_wrist_slightly_rusted_bracers",
        itemId = 24131,
        slot = "Wrist",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "quest_reward",
        instructions = "Complete Replenishing the Healing Crystals on Azuremyst Isle and choose Slightly Rusted Bracers over the other rewards.",
        zone = "Azuremyst Isle",
        npc = "Proenitus",
        questName = "Replenishing the Healing Crystals",
    },
    {
        id = "early2_mainhand_thicket_hammer",
        itemId = 5595,
        slot = "MainHand",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Crown of the Earth in Teldrassil and choose Thicket Hammer over the Walking Stick when Tarindrella offers the reward. Train Two-Handed Maces from a weapon master first.",
        zone = "Teldrassil",
        npc = "Tarindrella",
        questName = "Crown of the Earth",
    },
    {
        id = "early2_mainhand_practice_sword",
        itemId = 8177,
        slot = "MainHand",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Practice Sword (req 2) is a grey two-handed sword world drop from low-level humanoids and beasts in starter zones. Train Two-Handed Swords from a weapon master first.",
        zone = "Elwynn Forest",
    },
    {
        id = "early2_mainhand_scratched_claymore",
        itemId = 2128,
        slot = "MainHand",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Scratched Claymore is a grey two-handed sword world drop from low-level humanoids in starter zones. Train Two-Handed Swords from a weapon master first.",
        zone = "Elwynn Forest",
    },
    {
        id = "early2_offhand_worn_large_shield",
        itemId = 2213,
        slot = "SecondaryHand",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Worn Large Shield (req 2) is a grey shield world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early2_offhand_cracked_buckler",
        itemId = 2212,
        slot = "SecondaryHand",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Cracked Buckler is a grey shield world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early2_offhand_large_round_shield",
        itemId = 2129,
        slot = "SecondaryHand",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy a Large Round Shield from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early2_feet_outfitter_boots",
        itemId = 2691,
        slot = "Feet",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Skirmish at Echo Ridge in Northshire and choose Outfitter Boots over the other quest rewards.",
        zone = "Elwynn Forest",
        npc = "Marshal McBride",
        questName = "Skirmish at Echo Ridge",
    },
    {
        id = "early2_feet_tarnished_chain_boots",
        itemId = 2383,
        slot = "Feet",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Boots from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early2_feet_flimsy_chain_boots",
        itemId = 2650,
        slot = "Feet",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Boots are a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early2_legs_beaten_chain_leggings",
        itemId = 24423,
        slot = "Legs",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Spare Parts in Ammen Vale: collect 4 Emitter Spare Parts from Nestlewood Thicket and Hills, then choose Beaten Chain Leggings from Technician Zhanaa.",
        zone = "Azuremyst Isle",
        npc = "Technician Zhanaa",
        questName = "Spare Parts",
    },
    {
        id = "early2_legs_tarnished_chain_leggings",
        itemId = 2381,
        slot = "Legs",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Leggings from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early2_legs_flimsy_chain_pants",
        itemId = 2654,
        slot = "Legs",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Pants are a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early2_waist_tarnished_chain_belt",
        itemId = 2380,
        slot = "Waist",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Belt from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early2_waist_rustic_belt",
        itemId = 2172,
        slot = "Waist",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete A New Threat in Coldridge Valley and choose Rustic Belt over the other quest rewards.",
        zone = "Dun Morogh",
        questName = "A New Threat",
    },
    {
        id = "early2_waist_flimsy_chain_belt",
        itemId = 2649,
        slot = "Waist",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Belt is a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early2_hands_loose_chain_gloves",
        itemId = 2645,
        slot = "Hands",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Loose Chain Gloves (req 2) are uncommon mail world drops from humanoids in Elwynn Forest.",
        zone = "Elwynn Forest",
    },
    {
        id = "early2_hands_tarnished_chain_gloves",
        itemId = 2385,
        slot = "Hands",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Gloves from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early2_hands_flimsy_chain_gloves",
        itemId = 2653,
        slot = "Hands",
        minLevel = LEVEL2_MIN,
        maxLevel = LEVEL2_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Gloves are a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Level 3 band — Alliance mail melee (warrior / paladin)
    {
        id = "early3_back_journeymans_cloak",
        itemId = 4662,
        slot = "Back",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Journeyman's Cloak (req 3) is a green world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_back_warriors_cloak",
        itemId = 4658,
        slot = "Back",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Warrior's Cloak (req 3) is a green world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_back_burnt_cloak",
        itemId = 4665,
        slot = "Back",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Burnt Cloak (req 3) is a green world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_chest_rough_copper_vest",
        itemId = 10421,
        slot = "Chest",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Rough Copper Vest from a blacksmith trainer and craft at an anvil (Blacksmithing 1, requires level 2). Best mail chest at this level.",
        zone = "Elwynn Forest",
        npc = "Smith Argus",
    },
    {
        id = "early3_chest_mountaineer_chestpiece",
        itemId = 2898,
        slot = "Chest",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Mountaineer Chestpiece (req 2) drops from low-level mobs such as Ice Claw Bears in Dun Morogh.",
        zone = "Dun Morogh",
    },
    {
        id = "early3_chest_frostmane_chain_vest",
        itemId = 2109,
        slot = "Chest",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Kill Grik'nir the Cold in Frostmane Hovel (Coldridge Valley, Dun Morogh). Frostmane Chain Vest is a low-chance (~1%) loot drop — not a quest reward. You kill him for Ice and Fire anyway.",
        zone = "Dun Morogh",
        npc = "Grik'nir the Cold",
        questName = "Ice and Fire",
    },
    {
        id = "early3_wrist_chargers_bindings",
        itemId = 15474,
        slot = "Wrist",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Charger's Bindings (req 3) are a green mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_wrist_copper_bracers",
        itemId = 2853,
        slot = "Wrist",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Copper Bracers from a blacksmith trainer and craft at an anvil (Blacksmithing 1, requires level 2).",
        zone = "Elwynn Forest",
        npc = "Smith Argus",
    },
    {
        id = "early3_wrist_tarnished_chain_bracers",
        itemId = 2384,
        slot = "Wrist",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Bracers from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early3_mainhand_beatstick",
        itemId = 3190,
        slot = "MainHand",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Beatstick (req 3) is a green two-handed mace world drop from low-level humanoids in starter zones. Train Two-Handed Maces from a weapon master first.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_mainhand_large_axe",
        itemId = 2491,
        slot = "MainHand",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy a Large Axe from Janos Hammerknuckle in Northshire or Andrew Krighton in Goldshire. Train Two-Handed Axes from a weapon master first.",
        zone = "Elwynn Forest",
        npc = "Janos Hammerknuckle",
    },
    {
        id = "early3_mainhand_wood_chopper",
        itemId = 3189,
        slot = "MainHand",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Wood Chopper (req 3) is a green two-handed axe world drop from low-level humanoids in starter zones. Train Two-Handed Axes from a weapon master first.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_offhand_small_targe",
        itemId = 17186,
        slot = "SecondaryHand",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy a Small Targe from Andrew Krighton in Goldshire, Quartermaster Hudson in Northshire, or another shield vendor in a starter city.",
        zone = "Elwynn Forest",
        npc = "Andrew Krighton",
    },
    {
        id = "early3_offhand_burnt_buckler",
        itemId = 15895,
        slot = "SecondaryHand",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Burnt Buckler (req 3) is a green shield world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_offhand_chargers_shield",
        itemId = 15478,
        slot = "SecondaryHand",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Charger's Shield (req 3) is a green mail shield world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_feet_bloody_chain_boots",
        itemId = 18612,
        slot = "Feet",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Bloody Chain Boots (req 3) drop from Fury Shelda, a rare spawn in southern Teldrassil.",
        zone = "Teldrassil",
        npc = "Fury Shelda",
    },
    {
        id = "early3_feet_outfitter_boots",
        itemId = 2691,
        slot = "Feet",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete Skirmish at Echo Ridge in Northshire and choose Outfitter Boots over the other quest rewards.",
        zone = "Elwynn Forest",
        npc = "Marshal McBride",
        questName = "Skirmish at Echo Ridge",
    },
    {
        id = "early3_feet_tarnished_chain_boots",
        itemId = 2383,
        slot = "Feet",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Boots from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early3_legs_loose_chain_pants",
        itemId = 2646,
        slot = "Legs",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Loose Chain Pants (req 3) are uncommon mail world drops from humanoids in Elwynn Forest.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_legs_beaten_chain_leggings",
        itemId = 24423,
        slot = "Legs",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete Spare Parts in Ammen Vale: collect 4 Emitter Spare Parts from Nestlewood Thicket and Hills, then choose Beaten Chain Leggings from Technician Zhanaa.",
        zone = "Azuremyst Isle",
        npc = "Technician Zhanaa",
        questName = "Spare Parts",
    },
    {
        id = "early3_legs_tarnished_chain_leggings",
        itemId = 2381,
        slot = "Legs",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Leggings from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early3_waist_warriors_girdle",
        itemId = 4659,
        slot = "Waist",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Warrior's Girdle (req 3) is a green mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_waist_loose_chain_belt",
        itemId = 2635,
        slot = "Waist",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Loose Chain Belt (req 3) is an uncommon mail world drop from humanoids in Elwynn Forest.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_waist_tarnished_chain_belt",
        itemId = 2380,
        slot = "Waist",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Belt from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early3_hands_loose_chain_gloves",
        itemId = 2645,
        slot = "Hands",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Loose Chain Gloves (req 2) are uncommon mail world drops from humanoids in Elwynn Forest.",
        zone = "Elwynn Forest",
    },
    {
        id = "early3_hands_tarnished_chain_gloves",
        itemId = 2385,
        slot = "Hands",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Gloves from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early3_hands_flimsy_chain_gloves",
        itemId = 2653,
        slot = "Hands",
        minLevel = LEVEL3_MIN,
        maxLevel = LEVEL3_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Flimsy Chain Gloves are a grey mail world drop from low-level humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Levels 2–4 band — Alliance mail melee
    {
        id = "early4_back_infantry_cloak",
        itemId = 6508,
        slot = "Back",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Infantry Cloak (8 armor, req 4) is a green world drop or vendor find in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early4_back_pioneer_cloak",
        itemId = 6520,
        slot = "Back",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Pioneer Cloak (8 armor, req 4) is a green world drop in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early4_back_battle_chain_cloak",
        itemId = 4668,
        slot = "Back",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Battle Chain Cloak (8 armor, req 4) drops from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Chest
    {
        id = "early4_chest_rough_copper_vest",
        itemId = 10421,
        slot = "Chest",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Rough Copper Vest from a blacksmith trainer and craft at an anvil (requires level 2). Best early mail chest.",
        zone = "Elwynn Forest",
        npc = "Smith Argus",
    },
    {
        id = "early4_chest_mountaineer_chestpiece",
        itemId = 2898,
        slot = "Chest",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Mountaineer Chestpiece (req 2) drops from low-level mobs such as Ice Claw Bears in Dun Morogh.",
        zone = "Dun Morogh",
    },
    {
        id = "early4_chest_tarnished_vest",
        itemId = 2379,
        slot = "Chest",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Tarnished Chain Vest from Godric Rothgar in Northshire Abbey.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },

    -- Wrist
    {
        id = "early4_wrist_battle_chain_bracers",
        itemId = 3280,
        slot = "Wrist",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Battle Chain Bracers (req 4) are green mail world drops in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early4_wrist_warriors_bracers",
        itemId = 3214,
        slot = "Wrist",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Warrior's Bracers (req 4) are green mail world drops in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early4_wrist_graystone_bracers",
        itemId = 6061,
        slot = "Wrist",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "quest_reward",
        instructions = "Complete Timberling Sprouts in Teldrassil: collect 12 Timberling Sprouts for Denalan at Lake Al'Ameth and choose Graystone Bracers over Gardening Gloves.",
        zone = "Teldrassil",
        npc = "Denalan",
        questName = "Timberling Sprouts",
    },

    -- Main Hand (two-hand)
    {
        id = "early4_mainhand_thicket_hammer",
        itemId = 5595,
        slot = "MainHand",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Crown of the Earth in Teldrassil and choose Thicket Hammer over the Walking Stick when Tarindrella offers the reward.",
        zone = "Teldrassil",
        npc = "Tarindrella",
        questName = "Crown of the Earth",
    },
    {
        id = "early4_mainhand_vile_fin_battle_axe",
        itemId = 3325,
        slot = "MainHand",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Vile Fin Battle Axe (req 4) drops from murlocs in starter zones. Train Two-Handed Axes from a weapon master first.",
        zone = "Elwynn Forest",
    },
    {
        id = "early4_mainhand_rusted_claymore",
        itemId = 2497,
        slot = "MainHand",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy a Rusted Claymore from Janos Hammerknuckle in Northshire or Andrew Krighton in Goldshire. Train Two-Handed Swords from a weapon master first.",
        zone = "Elwynn Forest",
        npc = "Janos Hammerknuckle",
    },

    -- Off Hand (shield)
    {
        id = "early4_offhand_pioneer_buckler",
        itemId = 7109,
        slot = "SecondaryHand",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Pioneer Buckler (req 4) is a green shield world drop in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early4_offhand_primal_buckler",
        itemId = 15006,
        slot = "SecondaryHand",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Primal Buckler (req 4) is a green shield world drop in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early4_offhand_warriors_buckler",
        itemId = 3648,
        slot = "SecondaryHand",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy a Warrior's Buckler (req 4) from Godric Rothgar in Northshire or Andrew Krighton in Goldshire.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },

    -- Feet
    {
        id = "early4_feet_copper_chain_boots",
        itemId = 3469,
        slot = "Feet",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Copper Chain Boots and craft at an anvil (requires level 4). Best mail boots at this band.",
        zone = "Elwynn Forest",
        npc = "Smith Argus",
    },
    {
        id = "early4_feet_loose_chain_boots",
        itemId = 2642,
        slot = "Feet",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Loose Chain Boots (req 4) are uncommon mail world drops in Elwynn Forest.",
        zone = "Elwynn Forest",
    },
    {
        id = "early4_feet_bloody_chain_boots",
        itemId = 18612,
        slot = "Feet",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Bloody Chain Boots (req 3) drop from Fury Shelda, a rare spawn in southern Teldrassil.",
        zone = "Teldrassil",
        npc = "Fury Shelda",
    },

    -- Legs
    {
        id = "early4_legs_barkmail_leggings",
        itemId = 9599,
        slot = "Legs",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete The Relics of Wakening in Teldrassil: retrieve the four relics from Ban'ethil Barrow Den for Athridas Bearmantle in Dolanaar, then choose Barkmail Leggings over the Gritroot Staff.",
        zone = "Teldrassil",
        npc = "Athridas Bearmantle",
        questName = "The Relics of Wakening",
    },
    {
        id = "early4_legs_copper_chain_pants",
        itemId = 2852,
        slot = "Legs",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Copper Chain Pants and craft at an anvil (requires level 4).",
        zone = "Elwynn Forest",
        npc = "Smith Argus",
    },
    {
        id = "early4_legs_loose_chain_pants",
        itemId = 2646,
        slot = "Legs",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Loose Chain Pants (req 3) are uncommon mail world drops in Elwynn Forest.",
        zone = "Elwynn Forest",
    },

    -- Waist
    {
        id = "early4_waist_chargers_belt",
        itemId = 15472,
        slot = "Waist",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Charger's Belt (req 4) is a green mail world drop in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early4_waist_warriors_girdle",
        itemId = 4659,
        slot = "Waist",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Warrior's Girdle (req 3) is a green mail world drop in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early4_waist_loose_chain_belt",
        itemId = 2635,
        slot = "Waist",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Loose Chain Belt (req 3) is an uncommon mail world drop in Elwynn Forest.",
        zone = "Elwynn Forest",
    },

    -- Hands
    {
        id = "early4_hands_moss_covered_gauntlets",
        itemId = 5589,
        slot = "Hands",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Oakenscowl in Teldrassil: kill Oakenscowl and bring the Gargantuan Tumor to Denalan at Lake Al'Ameth, then choose Moss-covered Gauntlets over the Dirtwood Belt.",
        zone = "Teldrassil",
        npc = "Denalan",
        questName = "Oakenscowl",
    },
    {
        id = "early4_hands_warriors_gloves",
        itemId = 2968,
        slot = "Hands",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Warrior's Gloves (req 4) are green mail world drops in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early4_hands_loose_chain_gloves",
        itemId = 2645,
        slot = "Hands",
        minLevel = LEVEL2_MIN,
        maxLevel = EARLY4_MAX,
        classes = ALLIANCE_MAIL,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Loose Chain Gloves (req 2) are uncommon mail world drops in Elwynn Forest.",
        zone = "Elwynn Forest",
    },

    -- Level 5 band — Head unchanged (early4_all_head_* above). No Shoulder entries (no armor value at low levels).

    -- Back — Alliance, all classes (level 5)
    {
        id = "early5_back_worn_hide_cloak",
        itemId = 1421,
        slot = "Back",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Worn Hide Cloak (9 armor, req 5) is a green world drop from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_back_grizzly_cape",
        itemId = 15299,
        slot = "Back",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Grizzly Cape (9 armor, req 5) is a green world drop in low-level Alliance zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_back_goat_fur_cloak",
        itemId = 2905,
        slot = "Back",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Goat Fur Cloak (9 armor) drops from goats and other beasts in Dun Morogh and similar zones.",
        zone = "Dun Morogh",
    },

    -- Chest — Alliance mail melee (level 5)
    {
        id = "early5_chest_copper_chain_vest",
        itemId = 3471,
        slot = "Chest",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Copper Chain Vest and craft at an anvil (requires level 5). Best mail chest at this level (+1 Strength).",
        zone = "Elwynn Forest",
        npc = "Smith Argus",
    },
    {
        id = "early5_chest_warriors_tunic",
        itemId = 2965,
        slot = "Chest",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Warrior's Tunic (req 6) is a green mail world drop in Alliance starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_chest_light_mail_armor",
        itemId = 2392,
        slot = "Chest",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Light Mail Armor (req 5) from Andrew Krighton in Goldshire or another mail vendor in a starter city.",
        zone = "Elwynn Forest",
        npc = "Andrew Krighton",
    },

    -- Wrist — mail melee, both factions (level 5)
    {
        id = "early5_wrist_light_chain_bracers",
        itemId = 2402,
        slot = "Wrist",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy Light Chain Bracers (req 5) from Andrew Krighton in Goldshire or another mail vendor in a starter city.",
        zone = "Elwynn Forest",
        npc = "Andrew Krighton",
    },
    {
        id = "early5_wrist_light_mail_bracers",
        itemId = 2396,
        slot = "Wrist",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Light Mail Bracers (req 5) from Andrew Krighton in Goldshire or another mail vendor in a starter city.",
        zone = "Elwynn Forest",
        npc = "Andrew Krighton",
    },
    {
        id = "early5_wrist_infantry_bracers",
        itemId = 6507,
        slot = "Wrist",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Infantry Bracers (req 5) are a green mail world drop in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Main Hand — mail melee, both factions (level 5)
    {
        id = "early5_mainhand_training_sword",
        itemId = 8178,
        slot = "MainHand",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 6.1,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Training Sword (req 5) is a green two-handed sword world drop. Train Two-Handed Swords from a weapon master first.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_mainhand_severing_axe",
        itemId = 4562,
        slot = "MainHand",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 6.2,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Severing Axe (req 5) is a green two-handed axe world drop. Train Two-Handed Axes from a weapon master first.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_mainhand_thicket_hammer",
        itemId = 5595,
        slot = "MainHand",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "quest_reward",
        instructions = "Complete Crown of the Earth in Teldrassil and choose Thicket Hammer over the Walking Stick when Tarindrella offers the reward.",
        zone = "Teldrassil",
        npc = "Tarindrella",
        questName = "Crown of the Earth",
    },

    -- Off Hand — mail melee, both factions (level 5)
    {
        id = "early5_offhand_dull_heater_shield",
        itemId = 1201,
        slot = "SecondaryHand",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy a Dull Heater Shield (req 5) from a shield vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_offhand_worn_heater_shield",
        itemId = 2376,
        slot = "SecondaryHand",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy a Worn Heater Shield (req 5) from Godric Rothgar in Northshire or Andrew Krighton in Goldshire.",
        zone = "Elwynn Forest",
        npc = "Godric Rothgar",
    },
    {
        id = "early5_offhand_small_targe",
        itemId = 1167,
        slot = "SecondaryHand",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy a Small Targe (req 5) from a shield vendor in your starter city.",
        zone = "Elwynn Forest",
    },

    -- Feet — mail melee, both factions (level 5)
    {
        id = "early5_feet_light_chain_boots",
        itemId = 2401,
        slot = "Feet",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy Light Chain Boots (req 5) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_feet_light_mail_boots",
        itemId = 2395,
        slot = "Feet",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Light Mail Boots (req 5) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_feet_chargers_boots",
        itemId = 15473,
        slot = "Feet",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Charger's Boots (req 5) are a green mail world drop in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Legs — Alliance mail melee (level 5)
    {
        id = "early5_legs_stormwind_guard_leggings",
        itemId = 6084,
        slot = "Legs",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Wanted: Hogger in Elwynn Forest and choose Stormwind Guard Leggings (+3 Strength) over the other quest rewards.",
        zone = "Elwynn Forest",
        npc = "Marshal Dughan",
        questName = "Wanted: \"Hogger\"",
    },
    {
        id = "early5_legs_warriors_pants",
        itemId = 2966,
        slot = "Legs",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Warrior's Pants (req 5) are a green mail world drop in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_legs_light_mail_leggings",
        itemId = 2394,
        slot = "Legs",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Light Mail Leggings (req 5) from Andrew Krighton in Goldshire or another mail vendor in a starter city.",
        zone = "Elwynn Forest",
        npc = "Andrew Krighton",
    },

    -- Waist — mail melee, both factions (level 5)
    {
        id = "early5_waist_light_chain_belt",
        itemId = 2399,
        slot = "Waist",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy Light Chain Belt (req 5) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_waist_light_mail_belt",
        itemId = 2393,
        slot = "Waist",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Light Mail Belt (req 5) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_waist_battle_chain_girdle",
        itemId = 4669,
        slot = "Waist",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Battle Chain Girdle (req 5) is a green mail world drop in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Hands — mail melee, both factions (level 5)
    {
        id = "early5_hands_light_mail_gloves",
        itemId = 2397,
        slot = "Hands",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy Light Mail Gloves (req 5) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_hands_chargers_handwraps",
        itemId = 15476,
        slot = "Hands",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Charger's Handwraps (req 5) are a green mail world drop in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early5_hands_light_chain_gloves",
        itemId = 2403,
        slot = "Hands",
        minLevel = LEVEL5_MIN,
        maxLevel = LEVEL5_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Light Chain Gloves (req 5) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },

    -- Level 6 band — Head unchanged (early4_all_head_*). No Shoulder entries.

    -- Back — Alliance, all classes (level 6)
    {
        id = "early6_back_cadet_cloak",
        itemId = 9761,
        slot = "Back",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy Cadet Cloak (req 6) from a cloth vendor in a starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_back_rain_spotted_cape",
        itemId = 5591,
        slot = "Back",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Rain-spotted Cape is a green world drop from humanoids in low-level Alliance zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_back_simple_cape",
        itemId = 9745,
        slot = "Back",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Simple Cape (req 6) from a cloth vendor in a starter city.",
        zone = "Elwynn Forest",
    },

    -- Chest — Alliance mail melee (level 6)
    {
        id = "early6_chest_warriors_tunic",
        itemId = 2965,
        slot = "Chest",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Warrior's Tunic (req 6) is a green mail world drop in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_chest_chargers_armor",
        itemId = 15479,
        slot = "Chest",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 8.8,
        suffixRange = "+1-2 Strength",
        instructions = "Charger's Armor (req 6) is a green mail world drop in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_chest_copper_chain_vest",
        itemId = 3471,
        slot = "Chest",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Copper Chain Vest from a blacksmith trainer and craft at an anvil (requires level 5). +1 Strength.",
        zone = "Elwynn Forest",
        npc = "Smith Argus",
    },

    -- Wrist — mail melee, both factions (level 6)
    {
        id = "early6_wrist_war_torn_bands",
        itemId = 15482,
        slot = "Wrist",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "War-torn Bands (req 6) are a green mail world drop in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_wrist_light_chain_bracers",
        itemId = 2402,
        slot = "Wrist",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Light Chain Bracers (req 5) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_wrist_light_mail_bracers",
        itemId = 2396,
        slot = "Wrist",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Light Mail Bracers (req 5) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },

    -- Main Hand — mail melee, both factions (level 6)
    {
        id = "early6_mainhand_coldridge_hammer",
        itemId = 3103,
        slot = "MainHand",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Protecting the Herd in Dun Morogh and choose Coldridge Hammer over the other rewards. Train Two-Handed Maces first.",
        zone = "Dun Morogh",
        npc = "Rudra Amberstill",
        questName = "Protecting the Herd",
    },
    {
        id = "early6_mainhand_training_sword",
        itemId = 8178,
        slot = "MainHand",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 6.1,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Training Sword (req 5) is a green two-handed sword world drop. Train Two-Handed Swords from a weapon master first.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_mainhand_severing_axe",
        itemId = 4562,
        slot = "MainHand",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 6.2,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Severing Axe (req 5) is a green two-handed axe world drop. Train Two-Handed Axes from a weapon master first.",
        zone = "Elwynn Forest",
    },

    -- Off Hand — mail melee, both factions (level 6)
    {
        id = "early6_offhand_infantry_shield",
        itemId = 7108,
        slot = "SecondaryHand",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.6,
        suffixId = 6,
        suffixRange = "+1 Strength",
        instructions = "Infantry Shield (req 6) is a green mail shield world drop with random stat bonuses.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_offhand_thuggish_shield",
        itemId = 6203,
        slot = "SecondaryHand",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Thuggish Shield (req 6) is a green shield world drop in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_offhand_tribal_buckler",
        itemId = 3649,
        slot = "SecondaryHand",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Tribal Buckler (req 6) from a shield vendor in your starter city.",
        zone = "Elwynn Forest",
    },

    -- Feet — mail melee, both factions (level 6)
    {
        id = "early6_feet_infantry_boots",
        itemId = 6506,
        slot = "Feet",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "vendor",
        instructions = "Buy Infantry Boots (req 6) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_feet_light_chain_boots",
        itemId = 2401,
        slot = "Feet",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Light Chain Boots (req 5) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_feet_light_mail_boots",
        itemId = 2395,
        slot = "Feet",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Light Mail Boots (req 5) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },

    -- Legs — Alliance mail melee (level 6)
    {
        id = "early6_legs_stormwind_guard_leggings",
        itemId = 6084,
        slot = "Legs",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Wanted: Hogger in Elwynn Forest and choose Stormwind Guard Leggings (+3 Strength, 113 armor) over the other quest rewards.",
        zone = "Elwynn Forest",
        npc = "Marshal Dughan",
        questName = "Wanted: \"Hogger\"",
    },
    {
        id = "early6_legs_chargers_pants",
        itemId = 15477,
        slot = "Legs",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 10.0,
        suffixId = 23,
        suffixRange = "+1-2 Strength",
        instructions = "Charger's Pants of Strength (req 6) are a green mail world drop in starter zones (101 armor, +1–2 Strength). Hunt the of Strength roll.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_legs_warriors_pants",
        itemId = 2966,
        slot = "Legs",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Warrior's Pants (req 5) are a green mail world drop in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Waist — mail melee, both factions (level 6)
    {
        id = "early6_waist_copper_chain_belt",
        itemId = 2851,
        slot = "Waist",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Copper Chain Belt and craft at an anvil (requires level 6), or buy from a vendor if available.",
        zone = "Elwynn Forest",
        npc = "Smith Argus",
    },
    {
        id = "early6_waist_royal_frostmane_girdle",
        itemId = 2546,
        slot = "Waist",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Royal Frostmane Girdle (req 6) drops from Frostmane trolls in Dun Morogh.",
        zone = "Dun Morogh",
    },
    {
        id = "early6_waist_shackled_girdle",
        itemId = 5592,
        slot = "Waist",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Shackled Girdle is a green mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Hands — mail melee, both factions (level 6)
    {
        id = "early6_hands_battle_chain_gloves",
        itemId = 3281,
        slot = "Hands",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Battle Chain Gloves (req 6) are a green mail world drop in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_hands_infantry_gauntlets",
        itemId = 6510,
        slot = "Hands",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Infantry Gauntlets (req 6) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early6_hands_worn_mail_gloves",
        itemId = 1734,
        slot = "Hands",
        minLevel = LEVEL6_MIN,
        maxLevel = LEVEL6_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Worn Mail Gloves from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },

    -- Level 7 band — Head unchanged (early4_all_head_*). No Shoulder entries.

    -- Back — Alliance, all classes (level 7)
    {
        id = "early7_back_reinforced_linen_cape",
        itemId = 2580,
        slot = "Back",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Tailoring",
        instructions = "Learn Reinforced Linen Cape from a Tailoring trainer and craft at a loom (Tailoring 60). +1 Intellect.",
        zone = "Stormwind City",
    },
    {
        id = "early7_back_veteran_cloak",
        itemId = 4677,
        slot = "Back",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Veteran Cloak (req 7, 11 armor) is a common world drop from humanoids in low-level Alliance zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_back_ceremonial_cloak",
        itemId = 4692,
        slot = "Back",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Ceremonial Cloak (req 7, 11 armor) is a common world drop from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Chest — Alliance mail melee (level 7)
    {
        id = "early7_chest_warriors_tunic",
        itemId = 2965,
        slot = "Chest",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Warrior's Tunic (req 6) is a green mail world drop in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_chest_explorers_vest",
        itemId = 7229,
        slot = "Chest",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete the Bashal'Aran quest chain in Darkshore (final turn-in to Asterion) and choose Explorer's Vest (+2 Stamina, +1 Intellect) over the other rewards.",
        zone = "Darkshore",
        npc = "Asterion",
        questName = "Bashal'Aran",
    },
    {
        id = "early7_chest_ravager_chitin_tunic",
        itemId = 24107,
        slot = "Chest",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "quest_reward",
        instructions = "Complete Beasts of the Apocalypse! on Azuremyst Isle (Draenei starter zone) and choose Ravager Chitin Tunic (+1 Strength) over the other rewards.",
        zone = "Azuremyst Isle",
        questName = "Beasts of the Apocalypse!",
    },

    -- Wrist — mail melee, both factions (level 7)
    {
        id = "early7_wrist_ironwrought_bracers",
        itemId = 6177,
        slot = "Wrist",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Tundra MacGrann's Stolen Stash in Dun Morogh (req 7) and choose Ironwrought Bracers over Wooly Mittens.",
        zone = "Dun Morogh",
        npc = "Tundra MacGrann",
        questName = "Tundra MacGrann's Stolen Stash",
    },
    {
        id = "early7_wrist_cadet_bracers",
        itemId = 9760,
        slot = "Wrist",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Cadet Bracers (req 7) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_wrist_brackwater_bracers",
        itemId = 3303,
        slot = "Wrist",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Brackwater Bracers (req 7) are a common mail world drop from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Main Hand — mail melee, both factions (level 7)
    {
        id = "early7_mainhand_icepane_warhammer",
        itemId = 2254,
        slot = "MainHand",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Farm Icepane Warhammer (+2 Strength) from Hammerspine in the Gol'Bolar Quarry mine in Dun Morogh. Train Two-Handed Maces first.",
        zone = "Dun Morogh",
        npc = "Hammerspine",
    },
    {
        id = "early7_mainhand_short_bastard_sword",
        itemId = 3192,
        slot = "MainHand",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 6.1,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Short Bastard Sword (req 7) is a green two-handed sword world drop. Train Two-Handed Swords from a weapon master first.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_mainhand_coldridge_hammer",
        itemId = 3103,
        slot = "MainHand",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "quest_reward",
        instructions = "Complete Protecting the Herd in Dun Morogh and choose Coldridge Hammer over the other rewards. Train Two-Handed Maces first.",
        zone = "Dun Morogh",
        npc = "Rudra Amberstill",
        questName = "Protecting the Herd",
    },

    -- Off Hand — mail melee, both factions (level 7)
    {
        id = "early7_offhand_gypsy_buckler",
        itemId = 9753,
        slot = "SecondaryHand",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.6,
        suffixId = 6,
        suffixRange = "+1 Strength",
        instructions = "Gypsy Buckler (req 7) is a green shield world drop with random stat bonuses.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_offhand_war_torn_shield",
        itemId = 15486,
        slot = "SecondaryHand",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.6,
        suffixId = 6,
        suffixRange = "+1 Strength",
        instructions = "War-torn Shield (req 7) is a green shield world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_offhand_infantry_shield",
        itemId = 7108,
        slot = "SecondaryHand",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.6,
        suffixId = 6,
        suffixRange = "+1 Strength",
        instructions = "Infantry Shield (req 6) is a green mail shield world drop with random stat bonuses.",
        zone = "Elwynn Forest",
    },

    -- Feet — mail melee, both factions (level 7)
    {
        id = "early7_feet_battle_chain_boots",
        itemId = 3279,
        slot = "Feet",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Battle Chain Boots (req 7) are a common mail world drop from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_feet_infantry_boots",
        itemId = 6506,
        slot = "Feet",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Infantry Boots (req 6) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_feet_light_chain_boots",
        itemId = 2401,
        slot = "Feet",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "vendor",
        instructions = "Buy Light Chain Boots (req 5) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },

    -- Legs — Alliance mail melee (level 7)
    {
        id = "early7_legs_stormwind_guard_leggings",
        itemId = 6084,
        slot = "Legs",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Wanted: Hogger in Elwynn Forest and choose Stormwind Guard Leggings (+3 Strength) over the other quest rewards.",
        zone = "Elwynn Forest",
        npc = "Marshal Dughan",
        questName = "Wanted: \"Hogger\"",
    },
    {
        id = "early7_legs_infantry_leggings",
        itemId = 6337,
        slot = "Legs",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.7,
        suffixId = 23,
        suffixRange = "+1-2 Strength",
        instructions = "Infantry Leggings (req 7) are a green mail world drop in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_legs_battle_chain_pants",
        itemId = 3282,
        slot = "Legs",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Battle Chain Pants (req 7) are a common mail world drop from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Waist — mail melee, both factions (level 7)
    {
        id = "early7_waist_cadet_belt",
        itemId = 9758,
        slot = "Waist",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Cadet Belt (req 7) is a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_waist_worn_mail_belt",
        itemId = 1730,
        slot = "Waist",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "vendor",
        instructions = "Buy Worn Mail Belt (req 7) from a mail armor vendor in your starter city.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_waist_copper_chain_belt",
        itemId = 2851,
        slot = "Waist",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Copper Chain Belt and craft at an anvil (requires level 6), or buy from a vendor if available.",
        zone = "Elwynn Forest",
        npc = "Smith Argus",
    },

    -- Hands — mail melee, both factions (level 7)
    {
        id = "early7_hands_runed_copper_gauntlets",
        itemId = 3472,
        slot = "Hands",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Runed Copper Gauntlets from a Blacksmithing trainer and craft at an anvil (Blacksmithing 40). Random +Agility or +Intellect.",
        zone = "Stormwind City",
    },
    {
        id = "early7_hands_war_torn_handgrips",
        itemId = 15484,
        slot = "Hands",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "War-torn Handgrips (req 7) are a green mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early7_hands_battle_chain_gloves",
        itemId = 3281,
        slot = "Hands",
        minLevel = LEVEL7_MIN,
        maxLevel = LEVEL7_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Battle Chain Gloves (req 6) are a green mail world drop in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Level 8 band — Head unchanged (early4_all_head_*). No Shoulder entries.

    -- Back — Alliance, all classes (level 8)
    {
        id = "early8_back_embossed_leather_cloak",
        itemId = 2310,
        slot = "Back",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Leatherworking",
        instructions = "Learn Embossed Leather Cloak from a Leatherworking trainer and craft at a workbench (Leatherworking 60). +1 Stamina.",
        zone = "Stormwind City",
    },
    {
        id = "early8_back_brackwater_cloak",
        itemId = 4680,
        slot = "Back",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Brackwater Cloak (req 8, 12 armor) is a common world drop from humanoids in low-level Alliance zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early8_back_hunting_cloak",
        itemId = 4689,
        slot = "Back",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Hunting Cloak (req 8, 12 armor) is a common world drop from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Chest — Alliance mail melee (level 8)
    {
        id = "early8_chest_infantry_tunic",
        itemId = 6336,
        slot = "Chest",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.8,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Infantry Tunic of Strength (req 8) is a green mail world drop (+3-4 Strength, ~9.8% of rolls).",
        zone = "Elwynn Forest",
    },
    {
        id = "early8_chest_ironheart_chain",
        itemId = 3166,
        slot = "Chest",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete Filthy Paws in Loch Modan — collect 4 Miners' Gear from Silver Stream Mine and return to Mountaineer Stormpike. Choose Ironheart Chain over Ironplate Buckler and Robe of the Keeper.",
        zone = "Loch Modan",
        npc = "Mountaineer Stormpike",
        questName = "Filthy Paws",
    },
    {
        id = "early8_chest_battle_chain_tunic",
        itemId = 3283,
        slot = "Chest",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Battle Chain Tunic (req 8) is a common mail world drop from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Wrist — mail melee, both factions (level 8)
    {
        id = "early8_wrist_veteran_bracers",
        itemId = 3213,
        slot = "Wrist",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Veteran Bracers (req 8) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early8_wrist_ironwrought_bracers",
        itemId = 6177,
        slot = "Wrist",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete Tundra MacGrann's Stolen Stash in Dun Morogh (req 7) and choose Ironwrought Bracers over Wooly Mittens.",
        zone = "Dun Morogh",
        npc = "Tundra MacGrann",
        questName = "Tundra MacGrann's Stolen Stash",
    },
    {
        id = "early8_wrist_cadet_bracers",
        itemId = 9760,
        slot = "Wrist",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Cadet Bracers (req 7) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Main Hand — mail melee, both factions (level 8)
    {
        id = "early8_mainhand_spiked_club",
        itemId = 4564,
        slot = "MainHand",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 5.9,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Spiked Club of Strength (req 8) is a green two-handed mace world drop (+3-4 Strength, ~5.9% of rolls). Train Two-Handed Maces first.",
        zone = "Westfall",
    },
    {
        id = "early8_mainhand_copper_battle_axe",
        itemId = 3488,
        slot = "MainHand",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Copper Battle Axe from a Blacksmithing trainer and craft at an anvil (Blacksmithing 35). Train Two-Handed Axes first.",
        zone = "Stormwind City",
    },
    {
        id = "early8_mainhand_icepane_warhammer",
        itemId = 2254,
        slot = "MainHand",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Farm Icepane Warhammer (+2 Strength) from Hammerspine in the Gol'Bolar Quarry mine in Dun Morogh. Train Two-Handed Maces first.",
        zone = "Dun Morogh",
        npc = "Hammerspine",
    },

    -- Off Hand — mail melee, both factions (level 8)
    {
        id = "early8_offhand_cadet_shield",
        itemId = 9764,
        slot = "SecondaryHand",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.4,
        suffixRange = "+1-2 Strength",
        instructions = "Cadet Shield (req 8) is a green shield world drop with random stat bonuses.",
        zone = "Elwynn Forest",
    },
    {
        id = "early8_offhand_grizzly_buckler",
        itemId = 15298,
        slot = "SecondaryHand",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Grizzly Buckler (req 8) is a green shield world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early8_offhand_gypsy_buckler",
        itemId = 9753,
        slot = "SecondaryHand",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.6,
        suffixId = 6,
        suffixRange = "+1 Strength",
        instructions = "Gypsy Buckler (req 7) is a green shield world drop with random stat bonuses.",
        zone = "Elwynn Forest",
    },

    -- Feet — mail melee, both factions (level 8)
    {
        id = "early8_feet_cadet_boots",
        itemId = 9759,
        slot = "Feet",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Cadet Boots (req 8) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early8_feet_war_torn_greaves",
        itemId = 15481,
        slot = "Feet",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "War-Torn Greaves (req 8) are a green mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early8_feet_battle_chain_boots",
        itemId = 3279,
        slot = "Feet",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Battle Chain Boots (req 7) are a common mail world drop from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Legs — Alliance mail melee (level 8)
    {
        id = "early8_legs_runed_copper_pants",
        itemId = 3473,
        slot = "Legs",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Runed Copper Pants from a Blacksmithing trainer and craft at an anvil (Blacksmithing 45). +2 Strength, +2 Stamina.",
        zone = "Stormwind City",
    },
    {
        id = "early8_legs_stormwind_guard_leggings",
        itemId = 6084,
        slot = "Legs",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete Wanted: Hogger in Elwynn Forest and choose Stormwind Guard Leggings (+3 Strength) over the other quest rewards.",
        zone = "Elwynn Forest",
        npc = "Marshal Dughan",
        questName = "Wanted: \"Hogger\"",
    },
    {
        id = "early8_legs_infantry_leggings",
        itemId = 6337,
        slot = "Legs",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.7,
        suffixId = 23,
        suffixRange = "+1-2 Strength",
        instructions = "Infantry Leggings (req 7) are a green mail world drop in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Waist — mail melee, both factions (level 8)
    {
        id = "early8_waist_belt_of_peoples_militia",
        itemId = 1154,
        slot = "Waist",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Patrolling Westfall on Sentinel Hill and choose Belt of the People's Militia over Bracers of the People's Militia.",
        zone = "Westfall",
        npc = "Captain Danuvin",
        questName = "Patrolling Westfall",
    },
    {
        id = "early8_waist_war_torn_girdle",
        itemId = 15480,
        slot = "Waist",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "War-Torn Girdle (req 8) is a green mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early8_waist_cadet_belt",
        itemId = 9758,
        slot = "Waist",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Cadet Belt (req 7) is a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Hands — mail melee, both factions (level 8)
    {
        id = "early8_hands_cadet_gauntlets",
        itemId = 9762,
        slot = "Hands",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Cadet Gauntlets (req 8) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early8_hands_runed_copper_gauntlets",
        itemId = 3472,
        slot = "Hands",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 2,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Runed Copper Gauntlets from a Blacksmithing trainer and craft at an anvil (Blacksmithing 40). Random +Agility or +Intellect.",
        zone = "Stormwind City",
    },
    {
        id = "early8_hands_war_torn_handgrips",
        itemId = 15484,
        slot = "Hands",
        minLevel = LEVEL8_MIN,
        maxLevel = LEVEL8_MAX,
        classes = MAIL_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "War-torn Handgrips (req 7) are a green mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Level 9 band — Head unchanged (early4_all_head_*). Finger and Shoulder unlock at 9.

    -- Shoulder — Alliance mail melee (level 9)
    {
        id = "early9_shoulder_durable_chain_shoulders",
        itemId = 6189,
        slot = "Shoulder",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete WANTED: Chok'sul in Loch Modan and choose Durable Chain Shoulders over Kimbra Boots. Minor Channeling Ring is a bonus reward on the same turn-in.",
        zone = "Loch Modan",
        npc = "Magistrate Bluntnose",
        questName = "WANTED: Chok'sul",
    },
    {
        id = "early9_shoulder_veteran_pauldrons",
        itemId = 2977,
        slot = "Shoulder",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Veteran Pauldrons (req 10) are a common mail world drop from humanoids in low-level Alliance zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early9_shoulder_talbar_mantle",
        itemId = 10657,
        slot = "Shoulder",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 3,
        sourceType = "quest_reward",
        instructions = "Complete the In Nightmares quest chain in the Barrens (starts with Falla Sagewind) and deliver the Nightmare Shard to Mathrengyl Bearwalker in Darnassus. Choose Talbar Mantle over Quagmire Galoshes.",
        zone = "Darnassus",
        npc = "Mathrengyl Bearwalker",
        questName = "In Nightmares",
    },

    -- Back — Alliance, all classes (level 9; unchanged from level 8)
    {
        id = "early9_back_embossed_leather_cloak",
        itemId = 2310,
        slot = "Back",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Leatherworking",
        instructions = "Learn Embossed Leather Cloak from a Leatherworking trainer and craft at a workbench (Leatherworking 60). +1 Stamina.",
        zone = "Stormwind City",
    },
    {
        id = "early9_back_brackwater_cloak",
        itemId = 4680,
        slot = "Back",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Brackwater Cloak (req 8, 12 armor) is a common world drop from humanoids in low-level Alliance zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early9_back_hunting_cloak",
        itemId = 4689,
        slot = "Back",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Hunting Cloak (req 8, 12 armor) is a common world drop from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Chest — Alliance mail melee (level 9)
    {
        id = "early9_chest_infantry_tunic",
        itemId = 6336,
        slot = "Chest",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.8,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Infantry Tunic of Strength (req 8) is a green mail world drop (+3-4 Strength, ~9.8% of rolls).",
        zone = "Elwynn Forest",
    },
    {
        id = "early9_chest_wax_polished_armor",
        itemId = 6195,
        slot = "Chest",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Farm Wax-Polished Armor (+2 Strength, +3 Stamina) from Grizlak in the Silver Stream Mine in Loch Modan (~40% drop).",
        zone = "Loch Modan",
        npc = "Grizlak",
    },
    {
        id = "early9_chest_ironheart_chain",
        itemId = 3166,
        slot = "Chest",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 3,
        sourceType = "quest_reward",
        instructions = "Complete Filthy Paws in Loch Modan — collect 4 Miners' Gear from Silver Stream Mine and return to Mountaineer Stormpike. Choose Ironheart Chain over Ironplate Buckler and Robe of the Keeper.",
        zone = "Loch Modan",
        npc = "Mountaineer Stormpike",
        questName = "Filthy Paws",
    },

    -- Wrist — Alliance mail melee (level 9)
    {
        id = "early9_wrist_ridgeback_bracers",
        itemId = 15403,
        slot = "Wrist",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_HOLY,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete WANTED: Murkdeep! in Darkshore and choose Ridgeback Bracers over Timberland Armguards or Breakwater Girdle.",
        zone = "Darkshore",
        questName = "WANTED: Murkdeep!",
    },
    {
        id = "early9_wrist_timberland_armguards",
        itemId = 5315,
        slot = "Wrist",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_HOLY,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete WANTED: Murkdeep! in Darkshore and choose Timberland Armguards over Ridgeback Bracers or Breakwater Girdle.",
        zone = "Darkshore",
        questName = "WANTED: Murkdeep!",
    },
    {
        id = "early9_wrist_veteran_bracers",
        itemId = 3213,
        slot = "Wrist",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Veteran Bracers (req 8) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Main Hand — Alliance mail melee (level 9)
    {
        id = "early9_mainhand_edge_of_peoples_militia",
        itemId = 1566,
        slot = "MainHand",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Finish The People's Militia quest chain in Westfall (three parts from Gryan Stoutmantle at Sentinel Hill) and choose Edge of the People's Militia (+5 Stamina) over the other weapons. Train Two-Handed Swords first.",
        zone = "Westfall",
        npc = "Gryan Stoutmantle",
        questName = "The People's Militia",
    },
    {
        id = "early9_mainhand_spiked_club",
        itemId = 4564,
        slot = "MainHand",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 5.9,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Spiked Club of Strength (req 8) is a green two-handed mace world drop (+3-4 Strength, ~5.9% of rolls). Train Two-Handed Maces first.",
        zone = "Westfall",
    },
    {
        id = "early9_mainhand_copper_battle_axe",
        itemId = 3488,
        slot = "MainHand",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_MELEE,
        curatedRank = 3,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Copper Battle Axe from a Blacksmithing trainer and craft at an anvil (Blacksmithing 35). Train Two-Handed Axes first.",
        zone = "Stormwind City",
    },

    -- Off Hand — Alliance mail melee (level 9)
    {
        id = "early9_offhand_peacekeepers_buckler",
        itemId = 27400,
        slot = "SecondaryHand",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete WANTED: Deathclaw on Bloodmyst Isle — kill Deathclaw and turn in his paw for Peacekeeper's Buckler (+1 Strength, +2 Stamina).",
        zone = "Bloodmyst Isle",
        questName = "WANTED: Deathclaw",
    },
    {
        id = "early9_offhand_ironplate_buckler",
        itemId = 3160,
        slot = "SecondaryHand",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_PROT,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete Filthy Paws in Loch Modan and choose Ironplate Buckler over Ironheart Chain and Robe of the Keeper.",
        zone = "Loch Modan",
        npc = "Mountaineer Stormpike",
        questName = "Filthy Paws",
    },
    {
        id = "early9_offhand_cadet_shield",
        itemId = 9764,
        slot = "SecondaryHand",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.4,
        suffixRange = "+1-2 Strength",
        instructions = "Cadet Shield (req 8) is a green shield world drop with random stat bonuses.",
        zone = "Elwynn Forest",
    },

    -- Finger — Alliance mail melee (level 9)
    {
        id = "early9_finger_woven_copper_ring",
        itemId = 21931,
        slot = "Finger",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Jewelcrafting",
        instructions = "Learn Woven Copper Ring from a Jewelcrafting trainer and craft at a workbench (Jewelcrafting 30).",
        zone = "Stormwind City",
    },
    {
        id = "early9_finger_ring_of_fortitude",
        itemId = 2237,
        slot = "Finger",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Ring of Fortitude (req 8, +4 Stamina) is a green world drop from humanoids in low-level Alliance zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early9_finger_minor_channeling_ring",
        itemId = 1449,
        slot = "Finger",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_HOLY,
        curatedRank = 3,
        sourceType = "quest_reward",
        instructions = "Complete WANTED: Chok'sul in Loch Modan — kill Chok'sul and turn in his head to Magistrate Bluntnose in Thelsamar. Minor Channeling Ring (+2 Intellect) is a bonus reward in addition to your shoulder or boot choice.",
        zone = "Loch Modan",
        npc = "Magistrate Bluntnose",
        questName = "WANTED: Chok'sul",
    },

    -- Feet — Alliance mail melee (level 9)
    {
        id = "early9_feet_padded_lamellar_boots",
        itemId = 5320,
        slot = "Feet",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete Stolen Booty in Ratchet (The Barrens) — recover the Shipment of Boots and Telescopic Lens from the Southsea pirates and choose Padded Lamellar Boots (+2 Strength, +2 Stamina) over Wayfaring Gloves.",
        zone = "The Barrens",
        npc = "Gazlowe",
        questName = "Stolen Booty",
    },
    {
        id = "early9_feet_kimbra_boots",
        itemId = 6191,
        slot = "Feet",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete WANTED: Chok'sul in Loch Modan and choose Kimbra Boots over Durable Chain Shoulders. Minor Channeling Ring is a bonus reward on the same turn-in.",
        zone = "Loch Modan",
        npc = "Magistrate Bluntnose",
        questName = "WANTED: Chok'sul",
    },
    {
        id = "early9_feet_veteran_boots",
        itemId = 2979,
        slot = "Feet",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Veteran Boots (req 9) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Legs — Alliance mail melee (level 9)
    {
        id = "early9_legs_war_torn_pants",
        itemId = 15485,
        slot = "Legs",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.8,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "War-Torn Pants (req 9) are a green mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early9_legs_cadet_leggings",
        itemId = 9763,
        slot = "Legs",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.8,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Cadet Leggings (req 9) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early9_legs_runed_copper_pants",
        itemId = 3473,
        slot = "Legs",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 3,
        sourceType = "profession",
        profession = "Blacksmithing",
        instructions = "Learn Runed Copper Pants from a Blacksmithing trainer and craft at an anvil (Blacksmithing 45). +2 Strength, +2 Stamina.",
        zone = "Stormwind City",
    },

    -- Waist — Alliance mail melee (level 9)
    {
        id = "early9_waist_breakwater_girdle",
        itemId = 15404,
        slot = "Waist",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete WANTED: Murkdeep! in Darkshore and choose Breakwater Girdle over Ridgeback Bracers or Timberland Armguards.",
        zone = "Darkshore",
        questName = "WANTED: Murkdeep!",
    },
    {
        id = "early9_waist_veteran_girdle",
        itemId = 4678,
        slot = "Waist",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_MELEE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Veteran Girdle (req 9) is a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early9_waist_belt_of_peoples_militia",
        itemId = 1154,
        slot = "Waist",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_MELEE,
        curatedRank = 3,
        sourceType = "quest_reward",
        instructions = "Complete Patrolling Westfall on Sentinel Hill and choose Belt of the People's Militia over Bracers of the People's Militia.",
        zone = "Westfall",
        npc = "Captain Danuvin",
        questName = "Patrolling Westfall",
    },

    -- Hands — Alliance mail melee (level 9)
    {
        id = "early9_hands_brackwater_gauntlets",
        itemId = 3304,
        slot = "Hands",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_MELEE,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Brackwater Gauntlets (req 9) are a common mail world drop from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early9_hands_wayfaring_gloves",
        itemId = 5337,
        slot = "Hands",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_HOLY,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete Stolen Booty in Ratchet and choose Wayfaring Gloves over Padded Lamellar Boots.",
        zone = "The Barrens",
        npc = "Gazlowe",
        questName = "Stolen Booty",
    },
    {
        id = "early9_hands_cadet_gauntlets",
        itemId = 9762,
        slot = "Hands",
        minLevel = LEVEL9_MIN,
        maxLevel = LEVEL9_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Cadet Gauntlets (req 8) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Level 10 band — Alliance Retribution paladin (mail melee). Head unchanged (early4_all_head_*).

    -- Shoulder — Alliance Ret (level 10)
    {
        id = "early10_shoulder_talbar_mantle",
        itemId = 10657,
        slot = "Shoulder",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete the In Nightmares quest chain in the Barrens (starts with Falla Sagewind) and deliver the Nightmare Shard to Mathrengyl Bearwalker in Darnassus. Choose Talbar Mantle over Quagmire Galoshes.",
        zone = "Darnassus",
        npc = "Mathrengyl Bearwalker",
        questName = "In Nightmares",
    },
    {
        id = "early10_shoulder_durable_chain_shoulders",
        itemId = 6189,
        slot = "Shoulder",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete WANTED: Chok'sul in Loch Modan and choose Durable Chain Shoulders over Kimbra Boots.",
        zone = "Loch Modan",
        npc = "Magistrate Bluntnose",
        questName = "WANTED: Chok'sul",
    },
    {
        id = "early10_shoulder_veteran_pauldrons",
        itemId = 2977,
        slot = "Shoulder",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_RET,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Veteran Pauldrons (req 10) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Back — Alliance, all classes (level 10; unchanged from level 9)
    {
        id = "early10_back_embossed_leather_cloak",
        itemId = 2310,
        slot = "Back",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        factions = ALLIANCE,
        curatedRank = 1,
        sourceType = "profession",
        profession = "Leatherworking",
        instructions = "Learn Embossed Leather Cloak from a Leatherworking trainer and craft at a workbench (Leatherworking 60). +1 Stamina.",
        zone = "Stormwind City",
    },
    {
        id = "early10_back_brackwater_cloak",
        itemId = 4680,
        slot = "Back",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        factions = ALLIANCE,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Brackwater Cloak (req 8, 12 armor) is a common world drop from humanoids in low-level Alliance zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early10_back_hunting_cloak",
        itemId = 4689,
        slot = "Back",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        factions = ALLIANCE,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Hunting Cloak (req 8, 12 armor) is a common world drop from humanoids in starter zones.",
        zone = "Elwynn Forest",
    },

    -- Chest — Alliance Ret (level 10)
    {
        id = "early10_chest_cadet_vest",
        itemId = 9765,
        slot = "Chest",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_RET,
        curatedRank = 1,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.8,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Cadet Vest (req 10) is a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early10_chest_wax_polished_armor",
        itemId = 6195,
        slot = "Chest",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Farm Wax-Polished Armor (+2 Strength, +3 Stamina) from Grizlak in the Silver Stream Mine in Loch Modan (~40% drop).",
        zone = "Loch Modan",
        npc = "Grizlak",
    },
    {
        id = "early10_chest_slarkskin",
        itemId = 6180,
        slot = "Chest",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Farm Slarkskin (+3 Agility, +2 Stamina) from Slark, a rare murloc patrolling the Longshore coast in Westfall.",
        zone = "Westfall",
        npc = "Slark",
    },

    -- Wrist — Alliance Ret (level 10)
    {
        id = "early10_wrist_bloodspattered_wristbands",
        itemId = 15495,
        slot = "Wrist",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_RET,
        curatedRank = 1,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.3,
        suffixRange = "+1-2 Strength",
        instructions = "Bloodspattered Wristbands (req 10) are a green mail world drop from humanoids in low-level zones.",
        zone = "Westfall",
    },
    {
        id = "early10_wrist_soldiers_wristguards",
        itemId = 6550,
        slot = "Wrist",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_RET,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.3,
        suffixRange = "+1-2 Strength",
        instructions = "Soldier's Wristguards (req 10) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early10_wrist_veteran_bracers",
        itemId = 3213,
        slot = "Wrist",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_RET,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Veteran Bracers (req 8) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Main Hand — Alliance Ret (level 10)
    {
        id = "early10_mainhand_edge_of_peoples_militia",
        itemId = 1566,
        slot = "MainHand",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Finish The People's Militia quest chain in Westfall and choose Edge of the People's Militia (+5 Stamina). Train Two-Handed Swords first.",
        zone = "Westfall",
        npc = "Gryan Stoutmantle",
        questName = "The People's Militia",
    },
    {
        id = "early10_mainhand_birchwood_maul",
        itemId = 4570,
        slot = "MainHand",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_RET,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 5.9,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Birchwood Maul (req 10) is a green two-handed mace world drop. Train Two-Handed Maces first.",
        zone = "Loch Modan",
    },
    {
        id = "early10_mainhand_burrowing_shovel",
        itemId = 6205,
        slot = "MainHand",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 3,
        sourceType = "world_drop",
        instructions = "Farm the Burrowing Shovel (+4 Agility) from Master Digger, a rare kobold in the deepest part of Jangolode Mine in Westfall. Train Two-Handed Maces first.",
        zone = "Westfall",
        npc = "Master Digger",
    },

    -- Off Hand — unchanged from level 9 (level 10)
    {
        id = "early10_offhand_peacekeepers_buckler",
        itemId = 27400,
        slot = "SecondaryHand",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_MELEE,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete WANTED: Deathclaw on Bloodmyst Isle — kill Deathclaw and turn in his paw for Peacekeeper's Buckler (+1 Strength, +2 Stamina).",
        zone = "Bloodmyst Isle",
        questName = "WANTED: Deathclaw",
    },
    {
        id = "early10_offhand_ironplate_buckler",
        itemId = 3160,
        slot = "SecondaryHand",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_PROT,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete Filthy Paws in Loch Modan and choose Ironplate Buckler over Ironheart Chain and Robe of the Keeper.",
        zone = "Loch Modan",
        npc = "Mountaineer Stormpike",
        questName = "Filthy Paws",
    },
    {
        id = "early10_offhand_cadet_shield",
        itemId = 9764,
        slot = "SecondaryHand",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_MELEE,
        curatedRank = 3,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.4,
        suffixRange = "+1-2 Strength",
        instructions = "Cadet Shield (req 8) is a green shield world drop with random stat bonuses.",
        zone = "Elwynn Forest",
    },

    -- Finger — Alliance Ret (level 10)
    {
        id = "early10_finger_the_1_ring",
        itemId = 8350,
        slot = "Finger",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Fish up The 1 Ring from low-level fishing pools (Stormwind canals, Elwynn/Loch Modan waters, etc.) — extremely rare; check the Auction House if you prefer.",
        zone = "Stormwind City",
    },
    {
        id = "early10_finger_minor_channeling_ring",
        itemId = 1449,
        slot = "Finger",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete WANTED: Chok'sul in Loch Modan — Minor Channeling Ring (+2 Intellect) is a bonus reward on the turn-in.",
        zone = "Loch Modan",
        npc = "Magistrate Bluntnose",
        questName = "WANTED: Chok'sul",
    },
    {
        id = "early10_finger_woven_copper_ring",
        itemId = 21931,
        slot = "Finger",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 3,
        sourceType = "profession",
        profession = "Jewelcrafting",
        instructions = "Learn Woven Copper Ring from a Jewelcrafting trainer and craft at a workbench (Jewelcrafting 30).",
        zone = "Stormwind City",
    },

    -- Feet — Alliance Ret (level 10)
    {
        id = "early10_feet_quagmire_galoshes",
        itemId = 10658,
        slot = "Feet",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 1,
        sourceType = "quest_reward",
        instructions = "Complete the In Nightmares quest chain and choose Quagmire Galoshes over Talbar Mantle when turning in to Mathrengyl Bearwalker in Darnassus.",
        zone = "Darnassus",
        npc = "Mathrengyl Bearwalker",
        questName = "In Nightmares",
    },
    {
        id = "early10_feet_padded_lamellar_boots",
        itemId = 5320,
        slot = "Feet",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 2,
        sourceType = "quest_reward",
        instructions = "Complete Stolen Booty in Ratchet and choose Padded Lamellar Boots (+2 Strength, +2 Stamina).",
        zone = "The Barrens",
        npc = "Gazlowe",
        questName = "Stolen Booty",
    },
    {
        id = "early10_feet_mud_stompers",
        itemId = 6188,
        slot = "Feet",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 3,
        sourceType = "quest_reward",
        instructions = "Complete The Hunter's Revenge in Wetlands — kill Sarltooth and return his talon to Watcher Belgrum for Mud Stompers.",
        zone = "Wetlands",
        npc = "Watcher Belgrum",
        questName = "The Hunter's Revenge",
    },

    -- Legs — Alliance Ret (level 10)
    {
        id = "early10_legs_veteran_leggings",
        itemId = 2978,
        slot = "Legs",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_RET,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Veteran Leggings (req 10) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early10_legs_war_torn_pants",
        itemId = 15485,
        slot = "Legs",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 2,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.8,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "War-Torn Pants (req 9) are a green mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early10_legs_cadet_leggings",
        itemId = 9763,
        slot = "Legs",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 3,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.8,
        suffixId = 97,
        suffixRange = "+3-4 Strength",
        instructions = "Cadet Leggings (req 9) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },

    -- Waist — Alliance Ret (level 10)
    {
        id = "early10_waist_bloodspattered_sash",
        itemId = 15492,
        slot = "Waist",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_RET,
        curatedRank = 1,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.6,
        suffixId = 24,
        suffixRange = "+2-3 Strength",
        instructions = "Bloodspattered Sash (req 10) is a green mail world drop from humanoids in low-level zones.",
        zone = "Westfall",
    },
    {
        id = "early10_waist_silver_defias_belt",
        itemId = 832,
        slot = "Waist",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 2,
        sourceType = "world_drop",
        instructions = "Silver Defias Belt (req 10) is a green world drop from Defias mobs in Westfall and the Deadmines area.",
        zone = "Westfall",
    },
    {
        id = "early10_waist_breakwater_girdle",
        itemId = 15404,
        slot = "Waist",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        factions = ALLIANCE,
        specs = SPEC_RET,
        curatedRank = 3,
        sourceType = "quest_reward",
        instructions = "Complete WANTED: Murkdeep! in Darkshore and choose Breakwater Girdle.",
        zone = "Darkshore",
        questName = "WANTED: Murkdeep!",
    },

    -- Hands — Alliance Ret (level 10)
    {
        id = "early10_hands_veteran_gloves",
        itemId = 2980,
        slot = "Hands",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_RET,
        curatedRank = 1,
        sourceType = "world_drop",
        instructions = "Veteran Gloves (req 10) are a common mail world drop from humanoids in low-level zones.",
        zone = "Elwynn Forest",
    },
    {
        id = "early10_hands_gemmed_copper_gauntlets",
        itemId = 3474,
        slot = "Hands",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_RET,
        curatedRank = 2,
        sourceType = "profession",
        suffix = "of Strength",
        suffixChance = 9.2,
        suffixId = 24,
        suffixRange = "+2-3 Strength",
        profession = "Blacksmithing",
        instructions = "Learn Gemmed Copper Gauntlets from a Blacksmithing trainer and craft at an anvil (Blacksmithing 25). +2 Strength.",
        zone = "Stormwind City",
    },
    {
        id = "early10_hands_bloodspattered_gloves",
        itemId = 15491,
        slot = "Hands",
        minLevel = LEVEL10_MIN,
        maxLevel = LEVEL10_MAX,
        classes = MAIL_MELEE,
        specs = SPEC_RET,
        curatedRank = 3,
        sourceType = "world_drop",
        suffix = "of Strength",
        suffixChance = 9.2,
        suffixId = 24,
        suffixRange = "+2-3 Strength",
        instructions = "Bloodspattered Gloves (req 10) are a green mail world drop from humanoids in low-level zones.",
        zone = "Westfall",
    },

    -- Later Alliance leveling (unchanged horizon)
    {
        id = "early_chest_tunic_westfall",
        itemId = 2041,
        slot = "Chest",
        minLevel = 9,
        maxLevel = 18,
        factions = ALLIANCE,
        sourceType = "quest_reward",
        instructions = "Finish The Defias Brotherhood quest chain in Westfall. Turn in VanCleef's Head to Gryan Stoutmantle at Sentinel Hill and choose the Tunic of Westfall (leather chest).",
        zone = "Westfall",
        npc = "Gryan Stoutmantle",
        questName = "The Defias Brotherhood",
    },
    {
        id = "paladin_mainhand_hogger_blade",
        itemId = 6331,
        slot = "MainHand",
        minLevel = 6,
        maxLevel = 15,
        classes = { PALADIN = true },
        factions = ALLIANCE,
        sourceType = "world_drop",
        instructions = "Group for Hogger in Elwynn Forest (Wanted: Hogger quest). Howling Blade is a low-chance loot drop from Hogger.",
        zone = "Elwynn Forest",
        npc = "Hogger",
    },
    {
        id = "paladin_mainhand_verigans_fist",
        itemId = 6953,
        slot = "MainHand",
        minLevel = 20,
        maxLevel = 30,
        classes = { PALADIN = true },
        factions = ALLIANCE,
        sourceType = "quest_reward",
        instructions = "Complete the Paladin Test of Righteousness chain starting with The Tome of Valor in Stormwind. Gather Jordan's materials from Deadmines, Loch Modan, Shadowfang Keep, and Darkshore, then return to Jordan Stilwell in Ironforge.",
        zone = "Stormwind City",
        questName = "The Tome of Valor",
    },

}

local SLOT_TO_INVENTORY = {
    Head = 1,
    Neck = 2,
    Shoulder = 3,
    Back = 15,
    Chest = 5,
    Shirt = 4,
    Tabard = 19,
    Wrist = 9,
    Hands = 10,
    Waist = 6,
    Legs = 7,
    Feet = 8,
    Finger0 = 11,
    Finger1 = 12,
    Trinket0 = 13,
    Trinket1 = 14,
    MainHand = 16,
    SecondaryHand = 17,
    Ranged = 18,
}

-- Log categories: both finger/trinket inventory slots share one upgrade list each.
GQ.Data.MERGED_SLOT_INVENTORY = {
    Finger = { 11, 12 },
    Trinket = { 13, 14 },
}

function GQ.Data:NormalizeSlotName(slotName)
    if slotName == "Shield" then
        return "SecondaryHand"
    end
    if slotName == "Finger0" or slotName == "Finger1" then
        return "Finger"
    end
    if slotName == "Trinket0" or slotName == "Trinket1" then
        return "Trinket"
    end
    return slotName
end

function GQ.Data:GetInventorySlots(slotName)
    slotName = self:NormalizeSlotName(slotName)
    if self.MERGED_SLOT_INVENTORY[slotName] then
        return self.MERGED_SLOT_INVENTORY[slotName]
    end

    local inv = SLOT_TO_INVENTORY[slotName]
    if inv then
        return { inv }
    end
    return {}
end

function GQ.Data:GetInventorySlot(slotName)
    local slots = self:GetInventorySlots(slotName)
    return slots[1]
end

function GQ.Data:EntryMatchesSlot(entry, slotName)
    if not entry or not entry.slot then
        return false
    end
    return self:NormalizeSlotName(entry.slot) == self:NormalizeSlotName(slotName)
end

function GQ.Data:GetCandidateSlotKeys(slotName)
    slotName = self:NormalizeSlotName(slotName)
    if slotName == "Finger" then
        return { "Finger", "Finger0", "Finger1" }
    end
    if slotName == "Trinket" then
        return { "Trinket", "Trinket0", "Trinket1" }
    end
    if slotName == "SecondaryHand" then
        return { "SecondaryHand", "Shield" }
    end
    return { slotName }
end

function GQ.Data:BuildIndex()
    self.bySlot = {}
    self.byItemId = {}
    self.byId = {}
    self.byClass = {}
    self.byClassSlot = {}
    for _, entry in ipairs(self.entries) do
        local slot = self:NormalizeSlotName(entry.slot)
        self.bySlot[slot] = self.bySlot[slot] or {}
        table.insert(self.bySlot[slot], entry)
        self.byItemId[entry.itemId] = self.byItemId[entry.itemId] or {}
        table.insert(self.byItemId[entry.itemId], entry)
        if entry.id then
            self.byId[entry.id] = entry
        end
        if entry.classes then
            for classFile in pairs(entry.classes) do
                self.byClass[classFile] = self.byClass[classFile] or {}
                table.insert(self.byClass[classFile], entry)
                self.byClassSlot[classFile] = self.byClassSlot[classFile] or {}
                self.byClassSlot[classFile][slot] = self.byClassSlot[classFile][slot] or {}
                table.insert(self.byClassSlot[classFile][slot], entry)
            end
        end
    end
    self:InvalidateQueryCache()
end

function GQ.Data:GetClassSlotEntryList(slotName)
    slotName = self:NormalizeSlotName(slotName)
    local classFile = GQ:GetEffectiveClass()
    if classFile and self.byClassSlot and self.byClassSlot[classFile] then
        return self.byClassSlot[classFile][slotName]
    end
    return self.bySlot and self.bySlot[slotName]
end

function GQ.Data:GetEntriesByItemId(itemId)
    if not itemId then
        return {}
    end
    return self.byItemId and self.byItemId[itemId] or {}
end

function GQ.Data:GetItemFact(itemId)
    if not itemId then
        return nil
    end

    local tables = {
        self.itemFacts,
        self.warriorItemFacts,
        self.hunterItemFacts,
        self.druidItemFacts,
        self.shamanItemFacts,
        self.rogueItemFacts,
        self.priestItemFacts,
        self.priestEarly1to9Facts,
        self.warlockItemFacts,
        self.warlockEarly1to9Facts,
        self.mageItemFacts,
        self.mageEarly1to9Facts,
        self.paladinHorde1to9Facts,
        self.warriorHorde1to9Facts,
        self.hunterEarly1to9Facts,
        self.druidEarly1to9Facts,
        self.shamanEarly1to9Facts,
        self.rogueEarly1to9Facts,
    }

    for i = 1, #tables do
        local fact = tables[i] and tables[i][itemId]
        if fact then
            return fact
        end
    end

    return nil
end

function GQ.Data:GetItemDisplayName(itemId)
    if not itemId then
        return nil
    end

    local name = GetItemInfo(itemId)
    if name then
        return name
    end

    local fact = self:GetItemFact(itemId)
    if fact and fact.name then
        return fact.name
    end

    return PROFESSION_ITEM_NAMES[itemId]
end

function GQ.Data:GetEntryDisplayName(entry)
    if not entry then
        return nil
    end

    local base = self:GetItemDisplayName(entry.itemId) or ("Item " .. tostring(entry.itemId))
    local suffix = entry.suffix
    if suffix and suffix ~= "" then
        suffix = tostring(suffix)
        if suffix:sub(1, 1) == " " then
            return base .. suffix
        end
        return base .. " " .. suffix
    end

    return base
end

function GQ.Data:ItemNameMatchesSuffixTarget(itemName, targetName, entry)
    itemName = self:NormalizeItemName(itemName)
    targetName = self:NormalizeItemName(targetName)
    if not itemName or not targetName then
        return false
    end

    if itemName == targetName then
        return true
    end

    if entry and entry.suffix and entry.suffix ~= "" then
        local suffix = tostring(entry.suffix)
        if suffix:sub(1, 1) ~= " " then
            suffix = " " .. suffix
        end
        if itemName:sub(-#suffix) == suffix then
            return true
        end
    end

    return false
end

function GQ.Data:EntryDisplayNameReady(entry)
    if not entry or not entry.itemId then
        return false
    end

    local base = self:GetItemDisplayName(entry.itemId)
    if not base or base:find("^Item %d+$", 1) then
        return false
    end

    return true
end

function GQ.Data:SanitizeText(text)
    if text == nil or text == "" then
        return text
    end

    text = tostring(text)
    -- WoW fonts lack these glyphs and draw them as empty boxes.
    text = text:gsub("\226\128\148", "-") -- em dash
    text = text:gsub("\226\128\147", "-") -- en dash
    text = text:gsub("\226\128\146", "-") -- figure dash
    text = text:gsub("\194\183", ", ") -- middle dot
    text = text:gsub("\226\128\166", "...") -- ellipsis
    text = text:gsub("\226\128\156", "\"")
    text = text:gsub("\226\128\157", "\"")
    text = text:gsub("\226\128\152", "'")
    text = text:gsub("\226\128\153", "'")
    text = text:gsub("\194\160", " ")
    text = text:gsub(" +", " ")
    text = text:gsub(" ,", ",")
    return text
end

function GQ.Data:GetSuffixHint(entry)
    if not entry or not entry.suffix then
        return nil
    end

    local parts = { entry.suffix }
    if entry.suffixRange and entry.suffixRange ~= "" then
        parts[#parts + 1] = entry.suffixRange
    elseif entry.suffixId then
        parts[#parts + 1] = "tier " .. tostring(entry.suffixId)
    end

    local hint = table.concat(parts, ", ")
    if entry.suffixChance then
        hint = hint .. " (~" .. tostring(entry.suffixChance) .. "% on drop)"
    end

    return hint
end

-- Novelty on-use effects (fall damage/speed, drunk, party-only buffs, etc.) are not
-- real upgrades for the level band — hide them from picks and notables.
local NOVELTY_PROC_PATTERNS = {
    "fall speed",
    "fall damage",
    "slow fall",
    "safe fall",
    "parachute",
    "gets you quite drunk",
    "unless it explodes",
    "turns the target into a chicken",
    "look far into the distance",
    "nearby party members",
    "party members within",
    "summons the truesilver boar",
}

function GQ.Data:GetEntryProcText(entry)
    if not entry then
        return nil
    end

    if entry.proc and entry.proc ~= "" then
        return entry.proc
    end

    local facts = self.itemFacts
    if facts and entry.itemId then
        local fact = facts[entry.itemId]
        if fact and fact.proc and fact.proc ~= "" then
            return fact.proc
        end
    end

    return nil
end

function GQ.Data:IsNoveltyProcItem(entry)
    local proc = self:GetEntryProcText(entry)
    if not proc then
        return false
    end

    local lower = string.lower(tostring(proc))
    for i = 1, #NOVELTY_PROC_PATTERNS do
        if lower:find(NOVELTY_PROC_PATTERNS[i], 1, true) then
            return true
        end
    end

    return false
end

-- Ranged weapons whose DPS/procs only matter for Hunters (pull-slot filler for others).
GQ.Data.HUNTER_ONLY_RANGED_ITEMS = {
    [2825] = true, -- Bow of Searing Arrows
}

function GQ.Data:IsHunterOnlyRangedItem(entry)
    if not entry or not entry.itemId then
        return false
    end
    return self.HUNTER_ONLY_RANGED_ITEMS[entry.itemId] == true
end

-- Melee attack-speed on-use (not spell haste) — bear/feral only for druids.
GQ.Data.DRUID_MELEE_HASTE_ITEMS = {
    [9449] = true, -- Manual Crowd Pummeler
}

function GQ.Data:IsDruidMeleeHasteForCaster(entry)
    if not entry or not entry.itemId then
        return false
    end
    if not self.DRUID_MELEE_HASTE_ITEMS[entry.itemId] then
        return false
    end
    if not entry.specs then
        return false
    end
    return entry.specs.balance or entry.specs.restoration
end

-- On-use AOE / novelty trinkets that are not real stat upgrades for leveling BiS.
GQ.Data.EXCLUDED_ITEMS = {
    [13515] = true, -- Ramstein's Lightning Bolts
}

function GQ.Data:IsExcludedItem(entry)
    if not entry or not entry.itemId then
        return false
    end
    return self.EXCLUDED_ITEMS[entry.itemId] == true
end

function GQ.Data:ShouldShowEntry(entry)
    if not entry or self:IsNoveltyProcItem(entry) or self:IsExcludedItem(entry) then
        return false
    end

    if self:IsHunterOnlyRangedItem(entry) and GQ:GetEffectiveClass() ~= "HUNTER" then
        return false
    end

    if self:IsDruidMeleeHasteForCaster(entry) then
        return false
    end

    return true
end

function GQ.Data:GetTooltipScanner()
    if not self._tooltipScanner then
        self._tooltipScanner = CreateFrame("GameTooltip", "GearQuestTooltipScanner", UIParent, "GameTooltipTemplate")
    end
    return self._tooltipScanner
end

-- Craft skill from item tooltip ("Leatherworking (260)"), not equip level req.
local function StripTooltipText(text)
    if not text or text == "" then
        return ""
    end
    return text
        :gsub("|c%x%x%x%x%x%x%x%x", "")
        :gsub("|r", "")
        :gsub("|A:.-|a", "")
        :gsub("|T.-|t", "")
        :gsub("^%s+", "")
        :gsub("%s+$", "")
end

function GQ.Data:InvalidateCraftSkillCache(itemId)
    if not itemId or not self._craftSkillCache then
        return
    end
    self._craftSkillCache[itemId] = nil
end

-- BRD Chest of The Seven: boss reward chest after the Seven encounter, not a random world container.
local BOSS_CHEST_SEVEN = {
    sourceType = "boss_drop",
    instructions = "Drops from the Chest of The Seven after defeating the Seven in Blackrock Depths.",
    zone = "Blackrock Depths",
    npc = "The Seven",
}
GQ.Data.BOSS_CHEST_SOURCES = {
    [11921] = BOSS_CHEST_SEVEN,
    [11923] = BOSS_CHEST_SEVEN,
    [11925] = BOSS_CHEST_SEVEN,
    [11926] = BOSS_CHEST_SEVEN,
    [11927] = BOSS_CHEST_SEVEN,
    [11929] = BOSS_CHEST_SEVEN,
    [11945] = BOSS_CHEST_SEVEN,
    [11946] = BOSS_CHEST_SEVEN,
}

function GQ.Data:EnrichBossChestEntry(entry)
    if not entry or not entry.itemId then
        return entry
    end

    local override = self.BOSS_CHEST_SOURCES and self.BOSS_CHEST_SOURCES[entry.itemId]
    if not override then
        return entry
    end

    entry.sourceType = override.sourceType
    entry.instructions = override.instructions
    entry.zone = override.zone
    entry.npc = override.npc
    return entry
end

function GQ.Data:CacheTradeSkillRecipes()
    if not GetNumTradeSkills or not GetTradeSkillInfo or not GetTradeSkillItemLink then
        return
    end

    self._craftSkillCache = self._craftSkillCache or {}
    local num = GetNumTradeSkills()
    for i = 1, num do
        local _, skillType, _, _, skillLevel = GetTradeSkillInfo(i)
        if skillType ~= "header" and skillLevel and skillLevel > 0 then
            local link = GetTradeSkillItemLink(i)
            local itemId = link and self:ItemLinkToId(link)
            if itemId then
                self._craftSkillCache[itemId] = skillLevel
            end
        end
    end
end

function GQ.Data:LookupProfessionCraftSkill(itemId, profession)
    if not itemId then
        return nil
    end

    if GQ.CraftSkills and GQ.CraftSkills[itemId] and GQ.CraftSkills[itemId].skill then
        return GQ.CraftSkills[itemId].skill
    end

    self._craftSkillCache = self._craftSkillCache or {}
    local cached = self._craftSkillCache[itemId]
    if cached and cached > 0 then
        return cached
    end

    if GQ.Equip and GQ.Equip.PrimeItem then
        GQ.Equip:PrimeItem(itemId)
    else
        GetItemInfo(itemId)
    end

    local itemLink = select(2, GetItemInfo(itemId))
    if not itemLink then
        return nil
    end

    local scanner = self:GetTooltipScanner()
    scanner:SetOwner(UIParent, "ANCHOR_NONE")
    scanner:ClearLines()
    scanner:SetHyperlink(itemLink)
    if scanner.Show then
        scanner:Show()
    end

    local craftSkill
    local scannerName = scanner:GetName()
    for i = 1, scanner:NumLines() do
        for _, suffix in ipairs({ "TextLeft", "TextRight" }) do
            local line = _G[scannerName .. suffix .. i]
            local text = StripTooltipText(line and line:GetText())
            if text ~= "" then
                if profession and text:find(profession, 1, true) then
                    local skill = tonumber(text:match("%((%d+)%)"))
                    if skill and skill > 0 then
                        craftSkill = skill
                        break
                    end
                end

                local profName, skillText = text:match("([%a%s]+) %((%d+)%)")
                local skill = skillText and tonumber(skillText)
                if skill and skill > 0 then
                    if not profession or not profName
                        or profName:find(profession, 1, true)
                        or profession:find(StripTooltipText(profName), 1, true) then
                        craftSkill = skill
                        break
                    end
                end
            end
        end
        if craftSkill then
            break
        end
    end

    if scanner.Hide then
        scanner:Hide()
    end

    if craftSkill and craftSkill > 0 then
        self._craftSkillCache[itemId] = craftSkill
    end

    return craftSkill
end

function GQ.Data:GetProfessionInstructions(entry)
    if not entry or entry.sourceType ~= "profession" then
        return entry and entry.instructions
    end

    local instructions = entry.instructions or ""
    local isBoP = GQ.Equip and GQ.Equip.IsBindOnPickup and GQ.Equip:IsBindOnPickup(entry.itemId)
    -- BoE profession gear can be bought on the AH; only BoP must be self-crafted.
    if isBoP == false then
        return instructions
    end

    local craftSkill = self:LookupProfessionCraftSkill(entry.itemId, entry.profession)
    if craftSkill and craftSkill > 0 then
        local profession = entry.profession or "Profession"
        return string.format("Crafted with %s (requires skill %d).", profession, craftSkill)
    end

    return instructions
end

function GQ.Data:EnsureProfessionCraftSkillListener()
    if self._professionCraftSkillListener then
        return
    end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    frame:SetScript("OnEvent", function(_, _, itemId)
        if not itemId then
            return
        end

        GQ.Data:InvalidateCraftSkillCache(itemId)

        if GQ.Log and GQ.Log.frame and GQ.Log.frame:IsShown() then
            local entry = GQ.Log.selectedEntry
            if entry and entry.sourceType == "profession" and entry.itemId == itemId then
                if GQ.Equip and GQ.Equip.IsBindOnPickup and GQ.Equip:IsBindOnPickup(itemId) then
                    GQ.Data:EnrichProfessionEntry(entry)
                    GQ.Log:ApplyEntryDetail(entry)
                end
            end
        end
    end)
    self._professionCraftSkillListener = frame
end

function GQ.Data:EnrichProfessionEntry(entry)
    if not entry or entry.sourceType ~= "profession" then
        return entry
    end

    local isBoP = GQ.Equip and GQ.Equip.IsBindOnPickup and GQ.Equip:IsBindOnPickup(entry.itemId)
    if isBoP == false then
        return entry
    end

    self:EnsureProfessionCraftSkillListener()

    local instructions = self:GetProfessionInstructions(entry)
    if instructions then
        entry.instructions = instructions
    end

    return entry
end

function GQ.Data:CacheOwnedSuffixItemLink(entry, link)
    if not entry or not link then
        return
    end

    local key = self:EntryListKey(entry)
    if not key then
        return
    end

    self._ownedSuffixLinks = self._ownedSuffixLinks or {}
    self._ownedSuffixLinks[key] = link
end

function GQ.Data:GetCachedSuffixItemLink(entry)
    if not entry then
        return nil
    end

    local key = self:EntryListKey(entry)
    if not key then
        return nil
    end

    if self._ownedSuffixLinks and self._ownedSuffixLinks[key] then
        return self._ownedSuffixLinks[key]
    end

    return nil
end

function GQ.Data:FindCachedItemLink(entry)
    if not entry or not entry.itemId then
        return nil
    end

    local cached = self:GetCachedSuffixItemLink(entry)
    if cached then
        return cached
    end

    local function checkLink(link)
        if not link or self:ItemLinkToId(link) ~= entry.itemId then
            return nil
        end

        if entry.suffix and entry.suffix ~= "" then
            if not self:EntrySuffixMatchesLink(entry, link) then
                return nil
            end
        end

        self:CacheOwnedSuffixItemLink(entry, link)
        return link
    end

    for invSlot = 1, 19 do
        local link = checkLink(GetInventoryItemLink("player", invSlot))
        if link then
            return link
        end
    end

    local numBags = NUM_BAG_SLOTS or 4
    for bag = 0, numBags do
        local numSlots
        if C_Container and C_Container.GetContainerNumSlots then
            numSlots = C_Container.GetContainerNumSlots(bag) or 0
        elseif GetContainerNumSlots then
            numSlots = GetContainerNumSlots(bag) or 0
        else
            numSlots = 0
        end

        for slot = 1, numSlots do
            local link
            if C_Container and C_Container.GetContainerItemLink then
                link = C_Container.GetContainerItemLink(bag, slot)
            elseif GetContainerItemLink then
                link = GetContainerItemLink(bag, slot)
            end

            link = checkLink(link)
            if link then
                return link
            end
        end
    end

    return nil
end

function GQ.Data:ExtractItemStringFromHyperlink(hyperlink)
    if not hyperlink or hyperlink == "" then
        return nil
    end

    local itemString = hyperlink:match("|H(item:[^|]+)|h")
    if itemString then
        return itemString
    end

    if hyperlink:match("^item:") then
        return hyperlink
    end

    return nil
end

function GQ.Data:SuffixIdFromLink(link)
    if not link then
        return nil
    end

    local itemString = self:ExtractItemStringFromHyperlink(link)
    if not itemString and link:match("^item:") then
        itemString = link
    end
    if not itemString then
        return nil
    end

    if strsplit then
        local id = tonumber(select(7, strsplit(":", itemString)))
        if id and id ~= 0 then
            return id
        end
        return nil
    end

    return self:ParseSuffixIdFromItemString(itemString)
end

function GQ.Data:ParseSuffixIdFromItemString(itemString)
    if not itemString then
        return nil
    end

    return tonumber(itemString:match("^item:%d+:0:0:0:0:0:(%-?%d+):"))
end

function GQ.Data:GetSuffixLinkLevel(entry)
    local fallback = GQ.MAX_PLAYER_LEVEL or 60
    if not entry then
        return fallback
    end

    if GetItemInfo and entry.itemId then
        local _, _, _, iLevel, reqLevel = GetItemInfo(entry.itemId)
        if iLevel and iLevel > 0 then
            return iLevel
        end
        if reqLevel and reqLevel > 0 then
            return reqLevel
        end
    end

    if entry.minLevel and entry.minLevel > 0 then
        return entry.minLevel
    end

    return fallback
end

-- Random enchant tooltips and completion use pipeline suffixId only.
-- Positive field-7 id = ItemRandomProperties (fixed tier lookup).
-- Negative field-7 id = ItemRandomSuffix (ilvl-scaled; factor in field 8).
function GQ.Data:MakeSuffixTargetLink(entry)
    if not entry or not entry.itemId then
        return nil
    end

    if not entry.suffixId or entry.suffixId == 0 then
        return nil
    end

    if entry.suffixId < 0 then
        local factor = entry.suffixFactor or self:GetSuffixLinkLevel(entry)
        return string.format("item:%d:0:0:0:0:0:%d:%d:0", entry.itemId, entry.suffixId, factor)
    end

    return string.format("item:%d:0:0:0:0:0:%d:0:0", entry.itemId, entry.suffixId)
end

function GQ.Data:EntrySuffixMatchesLink(entry, link)
    if not entry or not link then
        return false
    end

    if self:ItemLinkToId(link) ~= entry.itemId then
        return false
    end

    if not entry.suffix or entry.suffix == "" then
        return true
    end

    local rolledId = self:SuffixIdFromLink(link)
    if entry.suffixId and entry.suffixId ~= 0 then
        if not rolledId then
            return false
        end
        return rolledId >= entry.suffixId
    end

    return self:ItemNameMatchesEntry(self:ItemNameFromLink(link), entry)
end

function GQ.Data:ResolveSuffixItemLink(entry)
    if not entry or not entry.suffix or entry.suffix == "" or not entry.itemId then
        return nil
    end

    self:EnrichEntrySuffix(entry)
    return self:MakeSuffixTargetLink(entry)
end

function GQ.Data:AppendSuffixRangeLines(tooltip, entry)
    if not tooltip or not entry or not entry.suffixRange or entry.suffixRange == "" then
        return
    end

    for part in string.gmatch(entry.suffixRange, "[^,]+") do
        local text = self:NormalizeItemName(part)
        if text and text ~= "" then
            tooltip:AddLine(text, 1, 1, 1)
        end
    end
end

function GQ.Data:EnsureSuffixTooltipRefresh()
    if self._suffixTooltipRefresh then
        return
    end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    frame:SetScript("OnEvent", function()
        local pending = self._pendingSuffixTooltips
        if not pending then
            return
        end

        for tooltip, entry in pairs(pending) do
            if not tooltip or not tooltip.IsShown or not tooltip:IsShown() then
                pending[tooltip] = nil
            else
                self:EnrichEntrySuffix(entry)
                local link = self:MakeSuffixTargetLink(entry)
                if link then
                    if GetItemInfo then
                        GetItemInfo(link)
                    end
                    tooltip:ClearLines()
                    tooltip:SetHyperlink(link)
                    pending[tooltip] = nil
                end
            end
        end
    end)
    self._suffixTooltipRefresh = frame
end

function GQ.Data:TrackPendingSuffixTooltip(tooltip, entry)
    if not tooltip or not entry then
        return
    end

    self:EnsureSuffixTooltipRefresh()
    self._pendingSuffixTooltips = self._pendingSuffixTooltips or {}
    self._pendingSuffixTooltips[tooltip] = entry

    if entry.itemId and GetItemInfo then
        GetItemInfo(entry.itemId)
    end
end

function GQ.Data:TryShowSuffixTargetTooltip(tooltip, entry)
    if not tooltip or not entry then
        return false
    end

    self:EnrichEntrySuffix(entry)
    local link = self:MakeSuffixTargetLink(entry)
    if not link then
        return false
    end

    if GetItemInfo then
        GetItemInfo(link)
    end

    tooltip:SetHyperlink(link)
    return true
end

function GQ.Data:CopyTooltipLinesFromScanner(tooltip, scanner, skipTitle)
    local scannerName = scanner:GetName()
    local startLine = skipTitle and 2 or 1

    for i = startLine, scanner:NumLines() do
        local left = _G[scannerName .. "TextLeft" .. i]
        local right = _G[scannerName .. "TextRight" .. i]
        if left then
            local text = left:GetText()
            if text and text ~= "" then
                local lr, lg, lb = left:GetTextColor()
                if right then
                    local rightText = right:GetText()
                    if rightText and rightText ~= "" then
                        local rr, rg, rb = right:GetTextColor()
                        tooltip:AddDoubleLine(text, rightText, lr, lg, lb, rr, rg, rb)
                    else
                        tooltip:AddLine(text, lr, lg, lb)
                    end
                else
                    tooltip:AddLine(text, lr, lg, lb)
                end
            end
        end
    end
end

function GQ.Data:ShowSuffixFallbackTooltip(tooltip, entry)
    local itemId = entry.itemId
    local scanner = self:GetTooltipScanner()
    scanner:SetOwner(UIParent, "ANCHOR_NONE")
    scanner:ClearLines()
    scanner:SetHyperlink("item:" .. itemId)

    local displayName = self:GetEntryDisplayName(entry)
    local _, _, quality = GetItemInfo(itemId)
    local r, g, b = GetItemQualityColor(quality or 1)

    tooltip:ClearLines()
    tooltip:SetText(displayName, r, g, b)
    self:CopyTooltipLinesFromScanner(tooltip, scanner, true)
    self:AppendSuffixRangeLines(tooltip, entry)

    local suffixHint = self:GetSuffixHint(entry)
    if suffixHint then
        tooltip:AddLine(" ")
        tooltip:AddLine("Target random enchant: " .. suffixHint, 0.7, 0.9, 1)
    end

    scanner:Hide()
end

function GQ.Data:GetEntryItemHyperlink(entry)
    if not entry or not entry.itemId then
        return nil
    end

    if entry.suffix and entry.suffix ~= "" then
        self:EnrichEntrySuffix(entry)
        local link = self:MakeSuffixTargetLink(entry)
        if link then
            local _, itemHyperlink = GetItemInfo(link)
            if itemHyperlink and itemHyperlink ~= "" then
                return itemHyperlink
            end
            return link
        end
    end

    local _, itemHyperlink = GetItemInfo(entry.itemId)
    if itemHyperlink and itemHyperlink ~= "" then
        return itemHyperlink
    end

    return "item:" .. entry.itemId
end

function GQ.Data:PopulateEntryItemTooltip(tooltip, entry)
    if not tooltip or not entry or not entry.itemId then
        return false
    end

    if entry.suffix and entry.suffix ~= "" then
        self:EnrichEntrySuffix(entry)
        if self:MakeSuffixTargetLink(entry) then
            self:TryShowSuffixTargetTooltip(tooltip, entry)
            self:TrackPendingSuffixTooltip(tooltip, entry)
            return true
        end

        self:ShowSuffixFallbackTooltip(tooltip, entry)
        self:TrackPendingSuffixTooltip(tooltip, entry)
        return true
    end

    tooltip:SetHyperlink("item:" .. entry.itemId)
    if entry.proc then
        tooltip:AddLine(" ")
        tooltip:AddLine(entry.proc, 1, 1, 1, true)
    end

    return true
end

function GQ.Data:ShowEntryItemTooltip(tooltip, owner, entry, anchor, ...)
    if not tooltip or not entry or not entry.itemId then
        return
    end

    tooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT", ...)
    self:PopulateEntryItemTooltip(tooltip, entry)
    tooltip:Show()
end

function GQ.Data:CacheContainerItemLinks()
    if not self.byItemId then
        return
    end

    local function cacheLink(link)
        if not link then
            return
        end

        local itemId = self:ItemLinkToId(link)
        if not itemId then
            return
        end

        local itemName = self:ItemNameFromLink(link)
        if not itemName or not itemName:find(" of ", 1, true) then
            return
        end

        for _, entry in ipairs(self.byItemId[itemId] or {}) do
            if entry.suffix and self:EntrySuffixMatchesLink(entry, link) then
                self:CacheOwnedSuffixItemLink(entry, link)
            end
        end
    end

    for invSlot = 1, 19 do
        cacheLink(GetInventoryItemLink("player", invSlot))
    end

    local numBags = NUM_BAG_SLOTS or 4
    for bag = 0, numBags do
        local numSlots
        if C_Container and C_Container.GetContainerNumSlots then
            numSlots = C_Container.GetContainerNumSlots(bag) or 0
        elseif GetContainerNumSlots then
            numSlots = GetContainerNumSlots(bag) or 0
        else
            numSlots = 0
        end

        for slot = 1, numSlots do
            local link
            if C_Container and C_Container.GetContainerItemLink then
                link = C_Container.GetContainerItemLink(bag, slot)
            elseif GetContainerItemLink then
                link = GetContainerItemLink(bag, slot)
            end
            cacheLink(link)
        end
    end
end

function GQ.Data:NormalizeItemName(name)
    if not name then
        return nil
    end

    if strtrim then
        return strtrim(name)
    end

    return (name:gsub("^%s*(.-)%s*$", "%1"))
end

function GQ.Data:ItemNameMatchesEntry(itemName, entry)
    if not itemName or not entry then
        return false
    end

    return self:NormalizeItemName(itemName) == self:GetEntryDisplayName(entry)
end

function GQ.Data:ItemLinkToId(link)
    if not link then
        return nil
    end

    return tonumber(link:match("item:(%d+)"))
end

function GQ.Data:ItemNameFromLink(link)
    if not link then
        return nil
    end

    local itemId = self:ItemLinkToId(link)
    if itemId then
        local name = GetItemInfo(itemId)
        if name then
            return name
        end
    end

    return link:match("%[(.-)%]")
end

function GQ.Data:PlayerOwnsEntryItem(entry)
    if not entry or not entry.itemId then
        return false
    end

    self:EnrichEntrySuffix(entry)

    local itemId = entry.itemId
    local needsSuffix = entry.suffix and entry.suffix ~= ""

    local function linkMatches(link)
        if self:ItemLinkToId(link) ~= itemId then
            return false
        end

        if needsSuffix then
            return self:EntrySuffixMatchesLink(entry, link)
        end

        return true
    end

    local ok, owned = pcall(function()
        for invSlot = 1, 19 do
            if linkMatches(GetInventoryItemLink("player", invSlot)) then
                return true
            end
        end

        local numBags = NUM_BAG_SLOTS or 4
        for bag = 0, numBags do
            local numSlots
            if C_Container and C_Container.GetContainerNumSlots then
                numSlots = C_Container.GetContainerNumSlots(bag) or 0
            elseif GetContainerNumSlots then
                numSlots = GetContainerNumSlots(bag) or 0
            else
                numSlots = 0
            end

            for slot = 1, numSlots do
                local link
                if C_Container and C_Container.GetContainerItemLink then
                    link = C_Container.GetContainerItemLink(bag, slot)
                elseif GetContainerItemLink then
                    link = GetContainerItemLink(bag, slot)
                end

                if linkMatches(link) then
                    return true
                end
            end
        end

        return false
    end)

    return ok and owned or false
end

function GQ.Data:GetEntryById(id)
    if not id then
        return nil
    end
    if self.byId and self.byId[id] then
        return self.byId[id]
    end
    for _, entry in ipairs(self.entries or {}) do
        if entry.id == id then
            return entry
        end
    end
    return self:GetNotableEntryById(id)
end

function GQ.Data:InvalidatePlayerBandCache()
    self:InvalidateQueryCache()
end

function GQ.Data:InvalidateSpecCache()
    self._queryCache = nil
    self._activeBandCache = nil
end

function GQ.Data:InvalidateQueryCache()
    self._queryCache = nil
    self._activeBandCache = nil
    self._notableEntryCache = nil
end

function GQ.Data:InvalidateClassCache()
    self:InvalidateQueryCache()
    self.notableBySlot = nil
    self._notableBySlotClass = nil
end

function GQ.Data:GetQueryCacheKey()
    return self:GetActiveBandCacheKey()
end

function GQ.Data:EnsureQueryCache()
    local cacheKey = self:GetQueryCacheKey()
    if self._queryCache and self._queryCache.key == cacheKey then
        return
    end

    self._queryCache = {
        key = cacheKey,
        candidates = {},
        topUpgrades = {},
        notables = {},
        activeBandMin = nil,
    }
end

function GQ.Data:GetActiveBandCacheKey()
    local spec = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec() or ""
    return (GQ:GetEffectiveLevel() or 0) .. ":"
        .. (GQ:GetEffectiveClass() or "") .. ":"
        .. (GQ:GetEffectiveFaction() or "") .. ":"
        .. tostring(spec)
end

function GQ.Data:EntryMatchesPlayerBand(entry)
    if not entry or not entry.slot then
        return false
    end

    if not self:IsSlotUnlocked(entry.slot) then
        return false
    end

    local classFile = GQ:GetEffectiveClass()
    if entry.classes and not entry.classes[classFile] then
        return false
    end

    local faction = GQ:GetEffectiveFaction()
    if entry.factions and not entry.factions[faction] then
        return false
    end

    if not GQ.Equip:EntryWithinLevelBand(entry) then
        return false
    end

    if GQ.Equip.EntryMatchesSpec and not GQ.Equip:EntryMatchesSpec(entry) then
        return false
    end

    return true
end

function GQ.Data:EntryMatchesPlayer(entry)
    if not self:EntryMatchesPlayerBand(entry) then
        return false
    end

    if not GQ.Equip:EntryMatchesItemRules(entry) then
        return false
    end

    return true
end

function GQ.Data:SelectActiveBand(entries, playerLevel)
    playerLevel = playerLevel or GQ:GetEffectiveLevel()
    local bestMinLevel
    local bestMaxLevel

    for _, entry in ipairs(entries or {}) do
        local minLevel = entry.minLevel or 1
        local maxLevel = entry.maxLevel or playerLevel
        if playerLevel >= minLevel and playerLevel <= maxLevel then
            if not bestMinLevel
                or minLevel > bestMinLevel
                or (minLevel == bestMinLevel and maxLevel < bestMaxLevel) then
                bestMinLevel = minLevel
                bestMaxLevel = maxLevel
            end
        end
    end

    if not bestMinLevel then
        -- Wide bands (e.g. seasonal head through level 8): fall back to highest minLevel reached.
        for _, entry in ipairs(entries or {}) do
            local minLevel = entry.minLevel or 1
            if playerLevel >= minLevel then
                if not bestMinLevel or minLevel > bestMinLevel then
                    bestMinLevel = minLevel
                    bestMaxLevel = nil
                end
            end
        end
    end

    return bestMinLevel, bestMaxLevel
end

function GQ.Data:EntryInActiveBand(entry, activeMinLevel, activeMaxLevel)
    if not entry or not activeMinLevel then
        return false
    end

    if (entry.minLevel or 1) ~= activeMinLevel then
        return false
    end

    if activeMaxLevel then
        return (entry.maxLevel or activeMaxLevel) == activeMaxLevel
    end

    return true
end

function GQ.Data:FilterToActiveBand(entries)
    if not entries or #entries == 0 then
        return entries
    end

    local playerLevel = GQ:GetEffectiveLevel()
    local activeMinLevel, activeMaxLevel = self:SelectActiveBand(entries, playerLevel)

    if not activeMinLevel then
        return entries
    end

    local filtered = {}
    for _, entry in ipairs(entries) do
        if self:EntryInActiveBand(entry, activeMinLevel, activeMaxLevel) then
            table.insert(filtered, entry)
        end
    end

    return filtered
end

function GQ.Data:EntryListKey(entry)
    if not entry or not entry.itemId then
        return nil
    end

    if entry.suffix and entry.suffix ~= "" then
        if entry.suffixId and entry.suffixId ~= 0 then
            return entry.itemId .. "\0" .. tostring(entry.suffixId)
        end
        return entry.itemId .. "\0" .. entry.suffix
    end

    return tostring(entry.itemId)
end

function GQ.Data:PreferEntry(a, b)
    if not a then
        return false
    end
    if not b then
        return true
    end

    if a.generated ~= b.generated then
        return not a.generated
    end

    local rankA = a.curatedRank or 99
    local rankB = b.curatedRank or 99
    if rankA ~= rankB then
        return rankA < rankB
    end

    return (a.minLevel or 0) > (b.minLevel or 0)
end

function GQ.Data:DeduplicateEntriesByItem(entries)
    local best = {}
    local order = {}

    for _, entry in ipairs(entries or {}) do
        local key = self:EntryListKey(entry)
        if key then
            local prev = best[key]
            if not prev then
                order[#order + 1] = key
                best[key] = entry
            elseif self:PreferEntry(entry, prev) then
                best[key] = entry
            end
        end
    end

    local results = {}
    for i = 1, #order do
        results[i] = best[order[i]]
    end

    return results
end

function GQ.Data:BackfillCandidates(allEntries, filtered, minCount)
    minCount = minCount or 3
    filtered = self:DeduplicateEntriesByItem(filtered)
    if not filtered or #filtered >= minCount then
        return filtered
    end

    local playerLevel = GQ:GetEffectiveLevel()
    local activeMinLevel, activeMaxLevel = self:SelectActiveBand(allEntries, playerLevel)

    local seen = {}
    local seenItem = {}
    for _, entry in ipairs(filtered) do
        seen[entry.id] = true
        local key = self:EntryListKey(entry)
        if key then
            seenItem[key] = true
        end
    end

    local extras = {}
    for _, entry in ipairs(allEntries or {}) do
        if not seen[entry.id] and not entry.notable and self:ShouldShowEntry(entry) then
            local key = self:EntryListKey(entry)
            if key and not seenItem[key] and activeMinLevel
                and self:EntryInActiveBand(entry, activeMinLevel, activeMaxLevel) then
                extras[#extras + 1] = entry
            end
        end
    end

    table.sort(extras, function(a, b)
        local rankA = a.curatedRank or 99
        local rankB = b.curatedRank or 99
        if rankA ~= rankB then
            return rankA < rankB
        end
        return (a.minLevel or 0) > (b.minLevel or 0)
    end)

    for _, entry in ipairs(extras) do
        if #filtered >= minCount then
            break
        end
        local key = self:EntryListKey(entry)
        if key and not seenItem[key] then
            seen[entry.id] = true
            seenItem[key] = true
            filtered[#filtered + 1] = entry
        end
    end

    return self:DeduplicateEntriesByItem(filtered)
end

local NOTABLE_CLASS = {
    PALADIN = { rows = "paladinNotable", facts = "itemFacts" },
    WARRIOR = { rows = "warriorNotable", facts = "warriorItemFacts" },
    HUNTER  = { rows = "hunterNotable",  facts = "hunterItemFacts" },
    DRUID   = { rows = "druidNotable",   facts = "druidItemFacts" },
    SHAMAN  = { rows = "shamanNotable",  facts = "shamanItemFacts" },
    ROGUE   = { rows = "rogueNotable",   facts = "rogueItemFacts" },
    PRIEST  = { rows = "priestNotable",  facts = "priestItemFacts" },
    WARLOCK = { rows = "warlockNotable", facts = "warlockItemFacts" },
    MAGE    = { rows = "mageNotable",    facts = "mageItemFacts" },
}

local NOTABLE_SPECS = {
    PALADIN = {
        retribution = { retribution = true },
        protection = { protection = true },
        holy = { holy = true },
    },
    WARRIOR = {
        arms = { arms = true },
        fury = { fury = true },
        protection = { protection = true },
    },
    HUNTER = {
        beast_mastery = { beast_mastery = true },
        marksmanship  = { marksmanship  = true },
        survival      = { survival      = true },
    },
    DRUID = {
        bear        = { bear        = true },
        feral       = { feral       = true },
        balance     = { balance     = true },
        restoration = { restoration = true },
    },
    SHAMAN = {
        elemental   = { elemental   = true },
        enhancement = { enhancement = true },
        restoration = { restoration = true },
    },
    ROGUE = {
        combat        = { combat        = true },
        assassination = { assassination = true },
        subtlety      = { subtlety      = true },
    },
    PRIEST = {
        holy       = { holy       = true },
        discipline = { discipline = true },
        shadow     = { shadow     = true },
    },
    WARLOCK = {
        affliction  = { affliction  = true },
        demonology  = { demonology  = true },
        destruction = { destruction = true },
    },
    MAGE = {
        frost  = { frost  = true },
        fire   = { fire   = true },
        arcane = { arcane = true },
    },
}

function GQ.Data:BuildNotableEntry(row, facts, classFile)
    if not row or not facts then
        return nil
    end

    local itemId, slot, minL, maxL = row[1], row[2], row[3], row[4]
    local spec, faction = row[5], row[6]
    local f = facts[itemId]
    if not f then
        return nil
    end

    if self:IsExcludedItem({ itemId = itemId, proc = f.proc }) then
        return nil
    end

    if f.proc then
        local probe = { itemId = itemId, proc = f.proc }
        if self:IsNoveltyProcItem(probe) then
            return nil
        end
    end

    local classTbl = { [classFile] = true }
    local specTbl = NOTABLE_SPECS[classFile]
    local FACTION = {
        Alliance = { Alliance = true },
        Horde = { Horde = true },
    }

    local entry = {
        id = string.format("notable:%s:%d:%s:%d:%s:%s", classFile, itemId, slot, minL, tostring(spec), tostring(faction)),
        itemId = itemId,
        slot = slot,
        minLevel = minL,
        maxLevel = maxL,
        classes = classTbl,
        specs = spec and specTbl and specTbl[spec] or nil,
        factions = faction and FACTION[faction] or nil,
        sourceType = f.sourceType,
        instructions = f.instructions,
        zone = f.zone,
        npc = f.npc,
        questName = f.questName,
        profession = f.profession,
        proc = f.proc,
        suffix = row.suffix,
        suffixChance = row.suffixChance,
        suffixId = row.suffixId,
        suffixRange = row.suffixRange,
        pipelineScore = self:LookupPipelineScore(itemId, slot, minL, faction, spec),
        generated = true,
        notable = true,
    }

    self._notableEntryCache = self._notableEntryCache or {}
    local cached = self._notableEntryCache[entry.id]
    if cached then
        return cached
    end

    entry = self:EnrichEntrySuffix(entry)
    entry = self:EnrichProfessionEntry(entry)
    self._notableEntryCache[entry.id] = entry
    return entry
end

function GQ.Data:AsMainBiSEntry(entry)
    if not entry or not entry.notable then
        return entry
    end

    local copy = {}
    for key, value in pairs(entry) do
        copy[key] = value
    end
    copy.notable = false
    return copy
end

function GQ.Data:ShouldDisplayAsNotable(entry, slotName)
    if not entry or not entry.notable then
        return false
    end

    slotName = slotName and self:NormalizeSlotName(slotName)
    if not slotName then
        return true
    end

    local itemKey = self:EntryListKey(entry)
    if not itemKey then
        return true
    end

    for _, top in ipairs(self:GetTopUpgradesForSlot(slotName)) do
        if self:EntryListKey(top) == itemKey then
            return false
        end
    end

    return true
end

local function NormalizeEntryIdToken(value)
    if value == nil or value == "" or value == "nil" then
        return nil
    end
    return value
end

function GQ.Data:GetNotableEntryById(id)
    if type(id) ~= "string" or not id:match("^notable:") then
        return nil
    end

    local classFile, itemId, slot, minL, spec, faction = id:match(
        "^notable:([^:]+):(%d+):([^:]+):(%d+):([^:]*):([^:]*)$"
    )
    if not classFile then
        return nil
    end

    itemId = tonumber(itemId)
    minL = tonumber(minL)
    spec = NormalizeEntryIdToken(spec)
    faction = NormalizeEntryIdToken(faction)

    local src = NOTABLE_CLASS[classFile]
    if not src then
        return nil
    end

    local rows = self[src.rows]
    local facts = self[src.facts]
    if not rows or not facts then
        return nil
    end

    for i = 1, #rows do
        local row = rows[i]
        if row[1] == itemId
            and row[2] == slot
            and row[3] == minL
            and (row[5] or nil) == spec
            and (row[6] or nil) == faction then
            return self:BuildNotableEntry(row, facts, classFile)
        end
    end

    return nil
end

function GQ.Data:EnsureNotableBySlot(classFile)
    classFile = classFile or GQ:GetEffectiveClass()
    if self._notableBySlotClass == classFile and self.notableBySlot then
        return
    end

    self._notableEntryCache = nil
    self.notableBySlot = {}
    self._notableBySlotClass = classFile

    local src = NOTABLE_CLASS[classFile]
    local rows = src and self[src.rows]
    if not rows then
        return
    end

    for i = 1, #rows do
        local row = rows[i]
        local slot = self:NormalizeSlotName(row[2])
        self.notableBySlot[slot] = self.notableBySlot[slot] or {}
        table.insert(self.notableBySlot[slot], row)
    end
end

function GQ.Data:GetNotableForSlot(slotName)
    local classFile = GQ:GetEffectiveClass()
    local src = NOTABLE_CLASS[classFile]
    if not src then
        return {}
    end

    local rows = self[src.rows]
    local facts = self[src.facts]
    if not rows or not facts then
        return {}
    end

    slotName = self:NormalizeSlotName(slotName)
    self:EnsureQueryCache()
    local cachedNotables = self._queryCache.notables[slotName]
    if cachedNotables then
        return cachedNotables
    end

    self:EnsureNotableBySlot(classFile)
    local slotRows = self.notableBySlot[slotName]
    if not slotRows then
        return {}
    end

    local results = {}
    for i = 1, #slotRows do
        local entry = self:BuildNotableEntry(slotRows[i], facts, classFile)
        if entry and self:EntryMatchesPlayerBand(entry) then
            table.insert(results, entry)
        end
    end

    results = self:FilterToActiveBand(results)
    results = self:DeduplicateEntriesByItem(results)
    self._queryCache.notables[slotName] = results
    return results
end

function GQ.Data:GetActiveBandMinLevel()
    local cacheKey = self:GetActiveBandCacheKey()
    if self._activeBandCache and self._activeBandCache.key == cacheKey then
        return self._activeBandCache.value
    end

    self:EnsureQueryCache()
    if self._queryCache.activeBandMin ~= nil then
        self._activeBandCache = { key = cacheKey, value = self._queryCache.activeBandMin }
        return self._queryCache.activeBandMin
    end

    local merged = {}
    for _, slotName in ipairs(self.BASE_SLOTS) do
        if self:IsSlotUnlocked(slotName) then
            local candidates = self:GetCandidatesForSlot(slotName)
            for i = 1, math.min(#candidates, 8) do
                merged[#merged + 1] = candidates[i]
            end
            if #merged >= 16 then
                break
            end
        end
    end

    local activeMinLevel = self:SelectActiveBand(merged)
    self._queryCache.activeBandMin = activeMinLevel
    self._activeBandCache = { key = cacheKey, value = activeMinLevel }
    return activeMinLevel
end

function GQ.Data:IsEntryNewForPlayer(entry)
    if not entry then
        return false
    end

    local activeMinLevel = self:GetActiveBandMinLevel()
    if not activeMinLevel then
        return false
    end

    return (entry.minLevel or 1) == activeMinLevel
end

function GQ.Data:GetCandidatesForSlot(slotName)
    slotName = self:NormalizeSlotName(slotName)
    self:EnsureQueryCache()

    local cached = self._queryCache.candidates[slotName]
    if cached then
        return cached
    end

    local results = {}
    local seen = {}

    for _, key in ipairs(self:GetCandidateSlotKeys(slotName)) do
        for _, entry in ipairs(self:GetClassSlotEntryList(key) or {}) do
            if not seen[entry.id] and self:ShouldShowEntry(entry) and self:EntryMatchesPlayerBand(entry) then
                seen[entry.id] = true
                table.insert(results, entry)
            end
        end
    end

    local allMatching = results
    results = self:FilterToActiveBand(results)
    results = self:BackfillCandidates(allMatching, results, 3)
    results = self:DeduplicateEntriesByItem(results)
    self._queryCache.candidates[slotName] = results
    return results
end

GQ.Data.SLOT_LABELS = {
    Head = "Head",
    Neck = "Neck",
    Shoulder = "Shoulder",
    Back = "Back",
    Chest = "Chest",
    Wrist = "Wrist",
    Hands = "Hands",
    Waist = "Waist",
    Legs = "Legs",
    Feet = "Feet",
    Finger = "Finger",
    Trinket = "Trinket",
    MainHand = "Main Hand",
    SecondaryHand = "Off Hand",
    Ranged = "Ranged",
}

GQ.Data.BASE_SLOTS = {
    "Head", "Neck", "Shoulder", "Back", "Chest", "Wrist", "Hands",
    "Waist", "Legs", "Feet", "Finger", "Trinket",
    "MainHand", "SecondaryHand",
}

-- CharacterFrame slot buttons (Character{Name}Slot). Ranged is one UI slot for all
-- class relics: librams/relics, idols, totems, wands, bows/guns/crossbows.
GQ.Data.PAPER_DOLL_SLOTS = {
    "Head", "Neck", "Shoulder", "Back", "Chest", "Wrist", "Hands",
    "Waist", "Legs", "Feet", "Finger0", "Finger1", "Trinket0", "Trinket1",
    "MainHand", "SecondaryHand", "Ranged",
}

GQ.Data.CLASS_RANGED = {
    WARRIOR = true,
    ROGUE = true,
    HUNTER = true,
    MAGE = true,
    PRIEST = true,
    WARLOCK = true,
    SHAMAN = true,
    PALADIN = true,
    DRUID = true,
}

-- GearQuest log/popup slots that unlock at specific character levels.
-- Milestone chat messages for these slots: see docs/DATA_RULES.md § Slot unlock & level-up messages.
GQ.Data.SLOT_UNLOCK_LEVEL = {
    Finger = 9,
    Shoulder = 9,
}

function GQ.Data:GetSlotUnlockLevel(slotName)
    slotName = self:NormalizeSlotName(slotName)
    return self.SLOT_UNLOCK_LEVEL[slotName] or 1
end

function GQ.Data:IsSlotUnlocked(slotName)
    return GQ:GetEffectiveLevel() >= self:GetSlotUnlockLevel(slotName)
end

function GQ.Data:GetSlotsForClass(classFile)
    local slots = {}
    local seen = {}

    for _, slotName in ipairs(self.BASE_SLOTS) do
        slotName = self:NormalizeSlotName(slotName)
        if not seen[slotName] and self:IsSlotUnlocked(slotName) then
            seen[slotName] = true
            table.insert(slots, slotName)
        end
    end

    if self.CLASS_RANGED[classFile] and not seen.Ranged then
        table.insert(slots, "Ranged")
    end

    return slots
end

function GQ.Data:GetMaxUpgradesForSlot(slotName)
    return 3
end

function GQ.Data:RegisterPipelineScore(itemId, slot, minLevel, faction, spec, score)
    if not score then
        return
    end
    self._pipelineScoreLookup = self._pipelineScoreLookup or {}
    local key = string.format(
        "%d:%s:%d:%s:%s",
        itemId or 0,
        slot or "",
        minLevel or 0,
        tostring(faction),
        tostring(spec)
    )
    self._pipelineScoreLookup[key] = score
end

function GQ.Data:LookupPipelineScore(itemId, slot, minLevel, faction, spec)
    if not self._pipelineScoreLookup then
        return nil
    end
    local key = string.format(
        "%d:%s:%d:%s:%s",
        itemId or 0,
        slot or "",
        minLevel or 0,
        tostring(faction),
        tostring(spec)
    )
    return self._pipelineScoreLookup[key]
end

function GQ.Data:GetRankableEntriesForSlot(slotName)
    slotName = self:NormalizeSlotName(slotName)
    local merged = {}
    local seen = {}

    local function add(entry)
        if not entry or not entry.id or seen[entry.id] then
            return
        end
        seen[entry.id] = true
        merged[#merged + 1] = entry
    end

    for _, entry in ipairs(self:GetCandidatesForSlot(slotName)) do
        add(entry)
    end

    for _, entry in ipairs(self:GetNotableForSlot(slotName)) do
        add(entry)
    end

    return merged
end

function GQ.Data:GetTopUpgradesForSlot(slotName, maxResults)
    slotName = self:NormalizeSlotName(slotName)
    maxResults = maxResults or self:GetMaxUpgradesForSlot(slotName)
    self:EnsureQueryCache()

    local cacheKey = slotName .. ":" .. maxResults
    local cached = self._queryCache.topUpgrades[cacheKey]
    if cached then
        return cached
    end

    local candidates = self:GetRankableEntriesForSlot(slotName)
    local ranked = GQ.Compare:RankEntries(candidates, slotName, maxResults)
    local results = {}
    for i = 1, #ranked do
        results[i] = self:AsMainBiSEntry(ranked[i])
    end
    self._queryCache.topUpgrades[cacheKey] = results
    return results
end

function GQ.Data:GetWeaponRouteForBand()
    for _, slot in ipairs({ "MainHand", "SecondaryHand" }) do
        for _, entry in ipairs(self:GetCandidatesForSlot(slot)) do
            if entry.route then
                return entry.route
            end
        end
    end
    return nil
end

function GQ.Data:GetWeaponRouteLabel(route)
    route = route or self:GetWeaponRouteForBand()
    if not route then
        return nil
    end
    local classFile = GQ:GetEffectiveClass()
    local spec = GQ:GetEffectiveSpec()
    local dualWieldTerms = classFile == "HUNTER"
        or (classFile == "SHAMAN" and spec == "enhancement")
    if route == "twohand" then
        return dualWieldTerms and "Two-hand build" or "Staff build"
    end
    return dualWieldTerms and "Dual-wield build" or "One-hand + off-hand"
end

function GQ.Data:EntryOffWeaponRoute(entry, slotName)
    if not entry or not entry.route then
        return false
    end
    slotName = self:NormalizeSlotName(slotName)
    if entry.route == "twohand" then
        return slotName == "SecondaryHand"
    end
    if entry.route == "onehand" and slotName == "MainHand" and GQ.Equip then
        return GQ.Equip:IsTwoHandWeapon(entry.itemId)
    end
    return false
end

function GQ.Data:SlotHeaderLabel(slotName)
    slotName = self:NormalizeSlotName(slotName)
    local label = self:SlotLabel(slotName)
    if slotName == "MainHand" or slotName == "SecondaryHand" then
        local routeLabel = self:GetWeaponRouteLabel()
        if routeLabel then
            return label .. " — " .. routeLabel
        end
    end
    return label
end

function GQ.Data:SlotLabel(slotName)
    slotName = self:NormalizeSlotName(slotName)
    if slotName == "Ranged" then
        local classFile = GQ:GetEffectiveClass()
        if classFile == "SHAMAN" then
            return "Totem"
        end
        if classFile == "DRUID" then
            return "Idol"
        end
        if classFile == "PALADIN" then
            return "Relic"
        end
        if classFile == "MAGE" or classFile == "PRIEST" or classFile == "WARLOCK" then
            return "Wand"
        end
    end
    return self.SLOT_LABELS[slotName] or slotName
end
