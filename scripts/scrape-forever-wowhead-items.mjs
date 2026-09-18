/**
 * Index Forever-only Wowhead items (id >= 200000) and cache tooltips.
 *
 * Wowhead Forever listview caps at 1,000 rows. Query by slot (and quality if a
 * slot is truncated) so the catalog is complete.
 *
 * Usage:
 *   node scripts/scrape-forever-wowhead-items.mjs           # index + tooltips
 *   node scripts/scrape-forever-wowhead-items.mjs --index
 *   node scripts/scrape-forever-wowhead-items.mjs --tooltips
 *
 * Cache: pipeline/data/forever_wowhead/{index,tooltips}.json
 * Ingest with: python pipeline/scripts/ingest_forever_wowhead.py
 */
import fs from "fs";
import path from "path";
import vm from "vm";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "..");
const outDir = path.join(root, "pipeline", "data", "forever_wowhead");
const indexPath = path.join(outDir, "index.json");
const tooltipPath = path.join(outDir, "tooltips.json");

const UA = "GearQuestForever-data/1.0";
const PAGE_DELAY = Number(process.env.GQ_SCRAPE_DELAY_MS || 1200);
const TIP_DELAY = Number(process.env.GQ_TOOLTIP_DELAY_MS || 250);
const MIN_ID = 200000;

const SLOTS = [
  [1, "Head"],
  [2, "Neck"],
  [3, "Shoulder"],
  [5, "Chest"],
  [6, "Waist"],
  [7, "Legs"],
  [8, "Feet"],
  [9, "Wrist"],
  [10, "Hands"],
  [11, "Finger"],
  [12, "Trinket"],
  [13, "OneHand"],
  [14, "Shield"],
  [15, "Ranged"],
  [16, "Back"],
  [17, "TwoHand"],
  [21, "MainHand"],
  [22, "OffHand"],
  [23, "Held"],
  [25, "Thrown"],
  [26, "Ranged"],
  [28, "Relic"],
];

const QUALITIES = [0, 1, 2, 3, 4, 5];

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function fetchText(url, attempt = 0) {
  const r = await fetch(url, { headers: { "User-Agent": UA } });
  if ((r.status === 403 || r.status === 429) && attempt < 5) {
    const wait = Math.min(60_000, PAGE_DELAY * (attempt + 2));
    console.warn(`HTTP ${r.status} ${url} — retry ${attempt + 1} in ${wait}ms`);
    await sleep(wait);
    return fetchText(url, attempt + 1);
  }
  if (!r.ok) {
    throw new Error(`HTTP ${r.status} for ${url}`);
  }
  return r.text();
}

function extractListviewItems(html) {
  const marker = "var listviewitems = ";
  const i = html.indexOf(marker);
  if (i < 0) return [];
  let p = i + marker.length;
  while (p < html.length && html[p] !== "[") p++;
  if (html[p] !== "[") return [];
  let depth = 0;
  const start = p;
  for (; p < html.length; p++) {
    const c = html[p];
    if (c === "[") depth++;
    else if (c === "]") {
      depth--;
      if (depth === 0) {
        return vm.runInNewContext("(" + html.slice(start, p + 1) + ")");
      }
    }
  }
  return [];
}

function listUrl(slot, quality) {
  const base = `https://www.wowhead.com/forever/items/slot:${slot}`;
  const q = quality == null ? "" : `/quality:${quality}`;
  return `${base}${q}?filter=151:195;2:1;${MIN_ID}:0`;
}

function slimRow(row, slotName) {
  return {
    id: row.id,
    name: row.name,
    slot: slotName,
    slotId: row.slot,
    ilvl: row.level || 0,
    rlvl: row.reqlevel || 0,
    quality: row.quality ?? 0,
    classs: row.classs,
    subclass: row.subclass,
    armor: row.armor || 0,
    dps: row.dps || 0,
    speed: row.speed || 0,
    source: row.source || [],
    sourcemore: row.sourcemore || [],
  };
}

async function fetchSlot(slot, slotName, quality) {
  const url = listUrl(slot, quality);
  const html = await fetchText(url);
  const rows = extractListviewItems(html).filter(
    (r) => r && r.id >= MIN_ID && (r.classs === 2 || r.classs === 4)
  );
  const truncated =
    /1,000 displayed/i.test(html) ||
    /1000 displayed/i.test(html) ||
    rows.length >= 1000;
  return { url, rows: rows.map((r) => slimRow(r, slotName)), truncated };
}

async function buildIndex() {
  const byId = new Map();
  const notes = [];

  for (const [slot, slotName] of SLOTS) {
    process.stdout.write(`index slot ${slot} ${slotName}... `);
    const first = await fetchSlot(slot, slotName);
    if (!first.truncated) {
      for (const row of first.rows) byId.set(row.id, row);
      console.log(`${first.rows.length}`);
      notes.push({ slot, slotName, n: first.rows.length, truncated: false });
      await sleep(PAGE_DELAY);
      continue;
    }

    console.log(`truncated at ${first.rows.length}, splitting by quality`);
    let n = 0;
    for (const quality of QUALITIES) {
      const part = await fetchSlot(slot, slotName, quality);
      for (const row of part.rows) byId.set(row.id, row);
      n += part.rows.length;
      if (part.truncated) {
        console.warn(`  quality ${quality} still truncated (${part.rows.length})`);
      }
      await sleep(PAGE_DELAY);
    }
    notes.push({ slot, slotName, n, truncated: true });
  }

  const items = [...byId.values()].sort((a, b) => a.id - b.id);
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(
    indexPath,
    JSON.stringify(
      {
        scrapedAt: new Date().toISOString(),
        minId: MIN_ID,
        count: items.length,
        slots: notes,
        items,
      },
      null,
      2
    )
  );
  console.log(`wrote ${items.length} items -> ${indexPath}`);
  return items;
}

async function fetchTooltips(items) {
  fs.mkdirSync(outDir, { recursive: true });
  let cache = {};
  if (fs.existsSync(tooltipPath)) {
    cache = JSON.parse(fs.readFileSync(tooltipPath, "utf8"));
  }

  const missing = items.filter((it) => !cache[it.id]);
  console.log(`tooltips cached ${Object.keys(cache).length}, need ${missing.length}`);

  for (let i = 0; i < missing.length; i++) {
    const id = missing[i].id;
    const url = `https://nether.wowhead.com/forever/tooltip/item/${id}`;
    try {
      const text = await fetchText(url);
      cache[id] = JSON.parse(text);
    } catch (err) {
      console.warn(`tooltip ${id}: ${err.message}`);
      cache[id] = { error: String(err.message) };
    }
    if ((i + 1) % 25 === 0 || i === missing.length - 1) {
      fs.writeFileSync(tooltipPath, JSON.stringify(cache));
      process.stdout.write(`  ${i + 1}/${missing.length}\n`);
    }
    await sleep(TIP_DELAY);
  }
  fs.writeFileSync(tooltipPath, JSON.stringify(cache));
  console.log(`wrote tooltips -> ${tooltipPath}`);
}

const args = new Set(process.argv.slice(2));
const doIndex = args.has("--index") || args.size === 0;
const doTips = args.has("--tooltips") || args.size === 0;

let items = [];
if (doIndex) {
  items = await buildIndex();
} else if (fs.existsSync(indexPath)) {
  items = JSON.parse(fs.readFileSync(indexPath, "utf8")).items;
}

if (doTips) {
  if (!items.length && fs.existsSync(indexPath)) {
    items = JSON.parse(fs.readFileSync(indexPath, "utf8")).items;
  }
  if (!items.length) {
    throw new Error("No index. Run --index first.");
  }
  await fetchTooltips(items);
}
