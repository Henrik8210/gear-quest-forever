/**
 * One-off: remove TBC level-70 curated band from GearQuest/Data.lua (Forever scope).
 * Run: node scripts/strip-level70-curated.mjs
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const dataPath = path.join(__dirname, "..", "GearQuest", "Data.lua");

let text = fs.readFileSync(dataPath, "utf8");

const marker = "\n    -- Level 70 band";
const start = text.indexOf(marker);
if (start < 0) {
  console.error("Level 70 band marker not found");
  process.exit(1);
}

const endMarker = "\n}\n\nlocal SLOT_TO_INVENTORY";
const end = text.indexOf(endMarker);
if (end < 0) {
  console.error("entries table end not found");
  process.exit(1);
}

const before = text.slice(0, start).replace(/\n\n$/, "\n");
const after = text.slice(end);
text = before + after;

const strips = [
  /local LEVEL70_MIN = 70\r?\nlocal LEVEL70_MAX = 70\r?\n-- Level 70 class \/ spec filters \(Phase 3 BT\/Hyjal\)\r?\n/,
  /local ROGUE = \{ ROGUE = true \}\r?\nlocal HUNTER = \{ HUNTER = true \}\r?\nlocal DRUID = \{ DRUID = true \}\r?\nlocal MAGE = \{ MAGE = true \}\r?\nlocal PALADIN = \{ PALADIN = true \}\r?\nlocal PRIEST = \{ PRIEST = true \}\r?\nlocal SHAMAN = \{ SHAMAN = true \}\r?\nlocal WARLOCK = \{ WARLOCK = true \}\r?\nlocal WARRIOR = \{ WARRIOR = true \}\r?\n/,
  /local SPEC_COMBAT = \{ combat = true \}\r?\nlocal SPEC_ASSASSINATION = \{ assassination = true \}\r?\nlocal SPEC_SUBTLETY = \{ subtlety = true \}\r?\nlocal SPEC_BEAST_MASTERY = \{ beast_mastery = true \}\r?\nlocal SPEC_MARKSMANSHIP = \{ marksmanship = true \}\r?\nlocal SPEC_SURVIVAL = \{ survival = true \}\r?\nlocal SPEC_BALANCE = \{ balance = true \}\r?\nlocal SPEC_BEAR = \{ bear = true \}\r?\nlocal SPEC_FERAL = \{ feral = true \}\r?\nlocal SPEC_RESTORATION = \{ restoration = true \}\r?\nlocal SPEC_ARCANE = \{ arcane = true \}\r?\nlocal SPEC_FIRE = \{ fire = true \}\r?\nlocal SPEC_FROST = \{ frost = true \}\r?\n/,
  /local SPEC_DISCIPLINE = \{ discipline = true \}\r?\n/,
  /local SPEC_ELEMENTAL = \{ elemental = true \}\r?\nlocal SPEC_ENHANCEMENT = \{ enhancement = true \}\r?\nlocal SPEC_DESTRUCTION = \{ destruction = true \}\r?\nlocal SPEC_AFFLICTION = \{ affliction = true \}\r?\nlocal SPEC_DEMONOLOGY = \{ demonology = true \}\r?\nlocal SPEC_ARMS = \{ arms = true \}\r?\nlocal SPEC_FURY = \{ fury = true \}\r?\n/,
];

for (const re of strips) {
  text = text.replace(re, "");
}

fs.writeFileSync(dataPath, text);

const l70 = (text.match(/level70_/g) || []).length;
const ids = (text.match(/^\s+id = /gm) || []).length;
console.log(`Updated ${dataPath}`);
console.log(`Remaining level70_ refs: ${l70}, curated id = lines: ${ids}`);
