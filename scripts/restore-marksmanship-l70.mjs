/**
 * Restore hunter marksmanship level-70 curated rows (clone of beast_mastery band).
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const dataPath = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "GearQuest", "Data.lua");
let text = fs.readFileSync(dataPath, "utf8");

if (text.includes('id = "level70_hunter_marksmanship_')) {
  console.log("Marksmanship L70 rows already present.");
  process.exit(0);
}

const startMarker = "    -- HUNTER / beast_mastery (AtlasLoot HunterBM_P3)";
const endMarker = "    -- HUNTER / survival (AtlasLoot HunterSurv_P3)";
const start = text.indexOf(startMarker);
const end = text.indexOf(endMarker);
if (start < 0 || end < 0 || end <= start) {
  throw new Error("Hunter L70 section markers not found");
}

const bmBlock = text.slice(start, end);
let mmBlock = bmBlock
  .replace(
    startMarker,
    "    -- HUNTER / marksmanship (copy of beast_mastery @ 70 — MM/BM share gear pool)",
  )
  .replace(/beast_mastery/g, "marksmanship")
  .replace(/SPEC_BEAST_MASTERY/g, "SPEC_MARKSMANSHIP");

if (!text.includes("local SPEC_MARKSMANSHIP")) {
  text = text.replace(
    "local SPEC_BEAST_MASTERY = { beast_mastery = true }",
    "local SPEC_BEAST_MASTERY = { beast_mastery = true }\nlocal SPEC_MARKSMANSHIP = { marksmanship = true }",
  );
}

text = text.slice(0, end) + mmBlock + text.slice(end);
fs.writeFileSync(dataPath, text);
console.log("Inserted", (mmBlock.match(/level70_hunter_marksmanship_/g) || []).length, "marksmanship L70 entries");
