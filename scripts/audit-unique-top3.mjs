/**
 * After unique-name emit: every spec × faction × level × slot should have
 * 3 uniquely named picks (2H off-hand empty until rescore is allowed).
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const genDir = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  "..",
  "..",
  "GearQuest",
  "GearQuest",
  "_generated"
);

const FILES = [
  ["WARRIOR", "Data.Warrior.generated.lua"],
  ["PALADIN", "Data.Paladin.generated.lua"],
  ["HUNTER", "Data.Hunter.generated.lua"],
  ["DRUID", "Data.Druid.generated.lua"],
  ["SHAMAN", "Data.Shaman.generated.lua"],
  ["ROGUE", "Data.Rogue.generated.lua"],
  ["PRIEST", "Data.Priest.generated.lua"],
  ["WARLOCK", "Data.Warlock.generated.lua"],
  ["MAGE", "Data.Mage.generated.lua"],
];

const SLOTS = [
  "Head", "Neck", "Shoulder", "Back", "Chest", "Wrist", "Hands",
  "Waist", "Legs", "Feet", "Finger", "Trinket", "MainHand", "SecondaryHand", "Ranged",
];

function parse(text) {
  const names = new Map();
  for (const m of text.matchAll(/\[(\d+)\]=\{name="([^"]+)"/g)) {
    names.set(Number(m[1]), m[2]);
  }
  const rows = [];
  const re = /\{\s*(\d+),\s*"([^"]+)",\s*(\d+),\s*(\d+),\s*(\d+),\s*"([^"]+)",\s*"([^"]+)"/g;
  let m;
  while ((m = re.exec(text))) {
    rows.push({
      id: Number(m[1]),
      slot: m[2],
      lo: Number(m[3]),
      hi: Number(m[4]),
      rank: Number(m[5]),
      spec: m[6],
      faction: m[7],
    });
  }
  return { names, rows };
}

const nameDups = [];
const short = [];
const emptyOH = [];

for (const [cls, file] of FILES) {
  const { names, rows } = parse(fs.readFileSync(path.join(genDir, file), "utf8"));
  const specs = [...new Set(rows.map((r) => r.spec))];
  const factions = [...new Set(rows.map((r) => r.faction))];
  for (const spec of specs) {
    for (const faction of factions) {
      for (const slot of SLOTS) {
        for (let lv = 10; lv <= 60; lv++) {
          const hit = rows.filter(
            (r) =>
              r.spec === spec &&
              r.faction === faction &&
              r.slot === slot &&
              r.lo <= lv &&
              r.hi >= lv
          );
          const display = hit.map((r) => names.get(r.id) || String(r.id));
          const uniqNames = new Set(display);
          if (display.length && uniqNames.size < display.length) {
            nameDups.push({ cls, spec, faction, slot, lv, display });
          }
          if (slot === "SecondaryHand" && hit.length === 0) {
            if (lv === 51) emptyOH.push({ cls, spec, faction, lv });
            continue;
          }
          if (hit.length && hit.length !== 3 && lv === 51) {
            short.push({ cls, spec, faction, slot, count: hit.length, display });
          }
        }
      }
    }
  }
}

console.log("name-dup bands", nameDups.length, nameDups.slice(0, 8));
console.log("short@51 (non-OH)", short.length, short.slice(0, 12));
console.log("empty OH @51", emptyOH);
