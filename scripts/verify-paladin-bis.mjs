import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "..", "GearQuest");

function countTableRows(text, tableName) {
  const marker = `GQ.Data.${tableName} = {`;
  const start = text.indexOf(marker);
  if (start < 0) return 0;
  const slice = text.slice(start);
  const end = slice.indexOf("\n}");
  return (slice.slice(0, end).match(/^\s*\{/gm) || []).length;
}

function countFactKeys(text, tableName) {
  const marker = `GQ.Data.${tableName} = {`;
  const start = text.indexOf(marker);
  if (start < 0) return 0;
  const slice = text.slice(start);
  const end = slice.indexOf("\n}");
  return (slice.slice(0, end).match(/\[\d+\]=/g) || []).length;
}

const dataLua = fs.readFileSync(path.join(root, "Data.lua"), "utf8");
const mainLua = fs.readFileSync(
  path.join(root, "_generated", "Data.Paladin.generated.lua"),
  "utf8",
);
const hordeLua = fs.readFileSync(
  path.join(root, "_generated", "Data.Paladin.Horde.1to9.generated.lua"),
  "utf8",
);

const curated = (dataLua.match(/^\s+id = /gm) || []).length;
const mainPicks = countTableRows(mainLua, "paladinPicks");
const hordePicks = countTableRows(mainLua.replace(/paladinPicks[\s\S]*/, ""), "paladinHorde1to9");
const hordePicksReal = countTableRows(hordeLua, "paladinHorde1to9");

console.log("=== Counts ===");
console.log("Curated:", curated);
console.log("paladinPicks:", mainPicks);
console.log("paladinHorde1to9:", hordePicksReal);
console.log("Expected total:", curated + mainPicks + hordePicksReal);

const picksBody = mainLua.match(/GQ\.Data\.paladinPicks = \{([\s\S]*?)\n\}/)?.[1] ?? "";
let maxLevel = 0;
let badBands = 0;
for (const m of picksBody.matchAll(/\{(\d+),"([^"]+)",(\d+),(\d+),/g)) {
  const minL = +m[3];
  const maxL = +m[4];
  maxLevel = Math.max(maxLevel, minL, maxL);
  if (minL > maxL) badBands++;
}
console.log("\n=== Bounds ===");
console.log("Max level in main picks:", maxLevel);
console.log("minLevel > maxLevel rows:", badBands);

const thunder = picksBody.match(
  /\{19019,"MainHand",60,60,1,"protection","Alliance"[^}]*\}/,
);
console.log("\n=== Spot checks (raw rows) ===");
console.log("Prot 60 MH rank1 Alliance:", thunder?.[0] ?? "MISSING");

const soldier = picksBody.match(
  /\{6545,"Chest",13,14,1,"retribution","Alliance"[^}]*\}/,
);
console.log("Ret 13-14 chest rank1:", soldier?.[0] ?? "MISSING");
