/**
 * Convert GearQuest/_generated/data/items_random.classic.json (Wowhead scrape)
 * into pipeline/data/items_random.json (score.py shape: stats / statsMin).
 *
 * Copies suffixId from pipeline/data/items_random.tbc.json when the suffix name
 * and high-end stats still match TBC. Range changes omit the id (wrong id is
 * worse than range-only tooltips).
 *
 * Usage: node scripts/convert-classic-random-to-pipeline.mjs
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), "..");
const classicPath = path.join(root, "GearQuest", "_generated", "data", "items_random.classic.json");
const tbcPath = path.join(root, "pipeline", "data", "items_random.tbc.json");
const outPath = path.join(root, "pipeline", "data", "items_random.json");

const SIMPLE = {
  Stamina: "sta",
  Intellect: "int",
  Strength: "str",
  Agility: "agi",
  Spirit: "spi",
  "Attack Power": "ap",
  Defense: "defense",
  "Defense Rating": "defense",
  "Dodge Rating": "dodge",
  "Block Rating": "blockRating",
  "Critical Strike Rating": "crit",
  "Spell Critical Strike Rating": "spellCrit",
  Healing: "heal",
  "Healing Spells": "heal",
  "Spell Damage and Healing": "sp",
  "Damage and Healing Spells": "sp",
  Haste: "haste",
  "Arcane Resistance": "resArcane",
  "Nature Resistance": "resNature",
  "Fire Resistance": "resFire",
  "Frost Resistance": "resFrost",
  "Shadow Resistance": "resShadow",
  "Resist Shadow": "resShadow",
};

const SCHOOL = /^(Arcane|Nature|Fire|Frost|Shadow|Holy)\s+(?:Spell\s+)?Damage$/i;
const HEALSP =
  /^\+\(?(\d+)\s*(?:-\s*(\d+))?\)?\s+Healing Spells and \+\(?(\d+)\s*(?:-\s*(\d+))?\)?\s+Damage Spells$/i;
const MP5 = /^\+\(?(\d+)\s*(?:-\s*(\d+))?\)?\s+[Mm]ana (?:Per|every) (\d+) sec\.?$/i;
const HP5 = /^\+\(?(\d+)\s*(?:-\s*(\d+))?\)?\s+[Hh]ealth (?:per|every) (\d+) sec\.?$/i;
const RX = /^\+\(?(\d+)\s*(?:-\s*(\d+))?\)?\s+(.*)$/;
const PCT = /^\+\(?(\d+)\s*(?:-\s*(\d+))?\)?%\s+(Block|Dodge)$/i;

function pick(lo, hi, end) {
  return end === "hi" ? (hi ?? lo) : lo;
}

function parseFrag(s, end) {
  s = s.trim();
  if (!s || s.includes("$i")) return {};
  let m = HEALSP.exec(s);
  if (m) {
    return {
      heal: pick(Number(m[1]), m[2] ? Number(m[2]) : null, end),
      sp_from_heal: pick(Number(m[3]), m[4] ? Number(m[4]) : null, end),
    };
  }
  m = MP5.exec(s);
  if (m) {
    const v = pick(Number(m[1]), m[2] ? Number(m[2]) : null, end);
    const per = Number(m[3]);
    return { mp5: Math.round((v * 5) / per * 100) / 100 };
  }
  if (HP5.test(s)) return {};
  m = PCT.exec(s);
  if (m) {
    const key = m[3].toLowerCase() === "block" ? "blockPct" : "dodge";
    return { [key]: pick(Number(m[1]), m[2] ? Number(m[2]) : null, end) };
  }
  m = RX.exec(s);
  if (!m) return null;
  const v = pick(Number(m[1]), m[2] ? Number(m[2]) : null, end);
  const label = m[3].trim();
  if (SIMPLE[label]) return { [SIMPLE[label]]: v };
  const sm = SCHOOL.exec(label);
  if (sm) return { ["sp" + sm[1][0].toUpperCase() + sm[1].slice(1).toLowerCase()]: v };
  return null;
}

function parseStatsText(statsText, end) {
  const stats = {};
  const parts = String(statsText || "")
    .split(",")
    .map((p) => p.trim())
    .filter(Boolean);
  for (const frag of parts) {
    const parsed = parseFrag(frag, end);
    if (parsed === null) return { ok: false, stats: null, frag };
    Object.assign(stats, parsed);
  }
  return { ok: true, stats };
}

function sameStats(a, b) {
  if (!a || !b) return false;
  const keys = new Set([...Object.keys(a), ...Object.keys(b)]);
  for (const k of keys) {
    if (a[k] !== b[k]) return false;
  }
  return true;
}

const classic = JSON.parse(fs.readFileSync(classicPath, "utf8"));
const tbc = fs.existsSync(tbcPath) ? JSON.parse(fs.readFileSync(tbcPath, "utf8")) : {};

const out = {};
let items = 0;
let variants = 0;
let withId = 0;
const unparsed = new Map();
const skipped = [];

for (const [id, row] of Object.entries(classic)) {
  if (row.noClassicPage || !row.enchants?.length) continue;
  const vs = [];
  const tbcBy = Object.fromEntries((tbc[id] || []).map((v) => [v.suffix, v]));
  for (const e of row.enchants) {
    const hi = parseStatsText(e.statsText, "hi");
    const lo = parseStatsText(e.statsText, "lo");
    if (!hi.ok || !lo.ok) {
      const frag = hi.frag || lo.frag;
      unparsed.set(frag, (unparsed.get(frag) || 0) + 1);
      continue;
    }
    if (!Object.keys(hi.stats).length && !Object.keys(lo.stats).length) continue;
    const suffix = e.suffix.startsWith("of") ? e.suffix : `of ${e.suffix.replace(/^\.+/, "").trim()}`;
    const rec = {
      suffix,
      chance: e.chance,
      chanceAny: e.chance,
      stats: hi.stats,
      statsMin: lo.stats,
    };
    const tbcV = tbcBy[suffix];
    if (tbcV?.suffixId != null && sameStats(tbcV.stats, hi.stats) && sameStats(tbcV.statsMin || tbcV.stats, lo.stats)) {
      rec.suffixId = tbcV.suffixId;
      withId++;
    }
    vs.push(rec);
    variants++;
  }
  if (vs.length) {
    out[id] = vs;
    items++;
  } else {
    skipped.push(id);
  }
}

fs.writeFileSync(outPath, JSON.stringify(out));
console.log(`wrote ${outPath}`);
console.log(`items: ${items}  variants: ${variants}  suffixId copied: ${withId}`);
if (skipped.length) console.log(`skipped (no parsed variants): ${skipped.join(", ")}`);
if (unparsed.size) {
  console.log("UNPARSED fragments:");
  for (const [frag, n] of [...unparsed.entries()].sort((a, b) => b[1] - a[1])) {
    console.log(`  ${String(n).padStart(4)}  ${frag}`);
  }
  process.exit(1);
}

const vg = (out["9640"] || []).find((v) => v.suffix === "of Strength");
if (!vg || vg.stats.str !== 17 || Math.abs(vg.chance - 9) > 0.2) {
  console.error("FAIL: Vice Grips of Strength is not Classic +17 @ 9%");
  process.exit(1);
}
console.log("era fingerprint: Vice Grips of Strength +17 @ 9% OK");
