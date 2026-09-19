/**
 * Extra reference layer: veldt1 Forever Item Explorer vs Wowhead Forever cache.
 *
 * Wowhead remains the ingest source (`scrape-forever-wowhead-items.mjs` →
 * `ingest_forever_wowhead.py`). This script never writes items.json.
 *
 * veldt1 is a client-diff explorer (beta 1.60.1.69876 vs Classic 1.15.9) with
 * stats computed from StatPercentEditor × RandPropPoints:
 *   https://veldt1.github.io/wowf-items/
 *
 * Usage:
 *   node scripts/diff-veldt-wowhead.mjs
 *   node scripts/diff-veldt-wowhead.mjs --refresh   # re-download veldt HTML
 *
 * Cache (gitignored with the rest of forever_wowhead/):
 *   pipeline/data/forever_wowhead/veldt_items.json
 *   pipeline/data/forever_wowhead/veldt_wowhead_diff.json
 */
import fs from "fs";
import path from "path";
import vm from "vm";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "..");
const cacheDir = path.join(root, "pipeline", "data", "forever_wowhead");
const htmlPath = path.join(cacheDir, "veldt_index.html");
const veldtPath = path.join(cacheDir, "veldt_items.json");
const diffPath = path.join(cacheDir, "veldt_wowhead_diff.json");
const wowheadIndexPath = path.join(cacheDir, "index.json");
const wowheadTipsPath = path.join(cacheDir, "tooltips.json");

const VELDT_URL = "https://raw.githubusercontent.com/veldt1/wowf-items/main/index.html";
const UA = "GearQuestForever-data/1.0";
const MIN_FOREVER_ID = 200000;
const EQUIP_CLASSES = new Set(["Armor", "Weapon"]);
const SKIP_SLOTS = new Set(["Tabard", "Shirt", "Non-equip", "Bag", "Ammo"]);

const COMBAT_RE =
  /\+\d|Armor|Damage|Equip:|Use:|Chance on hit|spell power|attack power/i;

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function fetchText(url, attempt = 0) {
  const r = await fetch(url, { headers: { "User-Agent": UA } });
  if ((r.status === 403 || r.status === 429) && attempt < 5) {
    const wait = Math.min(60_000, 1500 * (attempt + 2));
    console.warn(`HTTP ${r.status} ${url} — retry ${attempt + 1} in ${wait}ms`);
    await sleep(wait);
    return fetchText(url, attempt + 1);
  }
  if (!r.ok) throw new Error(`HTTP ${r.status} for ${url}`);
  return r.text();
}

function extractJsArray(html, marker) {
  const i = html.indexOf(marker);
  if (i < 0) return null;
  let p = i + marker.length;
  while (p < html.length && html[p] !== "[") p++;
  if (html[p] !== "[") return null;
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
  return null;
}

function mapVeldtRow(r) {
  return {
    id: r[0],
    name: r[1],
    quality: r[2],
    cls: r[3],
    subclass: r[4],
    slot: r[5],
    ilvl: r[6],
    req: r[7],
    bond: r[8],
    stats: r[9] || "",
    set: r[10] || "",
    sell: r[11] || 0,
    desc: r[12] || "",
    fx: r[13] || "",
  };
}

function veldtHasCombat(row) {
  const stats = String(row.stats || "").trim();
  const fx = String(row.fx || "").trim().replace(/^(Equip|Use):\s*$/i, "");
  return Boolean(stats || fx);
}

function isHuntSlot(row) {
  return EQUIP_CLASSES.has(row.cls) && !SKIP_SLOTS.has(row.slot);
}

function stripHtml(html) {
  return String(html || "")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function wowheadHasCombat(tip) {
  if (!tip || tip.error || !tip.tooltip) return false;
  return COMBAT_RE.test(stripHtml(tip.tooltip));
}

function slim(row, extra = {}) {
  return {
    id: row.id,
    name: row.name,
    quality: row.quality,
    cls: row.cls,
    subclass: row.subclass,
    slot: row.slot,
    ilvl: row.ilvl,
    req: row.req,
    stats: row.stats || "",
    fx: row.fx || "",
    set: row.set || "",
    ...extra,
  };
}

async function loadVeldt(refresh) {
  let html;
  if (!refresh && fs.existsSync(htmlPath)) {
    html = fs.readFileSync(htmlPath, "utf8");
    console.log(`using cached ${htmlPath}`);
  } else {
    console.log(`fetching ${VELDT_URL}`);
    html = await fetchText(VELDT_URL);
    fs.mkdirSync(cacheDir, { recursive: true });
    fs.writeFileSync(htmlPath, html);
  }

  const build =
    (html.match(/WoW Classic beta\s+<b>([^<]+)<\/b>/i) ||
      html.match(/1\.60\.\d+\.\d+/))?.[1] ||
    (html.match(/1\.60\.\d+\.\d+/) || [null])[0] ||
    "unknown";

  const raw = extractJsArray(html, "const DATA=");
  if (!Array.isArray(raw) || !raw.length) {
    throw new Error("Could not parse const DATA=[...] from veldt HTML");
  }

  const items = raw.map(mapVeldtRow);
  const payload = {
    fetchedAt: new Date().toISOString(),
    source: VELDT_URL,
    explorer: "https://veldt1.github.io/wowf-items/",
    build,
    count: items.length,
    items,
  };
  fs.writeFileSync(veldtPath, JSON.stringify(payload));
  console.log(`parsed ${items.length} veldt rows (build ${build}) -> ${veldtPath}`);
  return payload;
}

function loadWowhead() {
  if (!fs.existsSync(wowheadIndexPath)) {
    throw new Error(
      `missing ${wowheadIndexPath} — run node scripts/scrape-forever-wowhead-items.mjs --index`
    );
  }
  const index = JSON.parse(fs.readFileSync(wowheadIndexPath, "utf8"));
  const tips = fs.existsSync(wowheadTipsPath)
    ? JSON.parse(fs.readFileSync(wowheadTipsPath, "utf8"))
    : {};
  return { index, tips };
}

function tipFor(tips, id) {
  return tips[String(id)] || tips[id] || null;
}

function mainReport(veldt, wowhead) {
  const byVeldt = new Map(veldt.items.map((r) => [r.id, r]));
  const wowItems = wowhead.index.items || [];
  const byWow = new Map(wowItems.map((r) => [r.id, r]));
  const tips = wowhead.tips;

  const veldtEquipForever = veldt.items.filter((r) => r.id >= MIN_FOREVER_ID && isHuntSlot(r));
  const veldtOtherForever = veldt.items.filter((r) => r.id >= MIN_FOREVER_ID && !isHuntSlot(r));
  const veldtClassic = veldt.items.filter((r) => r.id < MIN_FOREVER_ID);

  const wowheadMissingStatsVeldtHas = [];
  const wowheadHasStatsVeldtEmpty = [];
  const bothHaveStats = [];
  const bothEmpty = [];

  for (const row of veldtEquipForever) {
    const wow = byWow.get(row.id);
    if (!wow) continue;
    const tip = tipFor(tips, row.id);
    const whCombat = wowheadHasCombat(tip);
    const vdCombat = veldtHasCombat(row);
    const rec = slim(row, {
      wowheadName: wow.name,
      wowheadSlot: wow.slot,
      wowheadTooltip: tip
        ? tip.error
          ? `error: ${tip.error}`
          : stripHtml(tip.tooltip || "").slice(0, 220)
        : "(no tooltip cache)",
    });
    if (!whCombat && vdCombat) wowheadMissingStatsVeldtHas.push(rec);
    else if (whCombat && !vdCombat) wowheadHasStatsVeldtEmpty.push(rec);
    else if (whCombat && vdCombat) bothHaveStats.push({ id: row.id, name: row.name });
    else bothEmpty.push(rec);
  }

  const veldtNotOnWowhead = veldtEquipForever
    .filter((r) => !byWow.has(r.id))
    .map((r) => slim(r));

  const wowheadNotOnVeldt = wowItems
    .filter((r) => !byVeldt.has(r.id))
    .map((r) => ({
      id: r.id,
      name: r.name,
      slot: r.slot,
      ilvl: r.ilvl,
      rlvl: r.rlvl,
      quality: r.quality,
    }));

  const classicRetunesWithStats = veldtClassic
    .filter((r) => isHuntSlot(r) && veldtHasCombat(r))
    .map((r) => slim(r));

  const setNames = [
    ...new Set(veldt.items.map((r) => r.set).filter(Boolean)),
  ].sort();

  wowheadMissingStatsVeldtHas.sort((a, b) => a.id - b.id);
  veldtNotOnWowhead.sort((a, b) => a.id - b.id);
  wowheadNotOnVeldt.sort((a, b) => a.id - b.id);

  return {
    generatedAt: new Date().toISOString(),
    note:
      "Wowhead is the ingest source. veldt1 is a second reference (client diff + computed stats). Do not merge veldt into items.json from this report.",
    veldt: {
      source: veldt.source,
      explorer: veldt.explorer,
      build: veldt.build,
      fetchedAt: veldt.fetchedAt,
      rows: veldt.count,
      foreverIds: veldt.items.filter((r) => r.id >= MIN_FOREVER_ID).length,
      foreverEquipment: veldtEquipForever.length,
      foreverOther: veldtOtherForever.length,
      classicDiffRows: veldtClassic.length,
    },
    wowhead: {
      scrapedAt: wowhead.index.scrapedAt,
      foreverItems: wowItems.length,
      tooltipKeys: Object.keys(tips).length,
    },
    counts: {
      overlapEquipment: veldtEquipForever.filter((r) => byWow.has(r.id)).length,
      wowheadMissingStatsVeldtHas: wowheadMissingStatsVeldtHas.length,
      wowheadHasStatsVeldtEmpty: wowheadHasStatsVeldtEmpty.length,
      bothHaveStats: bothHaveStats.length,
      bothEmpty: bothEmpty.length,
      veldtEquipNotOnWowhead: veldtNotOnWowhead.length,
      wowheadNotOnVeldt: wowheadNotOnVeldt.length,
      classicRetunesWithStats: classicRetunesWithStats.length,
      setNames: setNames.length,
    },
    wowheadMissingStatsVeldtHas,
    veldtEquipNotOnWowhead: veldtNotOnWowhead,
    wowheadNotOnVeldt,
    bothEmpty: bothEmpty.slice(0, 80),
    wowheadHasStatsVeldtEmpty: wowheadHasStatsVeldtEmpty.slice(0, 40),
    classicRetunesWithStats: classicRetunesWithStats.slice(0, 80),
    setNames,
  };
}

function printSummary(report) {
  const c = report.counts;
  console.log("\n=== veldt1 vs Wowhead Forever ===");
  console.log(`veldt build ${report.veldt.build}: ${report.veldt.rows} rows (${report.veldt.foreverEquipment} Forever equipment)`);
  console.log(`Wowhead index: ${report.wowhead.foreverItems} items (scraped ${report.wowhead.scrapedAt || "?"})`);
  console.log(`overlap (Forever equipment): ${c.overlapEquipment}`);
  console.log(`Wowhead tooltip empty, veldt has stats/fx: ${c.wowheadMissingStatsVeldtHas}`);
  console.log(`veldt equipment id not on Wowhead index: ${c.veldtEquipNotOnWowhead}`);
  console.log(`Wowhead index id not in veldt: ${c.wowheadNotOnVeldt}`);
  console.log(`both empty: ${c.bothEmpty}`);
  console.log(`set names on veldt: ${c.setNames}`);

  const show = (title, rows, n = 12) => {
    if (!rows.length) return;
    console.log(`\n${title} (showing ${Math.min(n, rows.length)} of ${rows.length})`);
    for (const r of rows.slice(0, n)) {
      const extra = [r.stats, r.fx, r.set].filter(Boolean).join(" | ");
      console.log(`  [${r.id}] ${r.name} ${r.slot || ""} ilvl ${r.ilvl ?? "?"} — ${extra || r.wowheadTooltip || ""}`);
    }
  };

  show("Wowhead missing combat stats — veldt has numbers", report.wowheadMissingStatsVeldtHas);
  show("Forever equipment on veldt, not in Wowhead index", report.veldtEquipNotOnWowhead);
}

const args = new Set(process.argv.slice(2));
const veldt = await loadVeldt(args.has("--refresh"));
const wowhead = loadWowhead();
const report = mainReport(veldt, wowhead);
fs.mkdirSync(cacheDir, { recursive: true });
fs.writeFileSync(diffPath, JSON.stringify(report, null, 2));
printSummary(report);
console.log(`\nwrote ${diffPath}`);
