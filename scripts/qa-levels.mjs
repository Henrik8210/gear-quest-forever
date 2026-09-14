import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const text = fs.readFileSync(
  path.join(__dirname, "..", "GearQuest", "Data.lua"),
  "utf8"
);

const consts = {};
for (const m of text.matchAll(
  /local (LEVEL\d+_(?:MIN|MAX)|EARLY4_MAX|EARLY_MIN|EARLY_MAX) = (\d+)/g
)) {
  consts[m[1]] = Number(m[2]);
}

function resolve(val) {
  val = val.trim();
  if (/^\d+$/.test(val)) return Number(val);
  return consts[val] ?? val;
}

const entryRe =
  /\{\s*\n\s*id = "([^"]+)",\s*\n\s*itemId = (\d+),\s*\n\s*slot = "([^"]+)",\s*\n\s*minLevel = ([^,]+),\s*\n\s*maxLevel = ([^,]+),/g;

const entries = [];
for (const m of text.matchAll(entryRe)) {
  const start = m.index;
  let depth = 0;
  let end = start;
  for (let i = start; i < text.length; i++) {
    if (text[i] === "{") depth++;
    else if (text[i] === "}") {
      depth--;
      if (depth === 0) {
        end = i + 1;
        break;
      }
    }
  }
  const block = text.slice(start, end);
  const e = {
    id: m[1],
    itemId: Number(m[2]),
    slot: m[3],
    minLevel: resolve(m[4]),
    maxLevel: resolve(m[5]),
  };
  for (const field of [
    "classes",
    "factions",
    "curatedRank",
    "sourceType",
    "zone",
    "npc",
    "questName",
    "profession",
    "specs",
    "instructions",
  ]) {
    const fm = block.match(new RegExp(`${field} = ([^\\n]+)`));
    if (fm) e[field] = fm[1].trim().replace(/,$/, "");
  }
  entries.push(e);
}

console.log(`Parsed ${entries.length} entries`);

function selectBand(playerLevel) {
  let best = null;
  for (const e of entries) {
    const mn = e.minLevel;
    const mx = e.maxLevel;
    if (typeof mn !== "number" || typeof mx !== "number") continue;
    if (playerLevel >= mn && playerLevel <= mx) {
      if (
        !best ||
        mn > best[0] ||
        (mn === best[0] && mx < best[1])
      ) {
        best = [mn, mx];
      }
    }
  }
  if (!best) {
    for (const e of entries) {
      const mn = e.minLevel;
      if (typeof mn !== "number") continue;
      if (playerLevel >= mn) {
        if (!best || mn > best[0]) best = [mn, null];
      }
    }
  }
  return best;
}

const BODY_SLOTS = [
  "Back",
  "Chest",
  "Wrist",
  "MainHand",
  "SecondaryHand",
  "Feet",
  "Legs",
  "Waist",
  "Hands",
];

const HORDE_ZONES = new Set([
  "Durotar",
  "Tirisfal Glades",
  "Mulgore",
  "Eversong Woods",
  "Ghostlands",
  "Silvermoon City",
  "Undercity",
  "Orgrimmar",
  "Thunder Bluff",
]);

const HORDE_NPCS = new Set(["Faraden Thelryn"]);

const issues = [];

function stripQuotes(s) {
  return (s || "").replace(/^"|"$/g, "");
}

function isMailMelee(e) {
  const c = e.classes || "";
  return (
    c.includes("WARRIOR") ||
    c.includes("PALADIN") ||
    c.includes("ALLIANCE_MAIL") ||
    c.includes("MAIL_MELEE")
  );
}

for (let lvl = 1; lvl <= 10; lvl++) {
  const band = selectBand(lvl);
  const active = entries.filter(
    (e) =>
      e.minLevel === band[0] &&
      (band[1] === null || e.maxLevel === band[1]) &&
      isMailMelee(e)
  );
  const bySlot = {};
  for (const e of active) {
    (bySlot[e.slot] ||= []).push(e);
  }

  for (const slot of BODY_SLOTS) {
    const items = bySlot[slot] || [];
    if (items.length !== 3) {
      issues.push(
        `L${lvl} ${slot}: ${items.length} items (band ${JSON.stringify(band)}, expected 3)`
      );
    }
    const ranks = items
      .map((i) => Number(stripQuotes(i.curatedRank)))
      .filter(Boolean)
      .sort((a, b) => a - b);
    if (items.length && JSON.stringify(ranks) !== "[1,2,3]") {
      issues.push(`L${lvl} ${slot}: ranks ${JSON.stringify(ranks)}`);
    }
    for (const i of items) {
      const zone = stripQuotes(i.zone);
      const npc = stripQuotes(i.npc);
      const st = stripQuotes(i.sourceType);
      if (i.factions && !i.factions.includes("Alliance")) {
        issues.push(`L${lvl} ${i.id}: missing Alliance faction tag`);
      }
      if (HORDE_ZONES.has(zone)) {
        let tag = "HORDE_ZONE";
        if (st === "vendor") tag = "HORDE_VENDOR_ZONE";
        if (st === "quest_reward") tag = "HORDE_QUEST_ZONE";
        issues.push(
          `${tag} L${lvl} rank${stripQuotes(i.curatedRank)} ${i.id} item=${i.itemId} zone=${zone} npc=${npc || "-"} type=${st}`
        );
      }
      if (HORDE_NPCS.has(npc)) {
        issues.push(
          `HORDE_NPC L${lvl} ${i.id} item=${i.itemId} vendor=${npc}`
        );
      }
      if (st === "boss_drop" && (npc || "").includes("Grik")) {
        issues.push(`MISLABEL L${lvl} ${i.id}: boss_drop for Grik'nir`);
      }
    }
  }
}

for (const e of entries.filter(isMailMelee)) {
  const inst = stripQuotes(e.instructions);
  if (inst.includes("Sunstrider Isle") && stripQuotes(e.npc) === "Proenitus") {
    issues.push(
      `QUEST_TEXT ${e.id}: mentions Sunstrider Isle but Proenitus is Azuremyst (Draenei)`
    );
  }
}

console.log("\n=== Active band per level (mail melee slots) ===");
for (let lvl = 1; lvl <= 10; lvl++) {
  const band = selectBand(lvl);
  const active = entries.filter(
    (e) =>
      e.minLevel === band[0] &&
      (band[1] === null || e.maxLevel === band[1]) &&
      isMailMelee(e)
  );
  const slots = {};
  for (const e of active) slots[e.slot] = (slots[e.slot] || 0) + 1;
  console.log(`  L${lvl}: band ${JSON.stringify(band)} ->`, slots);
}

console.log(`\n=== ISSUES (${issues.length}) ===`);
[...new Set(issues)].sort().forEach((i) => console.log(i));

// ... existing code at end before final console logs - add coverage section
console.log("\n=== Full slot coverage L1-10 (incl. Back alliance-wide) ===");
for (let lvl = 1; lvl <= 10; lvl++) {
  const band = selectBand(lvl);
  const active = entries.filter(
    (e) =>
      e.minLevel === band[0] &&
      (band[1] === null || e.maxLevel === band[1])
  );
  const bySlot = {};
  for (const e of active) {
    const isBack = e.slot === "Back";
    const mail = isMailMelee(e);
    const allyWide = isBack && stripQuotes(e.factions) === "ALLIANCE" && !e.classes;
    if (mail || allyWide || e.slot === "Head") {
      (bySlot[e.slot] ||= []).push(e);
    }
  }
  const parts = [];
  for (const slot of [...BODY_SLOTS, "Shoulder", "Finger", "Head"]) {
    const n = (bySlot[slot] || []).length;
    if (n) parts.push(`${slot}:${n}`);
  }
  console.log(`  L${lvl} band ${JSON.stringify(band)} -> ${parts.join(", ")}`);
}

const LEATHER_ITEMS = new Set([6085, 2018]); // Footman Tunic, Soft Leather Tunic - known leather
for (const e of entries.filter(isMailMelee)) {
  if (LEATHER_ITEMS.has(e.itemId)) {
    issues.push(`NON_MAIL ${e.id} item=${e.itemId} slot=${e.slot} (leather in mail list)`);
  }
}

const BOSS_DROPS = entries.filter(
  (e) => isMailMelee(e) && stripQuotes(e.sourceType) === "boss_drop"
);
console.log("\n=== boss_drop entries (verify rare vs quest mob) ===");
for (const e of BOSS_DROPS) {
  console.log(`  ${e.id} item=${e.itemId} npc=${stripQuotes(e.npc || "-")} zone=${stripQuotes(e.zone || "-")}`);
}
const seen = new Set();
for (let lvl = 1; lvl <= 10; lvl++) {
  const band = selectBand(lvl);
  for (const e of entries) {
    if (e.minLevel !== band[0] || (band[1] !== null && e.maxLevel !== band[1]))
      continue;
    if (stripQuotes(e.sourceType) !== "vendor" || !isMailMelee(e)) continue;
    const key = `${e.itemId}|${stripQuotes(e.npc)}`;
    if (seen.has(key)) continue;
    seen.add(key);
    console.log(
      `  item=${e.itemId} npc=${stripQuotes(e.npc)} zone=${stripQuotes(e.zone)} id=${e.id}`
    );
  }
}
