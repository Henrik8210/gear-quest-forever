import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const j = JSON.parse(
  fs.readFileSync(path.join(__dirname, "output/p3-bis-import.json"), "utf8")
);
const entries = j.lists.Rogue_P3.entries;

const zoneFix = {
  "Gruul the Dragonkiller": "Gruul's Lair",
  Moroes: "Karazhan",
  "Shade of Aran": "Karazhan",
  "Void Reaver": "Tempest Keep",
  "Al'ar": "Tempest Keep",
};

const overrides = {
  32591: {
    sourceType: "raid_trash",
    instructions:
      "Trash drop from mobs throughout Black Temple and Battle for Mount Hyjal.",
    zone: "Black Temple",
    npc: null,
  },
  29381: {
    sourceType: "vendor",
    instructions:
      "Purchase Choker of Vile Intent with Badge of Justice from G'eras in Shattrath.",
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
};

const slotMap = {
  Shoulders: "Shoulder",
  Rings: "Finger",
  Trinkets: "Trinket",
  "Main Hand": "MainHand",
  Offhand: "SecondaryHand",
};

function slug(n) {
  return n.toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_|_$/g, "");
}

function luaStr(s) {
  return s.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

const lines = [
  "    -- Level 70 band — Combat rogue (Phase 3 BT/Hyjal BiS, AtlasLoot import)",
  "",
];

for (const e of entries) {
  const copy = { ...e, ...(overrides[e.itemId] || {}) };
  if (copy.itemId === 28830) {
    copy.instructions =
      "Farm Gruul the Dragonkiller in Gruul's Lair for Dragonspine Trophy.";
    copy.zone = "Gruul's Lair";
  } else if (copy.npc && zoneFix[copy.npc]) {
    copy.zone = zoneFix[copy.npc];
    copy.instructions = `Farm ${copy.npc} in ${copy.zone} for ${copy.name}.`;
  }

  const gqSlot = slotMap[copy.atlasSlot] || copy.atlasSlot;

  lines.push("    {");
  lines.push(
    `        id = "level70_rogue_combat_${slug(copy.atlasSlot)}_${slug(copy.name)}",`
  );
  lines.push(`        itemId = ${copy.itemId},`);
  lines.push(`        slot = "${gqSlot}",`);
  lines.push("        minLevel = LEVEL70_MIN,");
  lines.push("        maxLevel = LEVEL70_MAX,");
  lines.push("        classes = ROGUE,");
  lines.push("        specs = SPEC_COMBAT,");
  lines.push(`        curatedRank = ${copy.rank},`);
  lines.push(`        sourceType = "${copy.sourceType}",`);
  if (copy.profession) lines.push(`        profession = "${copy.profession}",`);
  lines.push(`        instructions = "${luaStr(copy.instructions)}",`);
  if (copy.zone && copy.zone !== "Unknown") lines.push(`        zone = "${luaStr(copy.zone)}",`);
  if (copy.npc) lines.push(`        npc = "${luaStr(copy.npc)}",`);
  lines.push("    },");
  lines.push("");
}

const out = path.join(__dirname, "output/rogue-p3-data.lua");
fs.writeFileSync(out, lines.join("\n"));
console.log("Wrote", entries.length, "entries to", out);
