/**
 * Import AtlasLoot Phase 3 (BT/Hyjal) BiS lists into GearQuest Data.lua entries.
 *
 * Source: AtlasLootClassic_TBC_Phase_3_BT_Hyjal/phasethreeDB.lua
 * Enrichment: Wowhead TBC tooltip API + curated overrides (tokens, quests, trash).
 *
 * Usage:
 *   node scripts/import-atlasloot-p3-bis.mjs                    # all 21 spec lists
 *   node scripts/import-atlasloot-p3-bis.mjs ShamanElemental_P3 # one list
 *   node scripts/import-atlasloot-p3-bis.mjs --top 3              # ranks per slot (default 3)
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(__dirname, "..");
const ATLAS_P3 = path.join(
  "C:/Program Files (x86)/World of Warcraft/_anniversary_/Interface/AddOns",
  "AtlasLootClassic_TBC_Phase_3_BT_Hyjal/phasethreeDB.lua"
);
const OUT_DIR = path.join(ROOT, "scripts/output");
const OUT_LUA = path.join(OUT_DIR, "p3-bis-import.lua");
const OUT_JSON = path.join(OUT_DIR, "p3-bis-import.json");

const LEVEL = 70;
const TOP_ARG = process.argv.find((a) => a.startsWith("--top="));
const TOP_N = TOP_ARG ? parseInt(TOP_ARG.split("=")[1], 10) : 3;
const FILTER = process.argv.find((a) => !a.startsWith("--") && !a.endsWith(".mjs") && a.endsWith("_P3"));

const MENU_ORDER = [
  "Rogue_P3",
  "HunterBM_P3",
  "HunterSurv_P3",
  "DruidBalance_P3",
  "DruidBear_P3",
  "DruidCat_P3",
  "DruidRestoration_P3",
  "MageArcane_P3",
  "MageFire_P3",
  "PaladinHoly_P3",
  "PaladinProtection_P3",
  "PaladinRetribution_P3",
  "PriestHoly_P3",
  "PriestShadow_P3",
  "ShamanElemental_P3",
  "ShamanEnhancement_P3",
  "ShamanRestoration_P3",
  "WarlockDestruction_P3",
  "WarriorArms_P3",
  "WarriorFury_P3",
  "WarriorProt_P3",
];

const CLASS_CONST = {
  ROGUE: "ROGUE",
  HUNTER: "HUNTER",
  DRUID: "DRUID",
  MAGE: "MAGE",
  PALADIN: "PALADIN",
  PRIEST: "PRIEST",
  SHAMAN: "SHAMAN",
  WARLOCK: "WARLOCK",
  WARRIOR: "WARRIOR",
};

const SPEC_CONST = {
  combat: "SPEC_COMBAT",
  beast_mastery: "SPEC_BEAST_MASTERY",
  survival: "SPEC_SURVIVAL",
  balance: "SPEC_BALANCE",
  bear: "SPEC_BEAR",
  feral: "SPEC_FERAL",
  restoration: "SPEC_RESTORATION",
  arcane: "SPEC_ARCANE",
  fire: "SPEC_FIRE",
  holy: "SPEC_HOLY",
  protection: "SPEC_PROTECTION",
  retribution: "SPEC_RETRIBUTION",
  shadow: "SPEC_SHADOW",
  elemental: "SPEC_ELEMENTAL",
  enhancement: "SPEC_ENHANCEMENT",
  destruction: "SPEC_DESTRUCTION",
  arms: "SPEC_ARMS",
  fury: "SPEC_FURY",
};

const LIST_MAP = {
  Rogue_P3: { class: "ROGUE", spec: "combat" },
  HunterBM_P3: { class: "HUNTER", spec: "beast_mastery" },
  HunterSurv_P3: { class: "HUNTER", spec: "survival" },
  DruidBalance_P3: { class: "DRUID", spec: "balance" },
  DruidBear_P3: { class: "DRUID", spec: "bear" },
  DruidCat_P3: { class: "DRUID", spec: "feral" },
  DruidRestoration_P3: { class: "DRUID", spec: "restoration" },
  MageArcane_P3: { class: "MAGE", spec: "arcane" },
  MageFire_P3: { class: "MAGE", spec: "fire" },
  PaladinHoly_P3: { class: "PALADIN", spec: "holy" },
  PaladinProtection_P3: { class: "PALADIN", spec: "protection" },
  PaladinRetribution_P3: { class: "PALADIN", spec: "retribution" },
  PriestHoly_P3: { class: "PRIEST", spec: "holy" },
  PriestShadow_P3: { class: "PRIEST", spec: "shadow" },
  ShamanElemental_P3: { class: "SHAMAN", spec: "elemental" },
  ShamanEnhancement_P3: { class: "SHAMAN", spec: "enhancement" },
  ShamanRestoration_P3: { class: "SHAMAN", spec: "restoration" },
  WarlockDestruction_P3: { class: "WARLOCK", spec: "destruction" },
  WarriorArms_P3: { class: "WARRIOR", spec: "arms" },
  WarriorFury_P3: { class: "WARRIOR", spec: "fury" },
  WarriorProt_P3: { class: "WARRIOR", spec: "protection" },
};

const SLOT_MAP = {
  Head: "Head",
  Shoulders: "Shoulder",
  Back: "Back",
  Chest: "Chest",
  Wrist: "Wrist",
  Hands: "Hands",
  Waist: "Waist",
  Legs: "Legs",
  Feet: "Feet",
  Neck: "Neck",
  Rings: "Finger",
  Trinkets: "Trinket",
  "Main Hand": "MainHand",
  Offhand: "SecondaryHand",
  Twohand: "MainHand",
  Ranged: "Ranged",
  Totems: "Ranged",
  Wand: "Ranged",
};

const T6_SET_PREFIXES = [
  "Skyshatter",
  "Onslaught",
  "Gronnstalker",
  "Lightbringer",
  "Absolution",
  "Malefic",
  "Slayer",
  "Tempest",
  "Thunderheart",
];

const T5_SET_PREFIXES = [
  "Cyclone",
  "Cataclysm",
  "Destroyer",
  "Gronnstalker",
  "Justicar",
  "Incarnate",
  "Voidheart",
  "Deathmantle",
  "Netherblade",
  "Tirisfal",
  "Nordrassil",
  "Rift Stalker",
];

const T6_TOKEN = {
  Head: { boss: "Archimonde", zone: "Hyjal Summit", label: "helm" },
  Shoulder: { boss: "Mother Shahraz", zone: "Black Temple", label: "shoulder" },
  Chest: { boss: "Illidan Stormrage", zone: "Black Temple", label: "chest" },
  Hands: { boss: "Azgalor", zone: "Hyjal Summit", label: "hand" },
  Legs: { boss: "Illidari Council", zone: "Black Temple", label: "leg" },
};

const T5_TOKEN = {
  Head: { boss: "Lady Vashj", zone: "Serpentshrine Cavern", label: "helm" },
  Shoulder: { boss: "Void Reaver", zone: "Tempest Keep", label: "shoulder" },
  Chest: { boss: "Kael'thas Sunstrider", zone: "Tempest Keep", label: "chest" },
  Hands: { boss: "Leotheras the Blind", zone: "Serpentshrine Cavern", label: "hand" },
  Legs: { boss: "Fathom-Lord Karathress", zone: "Serpentshrine Cavern", label: "leg" },
};

const BOSS_ZONE = {
  "Illidan Stormrage": "Black Temple",
  "High Warlord Naj'entus": "Black Temple",
  "Supremus": "Black Temple",
  "Shade of Akama": "Black Temple",
  "Teron Gorefiend": "Black Temple",
  "Gurtogg Bloodboil": "Black Temple",
  "Mother Shahraz": "Black Temple",
  "High Nethermancer Zerevor": "Black Temple",
  "Essence of Anger": "Black Temple",
  "Archimonde": "Hyjal Summit",
  Azgalor: "Hyjal Summit",
  "Rage Winterchill": "Hyjal Summit",
  Anetheron: "Hyjal Summit",
  "Kaz'rogal": "Hyjal Summit",
  "Lady Vashj": "Serpentshrine Cavern",
  "Kael'thas Sunstrider": "Tempest Keep",
  "Fathom-Lord Karathress": "Serpentshrine Cavern",
  "Hydross the Unstable": "Serpentshrine Cavern",
  "High King Maulgar": "Gruul's Lair",
  "Gruul the Dragonkiller": "Gruul's Lair",
  "Terestian Illhoof": "Karazhan",
  Moroes: "Karazhan",
  "Shade of Aran": "Karazhan",
  "Void Reaver": "Tempest Keep",
  "Al'ar": "Tempest Keep",
  "Leotheras the Blind": "Serpentshrine Cavern",
};

/** Curated overrides where Wowhead tooltips are incomplete or misleading. */
const ITEM_OVERRIDES = {
  30015: {
    sourceType: "quest_reward",
    instructions:
      "Kill Kael'thas Sunstrider in The Eye (Tempest Keep) for the Verdant Sphere, then complete Kael'thas and the Verdant Sphere with A'dal in Shattrath to choose The Sun King's Talisman.",
    zone: "Tempest Keep",
    npc: "Kael'thas Sunstrider",
    questName: "Kael'thas and the Verdant Sphere",
  },
  32527: {
    sourceType: "raid_trash",
    instructions: "Trash drop from mobs throughout Black Temple.",
    zone: "Black Temple",
  },
  32592: {
    sourceType: "raid_trash",
    instructions:
      "Trash drop from mobs throughout Black Temple. Also drops from trash in Battle for Mount Hyjal.",
    zone: "Black Temple",
  },
  28248: {
    sourceType: "boss_drop",
    instructions:
      "Loot Totem of the Void from the Cache of the Legion in The Mechanar. Combine the Jagged Blue Crystal from Gatewatcher Gyro-Kill and the Jagged Red Crystal from Gatewatcher Iron-Hand to unlock the cache.",
    zone: "The Mechanar",
    npc: "Cache of the Legion",
  },
  29305: {
    sourceType: "vendor",
    instructions:
      "Get Band of the Eternal Sage from Soridormi in Caverns of Time at Exalted with The Scale of the Sands.",
    zone: "Caverns of Time",
    npc: "Soridormi",
  },
  29370: {
    sourceType: "vendor",
    instructions:
      "Purchase Icon of the Silver Crescent with Badge of Justice from G'eras in Shattrath (41 badges).",
    zone: "Shattrath City",
    npc: "G'eras",
  },
  29301: {
    sourceType: "vendor",
    instructions:
      "Get Band of the Eternal Champion from Soridormi in Caverns of Time at Exalted with The Scale of the Sands.",
    zone: "Caverns of Time",
    npc: "Soridormi",
  },
  29302: {
    sourceType: "vendor",
    instructions:
      "Get Band of the Eternal Defender from Soridormi in Caverns of Time at Exalted with The Scale of the Sands.",
    zone: "Caverns of Time",
    npc: "Soridormi",
  },
  29303: {
    sourceType: "vendor",
    instructions:
      "Get Band of the Eternal Restorer from Soridormi in Caverns of Time at Exalted with The Scale of the Sands.",
    zone: "Caverns of Time",
    npc: "Soridormi",
  },
  29304: {
    sourceType: "vendor",
    instructions:
      "Get Band of the Eternal Sage from Soridormi in Caverns of Time at Exalted with The Scale of the Sands.",
    zone: "Caverns of Time",
    npc: "Soridormi",
  },
  29381: {
    sourceType: "vendor",
    instructions:
      "Purchase Choker of Vile Intent with Badge of Justice from G'eras in Shattrath.",
    zone: "Shattrath City",
    npc: "G'eras",
  },
};

const PROFESSION_PATTERNS = [
  { pattern: /Nimble Thought/i, profession: "Tailoring" },
  { pattern: /Belt of Blasting/i, profession: "Tailoring" },
  { pattern: /Spellstrike/i, profession: "Tailoring" },
  { pattern: /Frozen Shadoweave/i, profession: "Tailoring" },
  { pattern: /Swiftstrike/i, profession: "Leatherworking" },
  { pattern: /Primalstrike/i, profession: "Leatherworking" },
  { pattern: /Windhawk/i, profession: "Leatherworking" },
  { pattern: /Drums of Battle/i, profession: "Leatherworking" },
  { pattern: /Hard Khorium/i, profession: "Blacksmithing" },
  { pattern: /Living Earth/i, profession: "Leatherworking" },
  { pattern: /Red Havoc/i, profession: "Blacksmithing" },
  { pattern: /Boots of Utter/i, profession: "Leatherworking" },
];

const wowheadCache = new Map();

function slugify(name) {
  return (name || "item")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_|_$/g, "");
}

const SLOT_BLOCK_RE =
  /name\s*=\s*format\(AL\["([^"]+)"\][^)]*\),\s*\[NORMAL_DIFF\]\s*=\s*\{((?:\s*\{\s*\d+\s*,\s*\d+\s*\}\s*,?\s*)+)\}/g;
const ITEM_PAIR_RE = /\{\s*(\d+)\s*,\s*(\d+)\s*\}/g;

function parseAtlasLists(text) {
  const lists = {};

  for (const key of Object.keys(LIST_MAP)) {
    const marker = `data["${key}"]`;
    const start = text.indexOf(marker);
    if (start < 0) continue;

    const next = text.indexOf('data["', start + marker.length);
    const chunk = next > start ? text.slice(start, next) : text.slice(start);

    const slots = {};
    const slotBlocks = [...chunk.matchAll(SLOT_BLOCK_RE)];
    for (const [, atlasSlot, itemBlock] of slotBlocks) {
      const items = [...itemBlock.matchAll(ITEM_PAIR_RE)]
        .map((x) => ({ rank: +x[1], itemId: +x[2] }))
        .sort((a, b) => a.rank - b.rank)
        .slice(0, TOP_N);
      if (items.length) slots[atlasSlot] = items;
    }
    if (Object.keys(slots).length) lists[key] = slots;
  }

  return lists;
}

function parseTooltip(tooltip) {
  const text = tooltip.replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim();
  return {
    text,
    drop: text.match(/Dropped by: ([^.]+)/)?.[1]?.replace(/ Drop Chance:.*/, "")?.trim() ?? null,
    sold: text.match(/Sold by: ([^.]+)/)?.[1]?.trim() ?? null,
  };
}

async function fetchWowhead(itemId) {
  if (wowheadCache.has(itemId)) return wowheadCache.get(itemId);
  const r = await fetch(`https://nether.wowhead.com/tbc/tooltip/item/${itemId}?dataEnv=8&locale=0`);
  const j = await r.json();
  const info = parseTooltip(j.tooltip || "");
  const data = { itemId, name: j.name || `Item ${itemId}`, ...info };
  wowheadCache.set(itemId, data);
  await sleep(120);
  return data;
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function tokenSlot(atlasSlot) {
  if (atlasSlot === "Shoulders") return "Shoulder";
  return atlasSlot;
}

function isTierVendorPiece(name, atlasSlot, prefixes) {
  const slot = tokenSlot(atlasSlot);
  return (
    prefixes.some((p) => name.includes(p)) &&
    ["Head", "Shoulder", "Chest", "Hands", "Legs"].includes(slot)
  );
}

function buildTierVendorEntry(name, atlasSlot, tier) {
  const slot = tokenSlot(atlasSlot);
  const tokenTable = tier === 6 ? T6_TOKEN : T5_TOKEN;
  const token = tokenTable[slot];
  if (!token) return null;
  const vendor =
    tier === 6
      ? { npc: "Tydormu", zone: "Hyjal Summit" }
      : { npc: "Arodis Sunblade", zone: "Shattrath City" };
  return {
    sourceType: "vendor",
    instructions: `Get ${name} from ${vendor.npc} at ${vendor.zone}. Requires a Tier ${tier} ${token.label} token from ${token.boss} in ${token.zone}.`,
    zone: vendor.zone,
    npc: vendor.npc,
  };
}

function buildProfessionEntry(name, profession) {
  return {
    sourceType: "profession",
    profession,
    instructions: `Learn ${name} from a ${profession} pattern and craft at a loom or forge (${profession} 375). BoE — often crafted or bought from the Auction House.`,
    zone: "Shattrath City",
  };
}

function inferSource(item, atlasSlot, wow) {
  if (ITEM_OVERRIDES[item.itemId]) return { ...ITEM_OVERRIDES[item.itemId] };

  const name = wow.name;

  if (isTierVendorPiece(name, atlasSlot, T6_SET_PREFIXES)) {
    const e = buildTierVendorEntry(name, atlasSlot, 6);
    if (e) return e;
  }
  if (isTierVendorPiece(name, atlasSlot, T5_SET_PREFIXES)) {
    const e = buildTierVendorEntry(name, atlasSlot, 5);
    if (e) return e;
  }

  for (const p of PROFESSION_PATTERNS) {
    if (p.pattern.test(name)) return buildProfessionEntry(name, p.profession);
  }

  if (/Band of the Eternal/i.test(name)) {
    return {
      sourceType: "vendor",
      instructions: `Get ${name} from Soridormi in Caverns of Time at Exalted with The Scale of the Sands.`,
      zone: "Caverns of Time",
      npc: "Soridormi",
    };
  }

  if (/Choker of Serrated Blades/i.test(name)) {
    return {
      sourceType: "raid_trash",
      instructions:
        "Trash drop from mobs throughout Black Temple and Battle for Mount Hyjal.",
      zone: "Black Temple",
    };
  }

  if (/Gladiator/i.test(name)) {
    return {
      sourceType: "vendor",
      instructions: `Purchase ${name} with arena points from the PvP vendor in Shattrath (Season 3).`,
      zone: "Shattrath City",
      npc: "Meminnie",
    };
  }

  if (wow.drop) {
    const zone = BOSS_ZONE[wow.drop] || "Black Temple";
    return {
      sourceType: "boss_drop",
      instructions: `Farm ${wow.drop} in ${zone} for ${name}.`,
      zone,
      npc: wow.drop,
    };
  }

  if (wow.sold) {
    return {
      sourceType: "vendor",
      instructions: `Purchase ${name} from ${wow.sold}.`,
      zone: "Shattrath City",
      npc: wow.sold.split(",")[0].trim(),
    };
  }

  return {
    sourceType: "boss_drop",
    instructions: `Obtain ${name} (source not in Wowhead tooltip — verify manually).`,
    zone: "Unknown",
    needsReview: true,
  };
}

function luaString(s) {
  return s.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

function entryId(listKey, atlasSlot, wow) {
  const meta = LIST_MAP[listKey];
  return `level70_${meta.class.toLowerCase()}_${meta.spec}_${slugify(atlasSlot)}_${slugify(wow.name)}`;
}

function renderLuaEntry(listKey, atlasSlot, rank, item, source, wow) {
  const meta = LIST_MAP[listKey];
  const classRef = CLASS_CONST[meta.class] || `{ ${meta.class} = true }`;
  const specRef = SPEC_CONST[meta.spec] || `{ ${meta.spec} = true }`;
  const gqSlot = SLOT_MAP[atlasSlot] || (atlasSlot === "Shoulders" ? "Shoulder" : atlasSlot);
  const lines = [
    "    {",
    `        id = "${entryId(listKey, atlasSlot, wow)}",`,
    `        itemId = ${item.itemId},`,
    `        slot = "${gqSlot}",`,
    `        minLevel = LEVEL70_MIN,`,
    `        maxLevel = LEVEL70_MAX,`,
    `        classes = ${classRef},`,
    `        specs = ${specRef},`,
    `        curatedRank = ${rank},`,
    `        sourceType = "${source.sourceType}",`,
  ];
  if (source.profession) lines.push(`        profession = "${source.profession}",`);
  lines.push(`        instructions = "${luaString(source.instructions)}",`);
  if (source.zone && source.zone !== "Unknown") lines.push(`        zone = "${luaString(source.zone)}",`);
  if (source.npc) lines.push(`        npc = "${luaString(source.npc)}",`);
  if (source.questName) lines.push(`        questName = "${luaString(source.questName)}",`);
  lines.push("    },");
  return lines.join("\n");
}

async function main() {
  if (!fs.existsSync(ATLAS_P3)) {
    console.error("AtlasLoot Phase 3 DB not found:", ATLAS_P3);
    process.exit(1);
  }

  const text = fs.readFileSync(ATLAS_P3, "utf8");
  const lists = parseAtlasLists(text);
  if (!Object.keys(lists).length) {
    console.error("Parser found 0 lists in", ATLAS_P3, "(file length", text.length + ")");
    process.exit(1);
  }
  const keys = FILTER ? [FILTER] : MENU_ORDER.filter((k) => LIST_MAP[k]);
  const report = { generatedAt: new Date().toISOString(), lists: {}, needsReview: [] };
  const luaChunks = [
    "    -- Level 70 band — Phase 3 BT/Hyjal BiS (AtlasLoot import, all specs)",
    "",
  ];

  for (const listKey of keys) {
    const slots = lists[listKey];
    if (!slots) {
      console.warn("Missing list:", listKey);
      continue;
    }
    const meta = LIST_MAP[listKey];
    luaChunks.push(`    -- ${meta.class} / ${meta.spec} (AtlasLoot ${listKey})`);
    if (meta.note) luaChunks.push(`    -- NOTE: ${meta.note}`);
    report.lists[listKey] = { class: meta.class, spec: meta.spec, entries: [] };

    for (const [atlasSlot, items] of Object.entries(slots)) {
      for (const item of items) {
        const wow = await fetchWowhead(item.itemId);
        const source = inferSource(item, atlasSlot, wow);
        const entry = {
          listKey,
          atlasSlot,
          rank: item.rank,
          itemId: item.itemId,
          name: wow.name,
          ...source,
        };
        report.lists[listKey].entries.push(entry);
        if (source.needsReview) report.needsReview.push(entry);
        luaChunks.push(renderLuaEntry(listKey, atlasSlot, item.rank, item, source, wow));
      }
      luaChunks.push("");
    }
  }

  fs.mkdirSync(OUT_DIR, { recursive: true });
  fs.writeFileSync(OUT_LUA, luaChunks.join("\n"));
  fs.writeFileSync(OUT_JSON, JSON.stringify(report, null, 2));

  const total = Object.values(report.lists).reduce((n, l) => n + l.entries.length, 0);
  console.log(`Wrote ${total} entries for ${keys.length} list(s).`);
  console.log(`  Lua:  ${OUT_LUA}`);
  console.log(`  JSON: ${OUT_JSON}`);
  if (report.needsReview.length) {
    console.log(`  ${report.needsReview.length} item(s) need manual review (no Wowhead drop/sold).`);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
