import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const file = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  "..",
  "GearQuest",
  "_generated",
  "Data.Druid.generated.lua",
);

let text = fs.readFileSync(file, "utf8");
const start = text.indexOf("GQ.Data.druidNotable = {");
const end = text.indexOf("\n}", start);
const block = text.slice(start, end);

let removed = 0;
const kept = block.split("\n").filter((line) => {
  if (!line.includes("{9449,")) return true;
  if (line.includes('"balance"') || line.includes('"restoration"')) {
    removed++;
    return false;
  }
  return true;
});

text = text.slice(0, start) + kept.join("\n") + text.slice(end);
fs.writeFileSync(file, text);
console.log(`Removed ${removed} balance/restoration Crowd Pummeler notable row(s)`);
