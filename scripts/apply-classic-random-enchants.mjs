/**
 * Patch generated pick/notable rows with Classic Wowhead random-enchant tables.
 * Adjusts suffixChance, suffixRange, and score (expected suffix-stat contribution delta).
 *
 * Prereq: node scripts/scrape-classic-random-enchants.mjs
 *
 * Usage: node scripts/apply-classic-random-enchants.mjs [--dry-run]
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { parseRandomEnchantsFromHtml } from "./parse-wh-random-enchants.mjs";
import {
  expectedSuffixStatScore,
  formatSuffixRange,
} from "./lib/random-enchant-stats.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "..");
const genDir = path.join(root, "GearQuest", "_generated");
const classicCachePath = path.join(genDir, "data", "items_random.classic.json");
const tbcCachePath = path.join(genDir, "data", "items_random.tbc.json");

const UA = "GearQuestForever-data/1.0";
const dryRun = process.argv.includes("--dry-run");

const CLASS_FILES = fs.readdirSync(genDir).filter((f) => f.endsWith(".generated.lua"));

const WEIGHTS = {};
for (const f of fs.readdirSync(genDir)) {
  const m = f.match(/^([A-Z]+)\.weights\.json$/);
  if (!m) continue;
  WEIGHTS[m[1]] = JSON.parse(fs.readFileSync(path.join(genDir, f), "utf8"))[m[1]];
}

function specWeights(className, spec) {
  const block = WEIGHTS[className];
  if (!block) return null;
  if (spec === "nil" || spec == null) return block.levelling_1_9?.weights;
  return block[spec]?.weights ?? block.default?.weights;
}

function classFromFile(name) {
  if (name.includes("Paladin")) return "PALADIN";
  if (name.includes("Warrior")) return "WARRIOR";
  if (name.includes("Hunter")) return "HUNTER";
  if (name.includes("Druid")) return "DRUID";
  if (name.includes("Shaman")) return "SHAMAN";
  if (name.includes("Rogue")) return "ROGUE";
  if (name.includes("Priest")) return "PRIEST";
  if (name.includes("Warlock")) return "WARLOCK";
  if (name.includes("Mage")) return "MAGE";
  return null;
}

async function ensureTbcCache(ids) {
  let tbc = {};
  if (fs.existsSync(tbcCachePath)) {
    tbc = JSON.parse(fs.readFileSync(tbcCachePath, "utf8"));
  }
  for (const id of ids) {
    const key = String(id);
    if (tbc[key]?.enchants?.length) continue;
    const url = `https://www.wowhead.com/tbc/item=${id}/random-enchants`;
    const r = await fetch(url, { headers: { "User-Agent": UA } });
    const html = await r.text();
    const enchants = parseRandomEnchantsFromHtml(html);
    tbc[key] = {
      itemId: id,
      era: "tbc",
      enchants,
      scrapedAt: new Date().toISOString(),
    };
    await new Promise((res) => setTimeout(res, 300));
  }
  fs.mkdirSync(path.dirname(tbcCachePath), { recursive: true });
  fs.writeFileSync(tbcCachePath, JSON.stringify(tbc, null, 2));
  return tbc;
}

function patchRowFixed(rowText, classicEnchants, tbcEnchants, className) {
  const suffixM = rowText.match(/suffix="([^"]+)"/);
  if (!suffixM) return { text: rowText, changed: false };

  // Pick row: {id,slot,min,max,rank,spec,faction,score,suffix=...}
  // Notable row: {id,slot,min,max,spec,faction,suffix=...} (no rank/score)
  const specM = rowText.match(/,\d+,\d+,(?:\d+,)?"([a-z_]+)","(?:Alliance|Horde)"/);
  const scoreM = rowText.match(/,"(?:Alliance|Horde)",([\d.]+),suffix="/);
  if (!specM) return { text: rowText, changed: false };

  const suffix = suffixM[1];
  const spec = specM[1];
  const weights = specWeights(className, spec);
  if (!weights) return { text: rowText, changed: false };

  const classicEntry = classicEnchants.find((e) => e.suffix === suffix);
  if (!classicEntry) return { text: rowText, changed: false };

  const newRange = formatSuffixRange(classicEntry.statsText);
  const newChance = classicEntry.chance;

  let out = rowText;
  const oldChance = rowText.match(/suffixChance=([\d.]+)/);
  const oldRange = rowText.match(/suffixRange="([^"]*)"/);

  out = out.replace(/suffixChance=[\d.]+/, `suffixChance=${newChance}`);
  if (oldRange) {
    out = out.replace(/suffixRange="[^"]*"/, `suffixRange="${newRange.replace(/"/g, '\\"')}"`);
  } else {
    out = out.replace(/suffix="[^"]+"/, `$& ,suffixRange="${newRange}"`.replace(" ,", ","));
  }

  const rangeChanged = oldRange && oldRange[1] !== newRange;
  if (rangeChanged && /suffixId=/.test(out)) {
    out = out.replace(/,suffixId=-?\d+/, "");
  }

  let scoreChanged = false;
  if (scoreM) {
    const oldScore = Number(scoreM[1]);
    let newScore = oldScore;
    if (tbcEnchants?.length) {
      const eTbc = expectedSuffixStatScore(tbcEnchants, weights);
      const eClassic = expectedSuffixStatScore(classicEnchants, weights);
      newScore = Math.round((oldScore - eTbc + eClassic) * 100) / 100;
    }
    if (Math.abs(newScore - oldScore) > 0.005) {
      out = out.replace(`,${oldScore},suffix=`, `,${newScore},suffix=`);
      scoreChanged = true;
    }
  }

  const changed =
    !oldChance ||
    Number(oldChance[1]) !== newChance ||
    !oldRange ||
    oldRange[1] !== newRange ||
    rangeChanged ||
    scoreChanged;

  return { text: out, changed };
}

if (!fs.existsSync(classicCachePath)) {
  console.error("Missing cache. Run: node scripts/scrape-classic-random-enchants.mjs");
  process.exit(1);
}

const classicCache = JSON.parse(fs.readFileSync(classicCachePath, "utf8"));
const itemIds = Object.keys(classicCache).filter((k) => classicCache[k].enchants?.length);
console.log("Classic cache items with enchants:", itemIds.length);

const tbcCache = await ensureTbcCache(itemIds.map(Number));

let totalChanges = 0;

for (const file of CLASS_FILES) {
  const className = classFromFile(file);
  if (!className) continue;
  const filePath = path.join(genDir, file);
  let text = fs.readFileSync(filePath, "utf8");
  const lines = text.split("\n");
  let fileChanges = 0;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!line.includes("suffix=")) continue;
    const idM = line.match(/\{(\d+),/);
    if (!idM) continue;
    const classic = classicCache[idM[1]];
    if (!classic?.enchants?.length) continue;
    const tbc = tbcCache[idM[1]]?.enchants ?? [];
    const { text: newLine, changed } = patchRowFixed(line, classic.enchants, tbc, className);
    if (changed) {
      lines[i] = newLine;
      fileChanges++;
    }
  }

  if (fileChanges > 0) {
    totalChanges += fileChanges;
    if (!dryRun) {
      fs.writeFileSync(filePath, lines.join("\n"));
    }
    console.log(`${file}: ${fileChanges} rows ${dryRun ? "(dry-run)" : "patched"}`);
  }
}

console.log(`Total row patches: ${totalChanges}${dryRun ? " (dry-run, no writes)" : ""}`);
