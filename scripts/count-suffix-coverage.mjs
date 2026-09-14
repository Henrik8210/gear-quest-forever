/**
 * How many generated suffix-item IDs have Classic enchant tables in cache?
 * Phase 2 gate uses scrapeable IDs (excludes Wowhead Classic 404 / noClassicPage).
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), "..");
const genDir = path.join(root, "GearQuest", "_generated");
const cachePath = path.join(genDir, "data", "items_random.classic.json");

const ids = new Set();
for (const name of fs.readdirSync(genDir)) {
  if (!name.endsWith(".generated.lua")) continue;
  const text = fs.readFileSync(path.join(genDir, name), "utf8");
  for (const m of text.matchAll(/\{(\d+),"[^"]+",\d+,\d+,(?:\d+,)?[^}]*suffix="/g)) {
    ids.add(m[1]);
  }
}

let cache = {};
if (fs.existsSync(cachePath)) {
  cache = JSON.parse(fs.readFileSync(cachePath, "utf8"));
}

let withClassic = 0;
let empty = 0;
let missing = 0;
let noClassicPage = 0;
for (const id of ids) {
  const row = cache[id];
  if (!row) missing++;
  else if (row.enchants?.length) withClassic++;
  else if (row.noClassicPage) noClassicPage++;
  else empty++;
}

const total = ids.size;
const scrapeable = total - noClassicPage;
const pctAll = total ? ((100 * withClassic) / total).toFixed(1) : "0";
const pctScrapeable = scrapeable ? ((100 * withClassic) / scrapeable).toFixed(1) : "0";

console.log("Generated rows reference suffix on", total, "unique item IDs");
console.log("Classic cache: keys", Object.keys(cache).length);
console.log("  overlap with enchants:", withClassic);
console.log("  no Classic Wowhead page (404):", noClassicPage);
console.log("  overlap empty/failed:", empty);
console.log("  not in cache:", missing);
console.log("Classic-backed suffix items (all IDs):", pctAll + "%");
console.log("Scrapeable suffix items:", scrapeable, "(total minus 404)");
console.log("Classic-backed (of scrapeable):", pctScrapeable + "%");

const MIN_PCT = Number(process.env.GQ_SUFFIX_COVERAGE_MIN || 0);
if (MIN_PCT > 0 && scrapeable > 0 && withClassic / scrapeable < MIN_PCT / 100) {
  console.error(`FAIL: scrapeable coverage below GQ_SUFFIX_COVERAGE_MIN=${MIN_PCT}%`);
  process.exit(1);
}
