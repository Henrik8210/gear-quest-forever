/**
 * Scrape Wowhead Classic random-enchant tables for item IDs used in generated picks.
 * Cache: GearQuest/_generated/data/items_random.classic.json
 *
 * Usage:
 *   node scripts/scrape-classic-random-enchants.mjs
 *   node scripts/scrape-classic-random-enchants.mjs --ids 9640,6570
 *   node scripts/scrape-classic-random-enchants.mjs --refresh
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { parseRandomEnchantsFromHtml } from "./parse-wh-random-enchants.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "..");
const genDir = path.join(root, "GearQuest", "_generated");
const cachePath = path.join(genDir, "data", "items_random.classic.json");

const UA = "GearQuestForever-data/1.0";
const DELAY_MS = Number(process.env.GQ_SCRAPE_DELAY_MS || 2000);
const MAX_RETRIES = 4;

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function fetchHtml(url, attempt = 0) {
  const r = await fetch(url, { headers: { "User-Agent": UA } });
  if (r.status === 403 && attempt < MAX_RETRIES) {
    const wait = Math.min(60_000, DELAY_MS * (attempt + 2));
    console.warn(`403 ${url} — retry ${attempt + 1}/${MAX_RETRIES} in ${wait}ms`);
    await sleep(wait);
    return fetchHtml(url, attempt + 1);
  }
  if (!r.ok) {
    throw new Error(`HTTP ${r.status} for ${url}`);
  }
  return r.text();
}

function collectItemIdsFromGenerated() {
  const ids = new Set();
  for (const name of fs.readdirSync(genDir)) {
    if (!name.endsWith(".generated.lua")) continue;
    const text = fs.readFileSync(path.join(genDir, name), "utf8");
    // Pick rows (with rank) and notable rows (no rank) both carry suffix=
    for (const m of text.matchAll(/\{(\d+),"[^"]+",\d+,\d+,(?:\d+,)?[^}]*suffix="/g)) {
      ids.add(Number(m[1]));
    }
  }
  return [...ids].sort((a, b) => a - b);
}

async function scrapeItem(id, era = "classic") {
  const urls = [
    `https://www.wowhead.com/${era}/item=${id}/random-enchants`,
    `https://www.wowhead.com/${era}/item=${id}?power`,
  ];
  let enchants = [];
  for (const url of urls) {
    const html = await fetchHtml(url);
    enchants = parseRandomEnchantsFromHtml(html);
    if (enchants.length > 0) break;
    await sleep(DELAY_MS);
  }
  if (enchants.length === 0) {
    return null;
  }
  const chanceSum = enchants.reduce((s, e) => s + e.chance, 0);
  return {
    itemId: id,
    era,
    scrapedAt: new Date().toISOString(),
    enchants,
    chanceSum: Math.round(chanceSum * 100) / 100,
  };
}

const args = process.argv.slice(2);
const refresh = args.includes("--refresh");
const retry403 = args.includes("--retry-403");
const reprobeEmpty = args.includes("--reprobe-empty");
let idList = null;
const idsArg = args.find((a) => a.startsWith("--ids="));
if (idsArg) {
  idList = idsArg
    .slice(6)
    .split(",")
    .map((x) => Number(x.trim()))
    .filter(Boolean);
}

if (!idList) {
  idList = collectItemIdsFromGenerated();
}

fs.mkdirSync(path.dirname(cachePath), { recursive: true });
let cache = {};
if (fs.existsSync(cachePath)) {
  cache = JSON.parse(fs.readFileSync(cachePath, "utf8"));
}

console.log(`Items to scrape (Classic): ${idList.length}; cache has ${Object.keys(cache).length}`);

let ok = 0;
let skip = 0;
let fail = 0;

for (let i = 0; i < idList.length; i++) {
  const id = idList[i];
  const key = String(id);
  const force = refresh || (idsArg != null && idList.includes(id));
  if (!force && cache[key]?.enchants?.length) {
    skip++;
    continue;
  }
  if (!force && cache[key]?.empty && !reprobeEmpty) {
    skip++;
    continue;
  }
  if (!force && !retry403 && cache[key]?.failed403) {
    skip++;
    continue;
  }
  if (reprobeEmpty && cache[key]?.empty) {
    delete cache[key];
  }
  try {
    if ((i + 1) % 10 === 0 || i === 0) {
      console.log(`[${i + 1}/${idList.length}] item ${id}…`);
    }
    const row = await scrapeItem(id, "classic");
    if (row) {
      cache[key] = row;
      ok++;
    } else if (!cache[key]?.enchants?.length) {
      cache[key] = { itemId: id, era: "classic", enchants: [], empty: true, scrapedAt: new Date().toISOString() };
      skip++;
    } else {
      skip++;
    }
  } catch (e) {
    console.error(`FAIL ${id}:`, e.message);
    if (String(e.message).includes("403") && !cache[key]?.enchants?.length) {
      cache[key] = { itemId: id, failed403: true, scrapedAt: new Date().toISOString() };
    }
    fail++;
  }
  if ((i + 1) % 25 === 0) {
    fs.writeFileSync(cachePath, JSON.stringify(cache, null, 2));
    console.log(`Progress ${i + 1}/${idList.length} (ok ${ok}, skip ${skip}, fail ${fail})`);
  }
  await sleep(DELAY_MS);
}

fs.writeFileSync(cachePath, JSON.stringify(cache, null, 2));
console.log(`Done. ok=${ok} skip=${skip} fail=${fail}`);
console.log(`Cache: ${cachePath}`);
