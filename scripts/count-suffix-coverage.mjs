/**
 * How many generated suffix-item IDs have Classic enchant tables in cache?
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
for (const id of ids) {
  const row = cache[id];
  if (!row) missing++;
  else if (row.enchants?.length) withClassic++;
  else empty++;
}

console.log("Generated rows reference suffix on", ids.size, "unique item IDs");
console.log("Classic cache: keys", Object.keys(cache).length);
console.log("  overlap with enchants:", withClassic);
console.log("  overlap empty/failed:", empty);
console.log("  not in cache:", missing);
const pct = ids.size ? ((100 * withClassic) / ids.size).toFixed(1) : "0";
console.log("Classic-backed suffix items:", pct + "%");
const MIN_PCT = Number(process.env.GQ_SUFFIX_COVERAGE_MIN || 0);
if (MIN_PCT > 0 && withClassic / ids.size < MIN_PCT / 100) {
  console.error(`FAIL: coverage below GQ_SUFFIX_COVERAGE_MIN=${MIN_PCT}%`);
  process.exit(1);
}
