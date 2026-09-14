/**
 * Replace the level-70 band in Data.lua with scripts/output/p3-bis-import.lua
 * Run after: node scripts/import-atlasloot-p3-bis.mjs
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const dataPath = path.join(__dirname, "../GearQuest/Data.lua");
const p3LuaPath = path.join(__dirname, "output/p3-bis-import.lua");

const CLASS_SPEC_CONSTANTS = `-- Level 70 class / spec filters (Phase 3 BT/Hyjal)
local ROGUE = { ROGUE = true }
local HUNTER = { HUNTER = true }
local DRUID = { DRUID = true }
local MAGE = { MAGE = true }
local PALADIN = { PALADIN = true }
local PRIEST = { PRIEST = true }
local SHAMAN = { SHAMAN = true }
local WARLOCK = { WARLOCK = true }
local WARRIOR = { WARRIOR = true }
local SPEC_COMBAT = { combat = true }
local SPEC_BEAST_MASTERY = { beast_mastery = true }
local SPEC_SURVIVAL = { survival = true }
local SPEC_BALANCE = { balance = true }
local SPEC_BEAR = { bear = true }
local SPEC_FERAL = { feral = true }
local SPEC_RESTORATION = { restoration = true }
local SPEC_ARCANE = { arcane = true }
local SPEC_FIRE = { fire = true }
local SPEC_HOLY = { holy = true }
local SPEC_PROTECTION = { protection = true }
local SPEC_RETRIBUTION = { retribution = true }
local SPEC_SHADOW = { shadow = true }
local SPEC_ELEMENTAL = { elemental = true }
local SPEC_ENHANCEMENT = { enhancement = true }
local SPEC_DESTRUCTION = { destruction = true }
local SPEC_ARMS = { arms = true }
local SPEC_FURY = { fury = true }
`;

// Replace level-70-only class/spec constants (keep leveling SPEC_* tables)
const OLD_LEVEL70_CONSTS =
  /local SHAMAN = \{ SHAMAN = true \}\r?\nlocal SPEC_ELEMENTAL = \{ elemental = true \}\r?\nlocal ROGUE = \{ ROGUE = true \}\r?\nlocal SPEC_COMBAT = \{ combat = true \}/;
const NEW_LEVEL70_CONSTS = CLASS_SPEC_CONSTANTS.trimEnd();

let data = fs.readFileSync(dataPath, "utf8");
const p3Block = fs.readFileSync(p3LuaPath, "utf8");

if (!data.includes("LEVEL70_MIN = 70")) {
  console.error("LEVEL70_MIN not found in Data.lua");
  process.exit(1);
}

if (OLD_LEVEL70_CONSTS.test(data)) {
  data = data.replace(OLD_LEVEL70_CONSTS, NEW_LEVEL70_CONSTS);
} else if (!data.includes("local SPEC_BEAR")) {
  data = data.replace(
    /(local LEVEL70_MAX = 70\r?\n)/,
    `$1${NEW_LEVEL70_CONSTS}\n`
  );
}

// Drop stale per-class constants that sat between level-70 block and MAIL_MELEE
data = data.replace(
  /\r?\nlocal SHAMAN = \{ SHAMAN = true \}\r?\nlocal SPEC_MELEE/,
  "\nlocal SPEC_MELEE"
);
data = data.replace(
  /\r?\nlocal SPEC_PROT = \{ protection = true \}\r?\nlocal SPEC_HOLY = \{ holy = true \}\r?\nlocal SPEC_PROT = \{ protection = true \}\r?\nlocal SPEC_ELEMENTAL = \{ elemental = true \}\r?\nlocal ROGUE = \{ ROGUE = true \}\r?\nlocal SPEC_COMBAT = \{ combat = true \}/,
  "\nlocal SPEC_PROT = { protection = true }"
);

const startRe = /\r?\n    -- Level 70 band/;
const endRe = /\r?\n\r?\nlocal SLOT_TO_INVENTORY = \{/;
const startMatch = data.match(startRe);
const endMatch = data.match(endRe);
if (!startMatch || !endMatch) {
  console.error("Could not find level-70 band boundaries in Data.lua");
  process.exit(1);
}

const startIdx = startMatch.index;
const endIdx = endMatch.index;

data =
  data.slice(0, startIdx) +
  "\n\n" +
  p3Block.trimEnd() +
  "\n}" +
  data.slice(endIdx);

// CLASS_RANGED — all ranged-slot classes at 70
const rangedBlock = `GQ.Data.CLASS_RANGED = {
    ROGUE = true,
    HUNTER = true,
    MAGE = true,
    PRIEST = true,
    WARLOCK = true,
    SHAMAN = true,
}`;
data = data.replace(/GQ\.Data\.CLASS_RANGED = \{[\s\S]*?\}/, rangedBlock);

fs.writeFileSync(dataPath, data);
console.log("Replaced level-70 band in Data.lua with", p3LuaPath);
