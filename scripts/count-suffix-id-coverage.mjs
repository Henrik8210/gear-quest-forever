import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const dir = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "GearQuest", "_generated");

let suffixRows = 0;
let withId = 0;

for (const f of fs.readdirSync(dir).filter((x) => x.endsWith(".generated.lua"))) {
  const t = fs.readFileSync(path.join(dir, f), "utf8");
  const rows = [...t.matchAll(/\{[^}]+\},?/g)].map((m) => m[0]);
  for (const row of rows) {
    if (!/suffix=/.test(row)) continue;
    suffixRows++;
    if (/suffixId=/.test(row)) withId++;
  }
}

console.log(`Suffix rows: ${suffixRows}`);
console.log(`With suffixId: ${withId} (${((100 * withId) / suffixRows).toFixed(1)}%)`);
console.log(`Missing: ${suffixRows - withId}`);
