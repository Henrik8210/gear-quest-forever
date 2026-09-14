import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "..", "GearQuest");

function read(name) {
  return fs.readFileSync(path.join(root, name), "utf8");
}

function countTableRows(text, tableName) {
  const body = extractTableBody(text, tableName);
  if (!body) return 0;
  return (body.match(/^\s*\{/gm) || []).length;
}

function extractTableBody(text, tableName) {
  const m = text.match(new RegExp(`GQ\\.Data\\.${tableName} = \\{([\\s\\S]*?)\\n\\}(?=\\s*(?:\\n|$|--|GQ\\.Data\\.))`));
  return m?.[1] ?? "";
}

const SOURCES = [
  {
    class: "PALADIN",
    picks: "paladinPicks",
    facts: "itemFacts",
    hasSpec: true,
    file: "_generated/Data.Paladin.generated.lua",
  },
  {
    class: "PALADIN",
    picks: "paladinHorde1to9",
    facts: "paladinHorde1to9Facts",
    hasSpec: false,
    faction: "Horde",
    file: "_generated/Data.Paladin.Horde.1to9.generated.lua",
  },
  {
    class: "WARRIOR",
    picks: "warriorPicks",
    facts: "warriorItemFacts",
    hasSpec: true,
    file: "_generated/Data.Warrior.generated.lua",
  },
  {
    class: "WARRIOR",
    picks: "warriorHorde1to9",
    facts: "warriorHorde1to9Facts",
    hasSpec: false,
    faction: "Horde",
    file: "_generated/Data.Warrior.Horde.1to9.generated.lua",
  },
  {
    class: "HUNTER",
    picks: "hunterPicks",
    facts: "hunterItemFacts",
    hasSpec: true,
    file: "_generated/Data.Hunter.generated.lua",
  },
  {
    class: "HUNTER",
    picks: "hunterEarly1to9",
    facts: "hunterEarly1to9Facts",
    hasSpec: false,
    factionInRow: true,
    file: "_generated/Data.Hunter.Early.1to9.generated.lua",
  },
  {
    class: "DRUID",
    picks: "druidPicks",
    facts: "druidItemFacts",
    hasSpec: true,
    file: "_generated/Data.Druid.generated.lua",
  },
  {
    class: "DRUID",
    picks: "druidEarly1to9",
    facts: "druidEarly1to9Facts",
    hasSpec: false,
    factionInRow: true,
    file: "_generated/Data.Druid.Early.1to9.generated.lua",
  },
  {
    class: "SHAMAN",
    picks: "shamanPicks",
    facts: "shamanItemFacts",
    hasSpec: true,
    file: "_generated/Data.Shaman.generated.lua",
  },
  {
    class: "SHAMAN",
    picks: "shamanEarly1to9",
    facts: "shamanEarly1to9Facts",
    hasSpec: false,
    factionInRow: true,
    file: "_generated/Data.Shaman.Early.1to9.generated.lua",
  },
  {
    class: "ROGUE",
    picks: "roguePicks",
    facts: "rogueItemFacts",
    hasSpec: true,
    file: "_generated/Data.Rogue.generated.lua",
  },
  {
    class: "ROGUE",
    picks: "rogueEarly1to9",
    facts: "rogueEarly1to9Facts",
    hasSpec: false,
    factionInRow: true,
    file: "_generated/Data.Rogue.Early.1to9.generated.lua",
  },
  {
    class: "PRIEST",
    picks: "priestPicks",
    facts: "priestItemFacts",
    hasSpec: true,
    file: "_generated/Data.Priest.generated.lua",
  },
  {
    class: "PRIEST",
    picks: "priestEarly1to9",
    facts: "priestEarly1to9Facts",
    hasSpec: false,
    factionInRow: true,
    file: "_generated/Data.Priest.Early.1to9.generated.lua",
  },
  {
    class: "WARLOCK",
    picks: "warlockPicks",
    facts: "warlockItemFacts",
    hasSpec: true,
    file: "_generated/Data.Warlock.generated.lua",
  },
  {
    class: "WARLOCK",
    picks: "warlockEarly1to9",
    facts: "warlockEarly1to9Facts",
    hasSpec: false,
    factionInRow: true,
    file: "_generated/Data.Warlock.Early.1to9.generated.lua",
  },
  {
    class: "MAGE",
    picks: "magePicks",
    facts: "mageItemFacts",
    hasSpec: true,
    file: "_generated/Data.Mage.generated.lua",
  },
  {
    class: "MAGE",
    picks: "mageEarly1to9",
    facts: "mageEarly1to9Facts",
    hasSpec: false,
    factionInRow: true,
    file: "_generated/Data.Mage.Early.1to9.generated.lua",
  },
];

const TARGET_TOTAL = 68520;
const TARGET_GENERATED = 67033;
const TARGET_CURATED = TARGET_TOTAL - TARGET_GENERATED;

const dataLua = read("Data.lua");
const curated = (dataLua.match(/^\s+id = /gm) || []).length;

let generated = 0;
const ids = new Map();

for (const src of SOURCES) {
  const text = read(src.file);
  const picks = countTableRows(text, src.picks);
  generated += picks;
  console.log(`${src.picks}: ${picks}`);

  const factsBody = extractTableBody(text, src.facts);
  const factIds = new Set([...factsBody.matchAll(/\[(\d+)\]=/g)].map((m) => m[1]));
  const picksBody = extractTableBody(text, src.picks);
  const prefix = `gen:${src.class.toLowerCase()}:`;

  for (const line of picksBody.match(/^\s*\{[^}]+\},?/gm) || []) {
    const m = line.match(
      /\{(\d+),"([^"]+)",(\d+),(\d+),(\d+)(?:,"([^"]+)")?(?:,"([^"]+)")?/,
    );
    if (!m) continue;
    const [, itemId, slot, minLevel, , , spec, faction] = m;
    if (!factIds.has(itemId)) continue;
    const specVal = src.hasSpec ? spec ?? "nil" : "nil";
    let factionVal;
    if (src.hasSpec) {
      factionVal = faction ?? "nil";
    } else if (src.factionInRow) {
      const fm = line.match(/faction="([^"]+)"/);
      factionVal = fm?.[1] ?? "nil";
    } else {
      factionVal = src.faction ?? "nil";
    }
    const id = `${prefix}${itemId}:${slot}:${minLevel}:${specVal}:${factionVal}`;
    ids.set(id, (ids.get(id) || 0) + 1);
  }
}

console.log("\n=== Counts ===");
console.log("Curated:", curated);
console.log("Generated:", generated);
console.log("Expected total:", curated + generated);
console.log(`Target total: ${TARGET_TOTAL} (${TARGET_CURATED} curated + ${TARGET_GENERATED} generated)`);

const dupes = [...ids.entries()].filter(([, n]) => n > 1);
console.log("\n=== Duplicate generated ids ===");
console.log(dupes.length === 0 ? "None" : dupes.slice(0, 10));

function countRangedPicks(file, picksName) {
  const body = extractTableBody(read(file), picksName);
  return (body.match(/"Ranged"/g) || []).length;
}

console.log("\n=== Relic (Ranged) slot picks ===");
console.log("paladin:", countRangedPicks("_generated/Data.Paladin.generated.lua", "paladinPicks"));
console.log("druid:", countRangedPicks("_generated/Data.Druid.generated.lua", "druidPicks"));
console.log("shaman:", countRangedPicks("_generated/Data.Shaman.generated.lua", "shamanPicks"));
console.log("priest:", countRangedPicks("_generated/Data.Priest.generated.lua", "priestPicks"));
console.log("warlock:", countRangedPicks("_generated/Data.Warlock.generated.lua", "warlockPicks"));
console.log("mage:", countRangedPicks("_generated/Data.Mage.generated.lua", "magePicks"));

const shamanBody = extractTableBody(read("_generated/Data.Shaman.generated.lua"), "shamanPicks");
const shamanEarlyBody = extractTableBody(
  read("_generated/Data.Shaman.Early.1to9.generated.lua"),
  "shamanEarly1to9",
);

console.log("\n=== Shaman checks ===");
const eleRestoSec = [...shamanBody.matchAll(/\{(\d+),"SecondaryHand",(\d+),(\d+),\d+,"(elemental|restoration)"/g)];
console.log("elemental/restoration SecondaryHand rows (shields + held items):", eleRestoSec.length);

const shamanEarlyRows = shamanEarlyBody.match(/^\s*\{[^}]+\},?/gm) || [];
console.log(
  "shamanEarly1to9 rows missing faction:",
  shamanEarlyRows.filter((line) => !line.includes('faction="')).length,
);

const druidEarlyBody = extractTableBody(
  read("_generated/Data.Druid.Early.1to9.generated.lua"),
  "druidEarly1to9",
);
const druidEarlyRows = druidEarlyBody.match(/^\s*\{[^}]+\},?/gm) || [];
console.log(
  "druidEarly1to9 rows missing faction:",
  druidEarlyRows.filter((line) => !line.includes('faction="')).length,
);

const priestEarlyBody = extractTableBody(
  read("_generated/Data.Priest.Early.1to9.generated.lua"),
  "priestEarly1to9",
);
const priestEarlyRows = priestEarlyBody.match(/^\s*\{[^}]+\},?/gm) || [];
console.log(
  "priestEarly1to9 rows missing faction:",
  priestEarlyRows.filter((line) => !line.includes('faction="')).length,
);

const warlockEarlyBody = extractTableBody(
  read("_generated/Data.Warlock.Early.1to9.generated.lua"),
  "warlockEarly1to9",
);
const warlockEarlyRows = warlockEarlyBody.match(/^\s*\{[^}]+\},?/gm) || [];
console.log(
  "warlockEarly1to9 rows missing faction:",
  warlockEarlyRows.filter((line) => !line.includes('faction="')).length,
);

const mageEarlyBody = extractTableBody(
  read("_generated/Data.Mage.Early.1to9.generated.lua"),
  "mageEarly1to9",
);
const mageEarlyRows = mageEarlyBody.match(/^\s*\{[^}]+\},?/gm) || [];
console.log(
  "mageEarly1to9 rows missing faction:",
  mageEarlyRows.filter((line) => !line.includes('faction="')).length,
);

let maxLevel = 0;
let badBands = 0;
for (const src of SOURCES) {
  const picksBody = extractTableBody(read(src.file), src.picks);
  for (const m of picksBody.matchAll(/\{(\d+),"([^"]+)",(\d+),(\d+),/g)) {
    const minL = +m[3];
    const maxL = +m[4];
    maxLevel = Math.max(maxLevel, minL, maxL);
    if (minL > maxL) badBands++;
  }
}
console.log("\n=== Bounds ===");
console.log("Max level in generated picks:", maxLevel);
console.log("minLevel > maxLevel rows:", badBands);

let exitCode = 0;
if (curated + generated !== TARGET_TOTAL) {
  console.error("\nFAIL: total entry count mismatch");
  exitCode = 1;
}
if (dupes.length > 0) {
  console.error("\nFAIL: duplicate generated ids");
  exitCode = 1;
}
if (maxLevel > 69) {
  console.error("\nFAIL: generated picks exceed level 69");
  exitCode = 1;
}
if (druidEarlyRows.filter((line) => !line.includes('faction="')).length > 0) {
  console.error("\nFAIL: druid early rows missing faction");
  exitCode = 1;
}
if (shamanEarlyRows.filter((line) => !line.includes('faction="')).length > 0) {
  console.error("\nFAIL: shaman early rows missing faction");
  exitCode = 1;
}
if (priestEarlyRows.filter((line) => !line.includes('faction="')).length > 0) {
  console.error("\nFAIL: priest early rows missing faction");
  exitCode = 1;
}
if (warlockEarlyRows.filter((line) => !line.includes('faction="')).length > 0) {
  console.error("\nFAIL: warlock early rows missing faction");
  exitCode = 1;
}
if (mageEarlyRows.filter((line) => !line.includes('faction="')).length > 0) {
  console.error("\nFAIL: mage early rows missing faction");
  exitCode = 1;
}
if (countRangedPicks("_generated/Data.Shaman.generated.lua", "shamanPicks") === 0) {
  console.error("\nFAIL: shaman relic slot empty");
  exitCode = 1;
}
if (countRangedPicks("_generated/Data.Priest.generated.lua", "priestPicks") === 0) {
  console.error("\nFAIL: priest wand slot empty");
  exitCode = 1;
}
if (countRangedPicks("_generated/Data.Warlock.generated.lua", "warlockPicks") === 0) {
  console.error("\nFAIL: warlock wand slot empty");
  exitCode = 1;
}
if (countRangedPicks("_generated/Data.Mage.generated.lua", "magePicks") === 0) {
  console.error("\nFAIL: mage wand slot empty");
  exitCode = 1;
}

const paladinBody = extractTableBody(read("_generated/Data.Paladin.generated.lua"), "paladinPicks");
const sash6570Holy = paladinBody.match(/\{6570,"Waist",17,17,3,"holy"[^}]+\}/);
console.log("\n=== Suffix id spot checks ===");
if (!sash6570Holy || !sash6570Holy[0].includes("suffixId=2032")) {
  console.error("FAIL: item 6570 holy level 17 must carry suffixId=2032");
  exitCode = 1;
} else {
  console.log("6570 holy @17: suffixId=2032 ok");
}

const rogueBody = extractTableBody(read("_generated/Data.Rogue.generated.lua"), "roguePicks");
const cap7413 = rogueBody.match(/\{7413,"Head",28,28,3,"combat","Alliance"[^}]+\}/);
if (!cap7413 || !cap7413[0].includes("suffixId=690")) {
  console.error("FAIL: item 7413 combat @28 must carry suffixId=690 (not family max 753)");
  exitCode = 1;
} else if (!cap7413[0].includes('suffixRange="+7-8 Agility, +7-8 Strength"')) {
  console.error("FAIL: item 7413 missing expected suffixRange");
  exitCode = 1;
} else {
  console.log("7413 combat @28: suffixId=690 ok");
}

let suffixRows = 0;
let withSuffixId = 0;
for (const src of SOURCES) {
  const text = read(src.file);
  for (const row of text.matchAll(/\{[^}]+\},?/g)) {
    if (!/suffix=/.test(row[0])) continue;
    suffixRows++;
    if (/suffixId=/.test(row[0])) withSuffixId++;
  }
}
const notableTables = ["paladinNotable", "warriorNotable", "hunterNotable", "druidNotable", "shamanNotable", "rogueNotable", "priestNotable", "warlockNotable", "mageNotable"];
for (const tableName of notableTables) {
  for (const file of fs.readdirSync(path.join(root, "_generated")).filter((f) => f.endsWith(".generated.lua"))) {
    const body = extractTableBody(read("_generated/" + file), tableName);
    if (!body) continue;
    for (const row of body.matchAll(/\{[^}]+\},?/g)) {
      if (!/suffix=/.test(row[0])) continue;
      suffixRows++;
      if (/suffixId=/.test(row[0])) withSuffixId++;
    }
  }
}
console.log(`\n=== Suffix id coverage ===`);
console.log(`Rows with suffix: ${suffixRows}, carrying suffixId: ${withSuffixId} (${((100 * withSuffixId) / suffixRows).toFixed(1)}%)`);
if (withSuffixId / suffixRows < 0.95) {
  console.error("WARN: suffixId coverage below 95% — import latest generated bundle");
}

const druidText = read("_generated/Data.Druid.generated.lua");
const bandit9775 = druidText.match(/\{9775,"Waist",14,14[^}]*suffix="of Healing"[^}]+\}/);
if (bandit9775 && !bandit9775[0].includes("suffixId=2031")) {
  console.error("FAIL: Bandit Cinch 9775 @14 must carry suffixId=2031");
  exitCode = 1;
} else if (bandit9775) {
  console.log("9775 @14: suffixId=2031 ok");
}

process.exit(exitCode);
