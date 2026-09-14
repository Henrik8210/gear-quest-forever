import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const file = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  "..",
  "GearQuest",
  "_generated",
  "Data.Warrior.generated.lua",
);

let text = fs.readFileSync(file, "utf8");
const start = text.indexOf("GQ.Data.warriorNotable = {");
const end = text.indexOf("\n}", start);
const before = text.slice(0, start);
const block = text.slice(start, end);
const after = text.slice(end);

const lines = block.split("\n");
const kept = lines.filter((line) => {
  if (!line.includes("{1447,")) return true;
  if (line.includes('"arms"') || line.includes('"fury"')) return false;
  return true;
});

const removed = lines.length - kept.length;
fs.writeFileSync(file, before + kept.join("\n") + after);
console.log(`Removed ${removed} Ring of Saviors arms/fury notable row(s)`);
