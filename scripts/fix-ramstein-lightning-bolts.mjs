import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const ITEM = 13515;
const REPO = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "GearQuest", "_generated");

const FILES = [
  "Data.Warrior.generated.lua",
  "Data.Paladin.generated.lua",
  "Data.Shaman.generated.lua",
];

const SHAMAN_PICK_RE =
  /^\s*\{13515,"Trinket",55,55,3,"enhancement","Alliance",[^}]+\},?\s*$/;
const SHAMAN_BACKFILL =
  '    {13965,"Trinket",55,55,3,"enhancement","Alliance",23.8},';

let totalRemoved = 0;

for (const file of FILES) {
  const full = path.join(REPO, file);
  const lines = fs.readFileSync(full, "utf8").split("\n");
  let removed = 0;
  let backfilled = false;

  const kept = lines.flatMap((line) => {
    if (SHAMAN_PICK_RE.test(line)) {
      removed++;
      backfilled = true;
      return [SHAMAN_BACKFILL];
    }
    if (line.includes(`{${ITEM},`) || line.includes(`[${ITEM}]=`)) {
      removed++;
      return [];
    }
    return [line];
  });

  fs.writeFileSync(full, kept.join("\n"));
  totalRemoved += removed;
  console.log(`${file}: removed ${removed} row(s)${backfilled ? ", backfilled 55-55 enhancement pick" : ""}`);
}

console.log(`Total removed: ${totalRemoved} Ramstein's Lightning Bolts (${ITEM}) row(s)`);
