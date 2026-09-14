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
const lines = text.split("\n");
let removed = 0;

const kept = lines.filter((line) => {
  if (!line.includes("{2825,")) return true;
  removed++;
  return false;
});

fs.writeFileSync(file, kept.join("\n"));
console.log(`Removed ${removed} Bow of Searing Arrows (2825) pick/notable row(s)`);
