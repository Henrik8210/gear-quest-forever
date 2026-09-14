/**
 * Clone level-70 curated BiS rows for specs that share gear pools.
 * Run: node scripts/clone-level70-specs.mjs
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const dataPath = path.join(__dirname, "..", "GearQuest", "Data.lua");

let text = fs.readFileSync(dataPath, "utf8");

if (text.includes('id = "level70_priest_discipline_')) {
  console.log("Level-70 clones already present — skipping.");
  process.exit(0);
}

function extractSpecEntries(sourceText, className, sourceSpec) {
  const prefix = `level70_${className}_${sourceSpec}_`;
  const escaped = prefix.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const re = new RegExp(
    `(    \\{\\n        id = "${escaped}[^"]+",[\\s\\S]*?\\n    \\},)`,
    "g",
  );
  return [...sourceText.matchAll(re)].map((m) => m[1]);
}

function cloneBlock(block, sourceSpec, targetSpec, specConst) {
  const src = sourceSpec.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return block
    .replace(new RegExp(`level70_([a-z]+)_${src}_`, "g"), `level70_$1_${targetSpec}_`)
    .replace(/specs = SPEC_[A-Z_]+/, `specs = ${specConst}`);
}

function insertBefore(needle, insertion) {
  const idx = text.indexOf(needle);
  if (idx < 0) throw new Error(`Needle not found: ${needle}`);
  text = text.slice(0, idx) + insertion + "\n\n    " + text.slice(idx);
}

const SPEC_CONST = {
  discipline: "SPEC_DISCIPLINE",
  frost: "SPEC_FROST",
  affliction: "SPEC_AFFLICTION",
  demonology: "SPEC_DEMONOLOGY",
  assassination: "SPEC_ASSASSINATION",
  subtlety: "SPEC_SUBTLETY",
};

// Extract from pristine snapshot before any inserts.
const holy = extractSpecEntries(text, "priest", "holy");
const arcane = extractSpecEntries(text, "mage", "arcane");
const destruction = extractSpecEntries(text, "warlock", "destruction");
const combat = extractSpecEntries(text, "rogue", "combat");

if (!holy.length) throw new Error("No holy priest entries found");
if (!arcane.length) throw new Error("No arcane mage entries found");
if (!destruction.length) throw new Error("No destruction warlock entries found");
if (!combat.length) throw new Error("No combat rogue entries found");

// --- SPEC_* constants (before entries reference them) ---
if (!text.includes("local SPEC_DISCIPLINE")) {
  text = text.replace(
    "local SPEC_HOLY = { holy = true }",
    `local SPEC_HOLY = { holy = true }
local SPEC_DISCIPLINE = { discipline = true }`,
  );
}
if (!text.includes("local SPEC_FROST")) {
  text = text.replace(
    "local SPEC_FIRE = { fire = true }",
    `local SPEC_FIRE = { fire = true }
local SPEC_FROST = { frost = true }`,
  );
}
if (!text.includes("local SPEC_AFFLICTION")) {
  text = text.replace(
    "local SPEC_DESTRUCTION = { destruction = true }",
    `local SPEC_DESTRUCTION = { destruction = true }
local SPEC_AFFLICTION = { affliction = true }
local SPEC_DEMONOLOGY = { demonology = true }`,
  );
}
if (!text.includes("local SPEC_ASSASSINATION")) {
  text = text.replace(
    "local SPEC_COMBAT = { combat = true }",
    `local SPEC_COMBAT = { combat = true }
local SPEC_ASSASSINATION = { assassination = true }
local SPEC_SUBTLETY = { subtlety = true }`,
  );
}

const discipline = holy.map((b) => cloneBlock(b, "holy", "discipline", SPEC_CONST.discipline));
insertBefore(
  "    -- PRIEST / shadow (AtlasLoot PriestShadow_P3)",
  `    -- PRIEST / discipline (copy of holy @ 70 — healing cloth, same item pool)\n${discipline.join("\n\n")}`,
);

const frost = arcane.map((b) => cloneBlock(b, "arcane", "frost", SPEC_CONST.frost));
insertBefore(
  "    -- MAGE / fire (AtlasLoot MageFire_P3)",
  `    -- MAGE / frost (copy of arcane @ 70 — spell damage / hit / int)\n${frost.join("\n\n")}`,
);

const affliction = destruction.map((b) =>
  cloneBlock(b, "destruction", "affliction", SPEC_CONST.affliction),
);
const demonology = destruction.map((b) =>
  cloneBlock(b, "destruction", "demonology", SPEC_CONST.demonology),
);
insertBefore(
  "    -- WARRIOR / arms (AtlasLoot WarriorArms_P3)",
  `    -- WARLOCK / affliction (copy of destruction @ 70 — TBC has no school-specific gear)\n${affliction.join("\n\n")}\n\n    -- WARLOCK / demonology (copy of destruction @ 70)\n${demonology.join("\n\n")}`,
);

function rogueWeapon(idSuffix, itemId, slot, spec, specConst, rank, instructions, opts = {}) {
  const sourceType = opts.sourceType || "boss_drop";
  const lines = [
    `    {`,
    `        id = "level70_rogue_${spec}_${idSuffix}",`,
    `        itemId = ${itemId},`,
    `        slot = "${slot}",`,
    `        minLevel = LEVEL70_MIN,`,
    `        maxLevel = LEVEL70_MAX,`,
    `        classes = ROGUE,`,
    `        specs = ${specConst},`,
    `        curatedRank = ${rank},`,
    `        sourceType = "${sourceType}",`,
    `        instructions = "${instructions}",`,
  ];
  if (opts.zone) lines.push(`        zone = "${opts.zone}",`);
  if (opts.npc) lines.push(`        npc = "${opts.npc}",`);
  lines.push(`    },`);
  return lines.join("\n");
}

const MH_DAGGERS = [
  [
    "main_hand_shard_of_azzinoth",
    32471,
    "Farm Illidan Stormrage in Black Temple for Shard of Azzinoth.",
    { zone: "Black Temple", npc: "Illidan Stormrage" },
  ],
  [
    "main_hand_vengeful_gladiator_s_shanker",
    33754,
    "Purchase Vengeful Gladiator's Shanker with arena points from the PvP vendor in Shattrath (Season 3).",
    { sourceType: "vendor", zone: "Shattrath City", npc: "Meminnie" },
  ],
  [
    "main_hand_blade_of_serration",
    34894,
    "Farm Kalecgos in Sunwell Plateau for Blade of Serration.",
    { zone: "Sunwell Plateau", npc: "Kalecgos" },
  ],
];

const OH_ASSASSINATION = [
  [
    "offhand_the_mutilator",
    34952,
    "Farm Lady Sacrolash in Sunwell Plateau for The Mutilator.",
    { zone: "Sunwell Plateau", npc: "Lady Sacrolash" },
  ],
  [
    "offhand_swift_blade_of_uncertainty",
    34949,
    "Farm Entropius in Sunwell Plateau for Swift Blade of Uncertainty.",
    { zone: "Sunwell Plateau", npc: "Entropius" },
  ],
  [
    "offhand_vengeful_gladiator_s_shiv",
    33756,
    "Purchase Vengeful Gladiator's Shiv with arena points from the PvP vendor in Shattrath (Season 3).",
    { sourceType: "vendor", zone: "Shattrath City", npc: "Meminnie" },
  ],
];

function buildRogueSpec(spec, specConst, replaceOffHand) {
  const skipSlot = (block) => {
    if (/slot = "MainHand"/.test(block)) return true;
    if (replaceOffHand && /slot = "SecondaryHand"/.test(block)) return true;
    return false;
  };

  const body = combat.filter((b) => !skipSlot(b)).map((b) => cloneBlock(b, "combat", spec, specConst));

  const mh = MH_DAGGERS.map(([suffix, itemId, instr, opts], i) =>
    rogueWeapon(suffix, itemId, "MainHand", spec, specConst, i + 1, instr, opts),
  );

  const parts = [...body];
  const rangedIdx = parts.findIndex((b) => /slot = "Ranged"/.test(b));
  const insertAt = rangedIdx >= 0 ? rangedIdx : parts.length;
  parts.splice(insertAt, 0, ...mh);

  if (replaceOffHand) {
    const oh = OH_ASSASSINATION.map(([suffix, itemId, instr, opts], i) =>
      rogueWeapon(suffix, itemId, "SecondaryHand", spec, specConst, i + 1, instr, opts),
    );
    parts.splice(insertAt + mh.length, 0, ...oh);
  }

  return parts.join("\n\n");
}

const assassination = buildRogueSpec("assassination", SPEC_CONST.assassination, true);
const subtlety = buildRogueSpec("subtlety", SPEC_CONST.subtlety, false);

insertBefore(
  "    -- HUNTER / beast_mastery (AtlasLoot HunterBM_P3)",
  `    -- ROGUE / assassination (combat armour + dagger weapons @ 70)\n${assassination}\n\n    -- ROGUE / subtlety (combat armour + dagger main hand @ 70)\n${subtlety}`,
);

fs.writeFileSync(dataPath, text);

const curated = (text.match(/^\s+id = /gm) || []).length;
console.log(`Done. Curated entries: ${curated}`);
console.log(`  discipline: ${discipline.length}`);
console.log(`  frost: ${frost.length}`);
console.log(`  affliction: ${affliction.length}`);
console.log(`  demonology: ${demonology.length}`);
console.log(`  assassination: ${combat.length - 6 + 6} (combat base minus swords + dagger weapons)`);
console.log(`  subtlety: ${combat.length - 3 + 3} (combat base minus MH swords + dagger MH)`);
