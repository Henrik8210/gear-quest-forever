/**
 * Audit generated picks: one top-3 per class × spec × faction × level × slot.
 * Overlapping bands and short lists are the usual "everything looks doubled" causes.
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const genDir = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "GearQuest", "_generated");

const FILES = [
  ["WARRIOR", "Data.Warrior.generated.lua", "warriorPicks", 10, 60],
  ["PALADIN", "Data.Paladin.generated.lua", "paladinPicks", 10, 60],
  ["HUNTER", "Data.Hunter.generated.lua", "hunterPicks", 10, 60],
  ["DRUID", "Data.Druid.generated.lua", "druidPicks", 10, 60],
  ["SHAMAN", "Data.Shaman.generated.lua", "shamanPicks", 10, 60],
  ["ROGUE", "Data.Rogue.generated.lua", "roguePicks", 10, 60],
  ["PRIEST", "Data.Priest.generated.lua", "priestPicks", 10, 60],
  ["WARLOCK", "Data.Warlock.generated.lua", "warlockPicks", 10, 60],
  ["MAGE", "Data.Mage.generated.lua", "magePicks", 10, 60],
];

const SLOTS = [
  "Head", "Neck", "Shoulder", "Back", "Chest", "Wrist", "Hands",
  "Waist", "Legs", "Feet", "Finger", "Trinket", "MainHand", "SecondaryHand", "Ranged",
];

function parsePicks(text, tableName) {
  const start = text.indexOf(`GQ.Data.${tableName} = {`);
  if (start < 0) return [];
  const body = text.slice(start);
  const rows = [];
  const re =
    /\{\s*(\d+),\s*"([^"]+)",\s*(\d+),\s*(\d+),\s*(\d+),\s*"([^"]+)",\s*"([^"]+)"/g;
  let m;
  while ((m = re.exec(body))) {
    rows.push({
      id: Number(m[1]),
      slot: m[2],
      lo: Number(m[3]),
      hi: Number(m[4]),
      rank: Number(m[5]),
      spec: m[6],
      faction: m[7],
    });
    if (m[0].includes("GQ.Data.") && rows.length > 3 && m.index > 200) {
      /* keep going — table is huge */
    }
  }
  return rows;
}

function factNames(text) {
  const names = new Map();
  for (const m of text.matchAll(/\[(\d+)\]=\{name="([^"]+)"/g)) {
    names.set(Number(m[1]), m[2]);
  }
  return names;
}

function bandsFor(rows) {
  const map = new Map();
  for (const r of rows) {
    const key = `${r.spec}|${r.faction}|${r.slot}|${r.lo}|${r.hi}`;
    if (!map.has(key)) map.set(key, { ...r, ids: [] });
    map.get(key).ids.push(r.id);
  }
  return [...map.values()];
}

function overlaps(a, b) {
  return a.lo <= b.hi && b.lo <= a.hi;
}

const report = {
  generatedAt: new Date().toISOString(),
  classes: {},
  overlapBands: [],
  shortAt51: [],
  duplicateNamesAt51: [],
};

for (const [cls, file, table] of FILES) {
  const text = fs.readFileSync(path.join(genDir, file), "utf8");
  const rows = parsePicks(text, table);
  const names = factNames(text);
  const bands = bandsFor(rows);
  const specs = [...new Set(rows.map((r) => r.spec))];
  const factions = [...new Set(rows.map((r) => r.faction))];

  const overlap = [];
  const byKey = new Map();
  for (const b of bands) {
    const k = `${b.spec}|${b.faction}|${b.slot}`;
    if (!byKey.has(k)) byKey.set(k, []);
    byKey.get(k).push(b);
  }
  for (const [k, list] of byKey) {
    for (let i = 0; i < list.length; i++) {
      for (let j = i + 1; j < list.length; j++) {
        if (overlaps(list[i], list[j])) {
          overlap.push({
            class: cls,
            key: k,
            a: `${list[i].lo}-${list[i].hi} [${list[i].ids.join(",")}]`,
            b: `${list[j].lo}-${list[j].hi} [${list[j].ids.join(",")}]`,
          });
        }
      }
    }
  }

  let short51 = 0;
  let nameDup51 = 0;
  for (const spec of specs) {
    for (const faction of factions) {
      for (const slot of SLOTS) {
        const covering = bands.filter(
          (b) => b.spec === spec && b.faction === faction && b.slot === slot && b.lo <= 51 && b.hi >= 51
        );
        const ids = covering.flatMap((b) => b.ids);
        const uniq = [...new Set(ids)];
        const display = uniq.map((id) => names.get(id) || String(id));
        const nameCounts = {};
        for (const n of display) nameCounts[n] = (nameCounts[n] || 0) + 1;
        const dups = Object.entries(nameCounts).filter(([, c]) => c > 1);
        if (covering.length > 1) {
          report.shortAt51.push({
            class: cls,
            spec,
            faction,
            slot,
            issue: "overlapping bands at 51",
            bands: covering.map((b) => `${b.lo}-${b.hi}:${b.ids.join("/")}`),
          });
        }
        if (uniq.length !== 3) {
          short51++;
          report.shortAt51.push({
            class: cls,
            spec,
            faction,
            slot,
            count: uniq.length,
            names: display,
          });
        }
        if (dups.length) {
          nameDup51++;
          report.duplicateNamesAt51.push({ class: cls, spec, faction, slot, dups });
        }
      }
    }
  }

  report.classes[cls] = {
    rows: rows.length,
    specs,
    factions,
    bands: bands.length,
    overlappingBandPairs: overlap.length,
    shortSlotsAt51: short51,
    duplicateNamesAt51: nameDup51,
  };
  report.overlapBands.push(...overlap.slice(0, 20));
}

const outDir = path.join(path.dirname(fileURLToPath(import.meta.url)), "output");
fs.mkdirSync(outDir, { recursive: true });
const outPath = path.join(outDir, "generated-slot-audit.json");
fs.writeFileSync(outPath, JSON.stringify(report, null, 2));

console.log("=== Generated slot audit ===");
for (const [cls, info] of Object.entries(report.classes)) {
  console.log(
    `${cls}: specs=${info.specs.join(",")} bands=${info.bands} overlapPairs=${info.overlappingBandPairs} short@51=${info.shortSlotsAt51} nameDup@51=${info.duplicateNamesAt51}`
  );
}
console.log("overlap samples", report.overlapBands.length);
console.log("short@51 samples", report.shortAt51.slice(0, 12));
console.log("wrote", outPath);
