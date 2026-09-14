/**
 * Phase 3 (addon-repo slice): drop TBC-only generated rows and cap bands at 60.
 *
 * Full Classic re-score still needs the external score.py pipeline (not in this
 * repo). This pass keeps TBC ranking among remaining Classic items, remaps
 * ranks 1–3, and prunes unused itemFacts.
 *
 * Usage: node scripts/filter-generated-classic.mjs [--dry-run]
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), "..");
const genDir = path.join(root, "GearQuest", "_generated");
const cachePath = path.join(genDir, "data", "items_random.classic.json");
const outIdsPath = path.join(genDir, "data", "tbc_only_item_ids.json");
const MAX_LEVEL = 60;
const dryRun = process.argv.includes("--dry-run");

/** Outland + TBC instances — any source type. */
const TBC_CONTENT_ZONES = [
  "Hellfire Peninsula",
  "Hellfire Citadel",
  "Hellfire Ramparts",
  "The Blood Furnace",
  "Blood Furnace",
  "Zangarmarsh",
  "Terokkar Forest",
  "Shattrath City",
  "Shattrath",
  "Nagrand",
  "Blade's Edge Mountains",
  "Blade's Edge",
  "Netherstorm",
  "Shadowmoon Valley",
  "Outland",
  "Karazhan",
  "Gruul's Lair",
  "Magtheridon's Lair",
  "Serpentshrine Cavern",
  "Coilfang Reservoir",
  "The Slave Pens",
  "Slave Pens",
  "The Underbog",
  "The Steamvault",
  "Mana-Tombs",
  "Auchenai Crypts",
  "Sethekk Halls",
  "Shadow Labyrinth",
  "Auchindoun",
  "The Shattered Halls",
  "Shattered Halls",
  "The Botanica",
  "The Mechanar",
  "The Arcatraz",
  "Tempest Keep",
  "Black Temple",
  "Hyjal Summit",
  "Mount Hyjal",
  "The Black Morass",
  "Old Hillsbrad Foothills",
  "Caverns of Time",
  "Zul'Aman",
  "Isle of Quel'Danas",
  "Sunwell Plateau",
  "Magisters' Terrace",
  "The Eye of the Storm",
];

/** TBC starting continents — quest/boss only (vendors often list Classic items here). */
const TBC_START_ZONES = [
  "Azuremyst Isle",
  "Bloodmyst Isle",
  "The Exodar",
  "Eversong Woods",
  "Ghostlands",
  "Silvermoon City",
  "Sunstrider Isle",
  "Ammen Vale",
];

function extractTable(text, tableName) {
  const re = new RegExp(
    `GQ\\.Data\\.${tableName} = \\{([\\s\\S]*?)\\n\\}(?=\\s*(?:\\n|$|--|GQ\\.Data\\.))`,
  );
  const m = text.match(re);
  if (!m) return null;
  return { full: m[0], body: m[1], index: m.index };
}

function parseFactZoneAndSource(line) {
  const zone = line.match(/zone="([^"]*)"/)?.[1] || "";
  const sourceType = line.match(/sourceType="([^"]*)"/)?.[1] || "";
  const instructions = line.match(/instructions="([^"]*)"/)?.[1] || "";
  return { zone, sourceType, blob: `${zone} ${instructions}` };
}

function zoneHits(blob, names) {
  const lower = blob.toLowerCase();
  return names.some((z) => lower.includes(z.toLowerCase()));
}

function loadNoClassicPageIds() {
  const ids = new Set();
  if (!fs.existsSync(cachePath)) return ids;
  const cache = JSON.parse(fs.readFileSync(cachePath, "utf8"));
  for (const [id, row] of Object.entries(cache)) {
    if (row.noClassicPage) ids.add(Number(id));
  }
  return ids;
}

function collectTbcIdsFromFacts(text, factsName, noClassicPage) {
  const table = extractTable(text, factsName);
  const tbc = new Set();
  if (!table) return tbc;
  for (const line of table.body.split("\n")) {
    const idM = line.match(/\[(\d+)\]=/);
    if (!idM) continue;
    const id = Number(idM[1]);
    if (noClassicPage.has(id)) {
      tbc.add(id);
      continue;
    }
    const { zone, sourceType, blob } = parseFactZoneAndSource(line);
    if (zoneHits(blob, TBC_CONTENT_ZONES) || zoneHits(zone, TBC_CONTENT_ZONES)) {
      tbc.add(id);
      continue;
    }
    const startHit = zoneHits(zone, TBC_START_ZONES) || zoneHits(blob, TBC_START_ZONES);
    if (startHit && sourceType !== "vendor" && sourceType !== "world_drop") {
      tbc.add(id);
    }
  }
  return tbc;
}

function parsePickLine(line) {
  const m = line.match(/^\s*\{(\d+),"([^"]+)",(\d+),(\d+)(?:,([^,}]+))?(.*)$/);
  if (!m) return null;
  return {
    itemId: Number(m[1]),
    slot: m[2],
    minLevel: Number(m[3]),
    maxLevel: Number(m[4]),
    rest: m[5] ? `,${m[5]}${m[6]}` : m[6],
    raw: line,
    rankField: m[5],
  };
}

function remapRank(line, newRank) {
  return line.replace(/^(\s*\{\d+,"[^"]+",\d+,\d+,)(\d+)(,)/, `$1${newRank}$3`);
}

function hasNumericRank(line) {
  return /^\s*\{\d+,"[^"]+",\d+,\d+,\d+,/.test(line);
}

function clampOrDrop(parsed) {
  if (parsed.minLevel > MAX_LEVEL) return null;
  let minL = parsed.minLevel;
  let maxL = Math.min(parsed.maxLevel, MAX_LEVEL);
  if (minL > maxL) return null;
  if (maxL === parsed.maxLevel && minL === parsed.minLevel) return parsed.raw;
  return parsed.raw.replace(
    /^(\s*\{\d+,"[^"]+",)\d+,\d+/,
    `$1${minL},${maxL}`,
  );
}

function bandKey(line) {
  const parsed = parsePickLine(line);
  if (!parsed) return line;
  const specFac = line.match(/,"([a-z_]+)","(Alliance|Horde)"/);
  if (specFac) return `${parsed.slot}|${parsed.minLevel}|${parsed.maxLevel}|${specFac[1]}|${specFac[2]}`;
  const fac = line.match(/,"(Alliance|Horde)"/);
  if (fac) return `${parsed.slot}|${parsed.minLevel}|${parsed.maxLevel}|${fac[1]}`;
  return `${parsed.slot}|${parsed.minLevel}|${parsed.maxLevel}`;
}

function filterRowTable(body, tbcIds, remapRanks) {
  const lines = body.split("\n").filter((l) => l.trim().startsWith("{"));
  const kept = [];
  let droppedTbc = 0;
  let droppedLevel = 0;

  for (const line of lines) {
    const parsed = parsePickLine(line);
    if (!parsed) {
      kept.push(line);
      continue;
    }
    if (tbcIds.has(parsed.itemId)) {
      droppedTbc++;
      continue;
    }
    const next = clampOrDrop(parsed);
    if (!next) {
      droppedLevel++;
      continue;
    }
    kept.push(next);
  }

  if (!remapRanks) {
    return { body: kept.length ? "\n" + kept.join("\n") + "\n" : "\n", droppedTbc, droppedLevel };
  }

  const grouped = new Map();
  const notables = [];
  for (const line of kept) {
    if (!hasNumericRank(line)) {
      notables.push(line);
      continue;
    }
    const key = bandKey(line);
    if (!grouped.has(key)) grouped.set(key, []);
    grouped.get(key).push(line);
  }

  const remapped = [];
  for (const rows of grouped.values()) {
    rows.sort((a, b) => {
      const ra = Number(a.match(/^\s*\{\d+,"[^"]+",\d+,\d+,(\d+)/)[1]);
      const rb = Number(b.match(/^\s*\{\d+,"[^"]+",\d+,\d+,(\d+)/)[1]);
      return ra - rb;
    });
    rows.slice(0, 3).forEach((line, i) => remapped.push(remapRank(line, i + 1)));
  }
  remapped.push(...notables);
  return {
    body: remapped.length ? "\n" + remapped.join("\n") + "\n" : "\n",
    droppedTbc,
    droppedLevel,
  };
}

function filterFacts(body, usedIds) {
  const lines = body.split("\n");
  const out = [];
  for (const line of lines) {
    const m = line.match(/^\s*\[(\d+)\]=/);
    if (!m) {
      if (line.trim() === "") continue;
      out.push(line);
      continue;
    }
    if (usedIds.has(Number(m[1]))) out.push(line);
  }
  return out.length ? "\n" + out.join("\n") + "\n" : "\n";
}

function collectUsedIds(picksBody, notableBody) {
  const ids = new Set();
  for (const body of [picksBody, notableBody]) {
    if (!body) continue;
    for (const m of body.matchAll(/\{(\d+),"/g)) ids.add(Number(m[1]));
  }
  return ids;
}

const FILES = fs.readdirSync(genDir).filter((f) => f.endsWith(".generated.lua") && f.startsWith("Data."));
const noClassicPage = loadNoClassicPageIds();
const allTbc = new Set([...noClassicPage]);

const fileTexts = FILES.map((file) => {
  const filePath = path.join(genDir, file);
  const text = fs.readFileSync(filePath, "utf8");
  const tableNames = [...text.matchAll(/GQ\.Data\.(\w+) = \{/g)].map((m) => m[1]);
  const factsNames = tableNames.filter((n) => /Facts$/i.test(n) || n === "itemFacts");
  const pickNames = tableNames.filter((n) => !/Facts$/i.test(n) && n !== "itemFacts");
  for (const factsName of factsNames) {
    for (const id of collectTbcIdsFromFacts(text, factsName, noClassicPage)) allTbc.add(id);
  }
  return { file, filePath, text, factsNames, pickNames };
});

let totalDroppedTbc = 0;
let totalDroppedLevel = 0;

for (const entry of fileTexts) {
  let { file, filePath, text, factsNames, pickNames } = entry;
  const tbcIds = allTbc;
  let fileDropTbc = 0;
  let fileDropLevel = 0;

  for (const name of pickNames) {
    const table = extractTable(text, name);
    if (!table) continue;
    const isNotable = /Notable$/i.test(name);
    const { body, droppedTbc, droppedLevel } = filterRowTable(table.body, tbcIds, !isNotable);
    fileDropTbc += droppedTbc;
    fileDropLevel += droppedLevel;
    text = text.slice(0, table.index) + `GQ.Data.${name} = {${body}}` + text.slice(table.index + table.full.length);
  }

  const used = new Set();
  for (const name of pickNames) {
    const table = extractTable(text, name);
    if (!table) continue;
    for (const id of collectUsedIds(table.body, "")) used.add(id);
  }
  for (const factsName of factsNames) {
    const table = extractTable(text, factsName);
    if (!table) continue;
    const nextBody = filterFacts(table.body, used);
    text = text.slice(0, table.index) + `GQ.Data.${factsName} = {${nextBody}}` + text.slice(table.index + table.full.length);
  }

  text = text
    .replace(/levels 10-69/gi, "levels 10-60")
    .replace(/10–69/g, "10–60")
    .replace(/10-69/g, "10-60")
    .replace(/levels 1–69/g, "levels 1–60")
    .replace(/exceed level 69/g, "exceed level 60");

  totalDroppedTbc += fileDropTbc;
  totalDroppedLevel += fileDropLevel;
  console.log(`${file}: dropped TBC ${fileDropTbc}, over-60 ${fileDropLevel}`);
  if (!dryRun) fs.writeFileSync(filePath, text);
}

const tbcList = [...allTbc].sort((a, b) => a - b);
if (!dryRun) {
  fs.writeFileSync(
    outIdsPath,
    JSON.stringify({ count: tbcList.length, ids: tbcList, noClassicPage: [...noClassicPage].sort((a, b) => a - b) }, null, 2),
  );
}
console.log(`TBC-only IDs flagged: ${tbcList.length} (noClassicPage ${noClassicPage.size})`);
console.log(`Rows dropped: TBC ${totalDroppedTbc}, level>${MAX_LEVEL} ${totalDroppedLevel}${dryRun ? " (dry-run)" : ""}`);
