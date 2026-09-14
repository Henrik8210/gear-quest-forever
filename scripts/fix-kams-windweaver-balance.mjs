import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const KAMS = 2280;
const WIND = 7757;
const WIND_SCORE = 17.5;
const KAMS_SCORE = 10.9;
const file = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  "..",
  "GearQuest",
  "_generated",
  "Data.Druid.generated.lua",
);

const PICK_RE =
  /^\s*\{(\d+),"MainHand",(\d+),(\d+),(\d+),"balance","(Alliance|Horde)",([\d.]+)([^}]*)\},?\s*$/;

function bandKey(minL, maxL, faction) {
  return `${faction}:${minL}:${maxL}`;
}

function formatRow(r) {
  return `    {${r.itemId},"MainHand",${r.minL},${r.maxL},${r.rank},"balance","${r.faction}",${r.score}${r.extra}},`;
}

let text = fs.readFileSync(file, "utf8");
const start = text.indexOf("GQ.Data.druidPicks = {");
const end = text.indexOf("\n}", start);
const pickLines = text.slice(start, end).split("\n");

const parsed = [];
for (const line of pickLines) {
  const m = line.match(PICK_RE);
  parsed.push(m ? { line, row: {
    itemId: +m[1], minL: +m[2], maxL: +m[3], rank: +m[4],
    faction: m[5], score: +m[6], extra: m[7] || "",
  }} : { line, row: null });
}

const groups = new Map();
for (const p of parsed) {
  if (!p.row) continue;
  const k = bandKey(p.row.minL, p.row.maxL, p.row.faction);
  if (!groups.has(k)) groups.set(k, []);
  groups.get(k).push(p.row);
}

const rebuilt = new Map();
let fixed = 0;

for (const [k, band] of groups) {
  if (band[0].minL < 32) continue;
  const hasKams = band.some((r) => r.itemId === KAMS);
  const hasWind = band.some((r) => r.itemId === WIND);
  if (!hasKams && !hasWind) continue;

  let items = band.filter((r) => r.itemId !== KAMS && r.itemId !== WIND);
  items.push({
    itemId: WIND,
    minL: band[0].minL,
    maxL: band[0].maxL,
    faction: band[0].faction,
    score: WIND_SCORE,
    extra: band.find((r) => r.itemId === WIND)?.extra || "",
    rank: 0,
  });
  items.push({
    itemId: KAMS,
    minL: band[0].minL,
    maxL: band[0].maxL,
    faction: band[0].faction,
    score: KAMS_SCORE,
    extra: band.find((r) => r.itemId === KAMS)?.extra || "",
    rank: 0,
  });

  items.sort((a, b) => {
    if (a.itemId === WIND) return -1;
    if (b.itemId === WIND) return 1;
    if (a.itemId === KAMS) return -1;
    if (b.itemId === KAMS) return 1;
    return b.score - a.score || a.itemId - b.itemId;
  });

  items = items.slice(0, 3).map((r, i) => ({
    ...r,
    rank: i + 1,
    score: r.itemId === WIND ? WIND_SCORE : r.itemId === KAMS ? KAMS_SCORE : r.score,
  }));

  rebuilt.set(k, items);
  fixed++;
}

const out = [];
const emitted = new Set();

for (const p of parsed) {
  if (!p.row) {
    out.push(p.line);
    continue;
  }
  const k = bandKey(p.row.minL, p.row.maxL, p.row.faction);
  if (rebuilt.has(k)) {
    if (emitted.has(k)) continue;
    emitted.add(k);
    for (const r of rebuilt.get(k)) out.push(formatRow(r));
  } else {
    out.push(p.line);
  }
}

text = text.slice(0, start) + out.join("\n") + text.slice(end);
fs.writeFileSync(file, text);
console.log(`Fixed ${fixed} balance MainHand band(s) at level 32+: Windweaver ranks above Kam's`);
