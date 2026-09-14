import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const CROWD_PUMMELER = 9449;
const CASTER_SPECS = new Set(["balance", "restoration"]);
const file = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  "..",
  "GearQuest",
  "_generated",
  "Data.Druid.generated.lua",
);

const PICK_RE =
  /^\s*\{(\d+),"([^"]+)",(\d+),(\d+),(\d+),"([^"]+)","([^"]+)",([\d.]+)([^}]*)\},?\s*$/;

function parsePick(line) {
  const m = line.match(PICK_RE);
  if (!m) return null;
  return {
    itemId: +m[1],
    slot: m[2],
    minLevel: +m[3],
    maxLevel: +m[4],
    rank: +m[5],
    spec: m[6],
    faction: m[7],
    score: +m[8],
    extra: m[9] || "",
  };
}

function groupKey(row) {
  return `${row.slot}:${row.spec}:${row.faction}:${row.minLevel}:${row.maxLevel}`;
}

function bandsOverlap(a, b) {
  return a.minLevel <= b.maxLevel && a.maxLevel >= b.minLevel;
}

function formatPick(row) {
  return `    {${row.itemId},"${row.slot}",${row.minLevel},${row.maxLevel},${row.rank},"${row.spec}","${row.faction}",${row.score}${row.extra}},`;
}

let text = fs.readFileSync(file, "utf8");

// --- druidPicks ---
const picksStart = text.indexOf("GQ.Data.druidPicks = {");
const picksEnd = text.indexOf("\n}", picksStart);

const pickLines = text.slice(picksStart, picksEnd).split("\n");
const parsedPicks = pickLines.map(parsePick).filter(Boolean);

const groups = new Map();
for (const row of parsedPicks) {
  const key = groupKey(row);
  if (!groups.has(key)) groups.set(key, []);
  groups.get(key).push(row);
}

const fillPool = parsedPicks.filter(
  (r) =>
    CASTER_SPECS.has(r.spec) &&
    r.itemId !== CROWD_PUMMELER &&
    r.slot === "MainHand",
);

function rebuildBand(bandRows) {
  const band = bandRows[0];
  let items = bandRows
    .filter((r) => r.itemId !== CROWD_PUMMELER)
    .map((r) => ({ ...r }));

  const used = new Set(items.map((r) => r.itemId));
  let filled = 0;
  while (items.length < 3) {
    let best = null;
    for (const cand of fillPool) {
      if (cand.spec !== band.spec || cand.faction !== band.faction) continue;
      if (used.has(cand.itemId)) continue;
      if (
        cand.maxLevel < band.minLevel - 1 ||
        cand.minLevel > band.maxLevel
      )
        continue;
      if (!best || cand.score > best.score) best = cand;
    }
    if (!best) break;
    items.push({
      ...best,
      minLevel: band.minLevel,
      maxLevel: band.maxLevel,
      rank: items.length + 1,
    });
    used.add(best.itemId);
    filled++;
  }

  items.sort((a, b) => b.score - a.score || a.itemId - b.itemId);
  return {
    rows: items.slice(0, 3).map((r, i) => ({
      ...r,
      minLevel: band.minLevel,
      maxLevel: band.maxLevel,
      rank: i + 1,
    })),
    filled,
  };
}

let pickGroupsFixed = 0;
let picksRemoved = 0;
let picksPromoted = 0;
const replacementByGroup = new Map();

// Bands that lost Crowd Pummeler (already stripped) or still have fewer than 3 picks.
for (const [key, bandRows] of groups) {
  const spec = bandRows[0].spec;
  if (!CASTER_SPECS.has(spec) || bandRows[0].slot !== "MainHand") continue;

  const hadPummeler = bandRows.some((r) => r.itemId === CROWD_PUMMELER);
  const without = bandRows.filter((r) => r.itemId !== CROWD_PUMMELER);
  if (!hadPummeler && without.length >= 3) continue;

  const { rows, filled } = rebuildBand(bandRows);
  replacementByGroup.set(key, rows);
  picksPromoted += filled;
  if (hadPummeler) {
    picksRemoved += bandRows.filter((r) => r.itemId === CROWD_PUMMELER).length;
  }
}

pickGroupsFixed = replacementByGroup.size;

const newPickLines = [];
for (const line of pickLines) {
  const row = parsePick(line);
  if (!row) {
    newPickLines.push(line);
    continue;
  }

  const key = groupKey(row);
  if (replacementByGroup.has(key)) {
    if (row.rank !== 1) continue;
    for (const r of replacementByGroup.get(key)) newPickLines.push(formatPick(r));
    continue;
  }

  if (CASTER_SPECS.has(row.spec) && row.itemId === CROWD_PUMMELER) continue;
  newPickLines.push(line);
}

text =
  text.slice(0, picksStart) +
  newPickLines.join("\n") +
  text.slice(picksEnd);

// --- druidNotable ---
const notStart = text.indexOf("GQ.Data.druidNotable = {");
const notEnd = text.indexOf("\n}", notStart);
const notBlock = text.slice(notStart, notEnd);
let notableRemoved = 0;

const newNotLines = notBlock.split("\n").filter((line) => {
  if (!line.includes(`{${CROWD_PUMMELER},`)) return true;
  const isCaster =
    line.includes('"balance"') || line.includes('"restoration"');
  if (isCaster) notableRemoved++;
  return !isCaster;
});

text = text.slice(0, notStart) + newNotLines.join("\n") + text.slice(notEnd);

fs.writeFileSync(file, text);

console.log(`Fixed ${pickGroupsFixed} balance/restoration band(s)`);
console.log(`Removed ${picksRemoved} Crowd Pummeler pick row(s)`);
console.log(`Promoted ${picksPromoted} fill-in pick row(s) to restore top 3`);
console.log(`Removed ${notableRemoved} Crowd Pummeler notable row(s)`);

// Sanity
const after = fs.readFileSync(file, "utf8");
const badPicks = (after.match(/9449.*"(balance|restoration)"/g) || []).length;
const badNot = (
  after.match(/\{9449,[^}]+\("(balance|restoration)"/g) || []
).length;
console.log(`Remaining balance/restoration Crowd Pummeler refs: picks=${badPicks}, notables=${badNot}`);
if (badPicks + badNot > 0) process.exit(1);
