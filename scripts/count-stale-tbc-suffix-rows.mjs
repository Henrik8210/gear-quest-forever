/**
 * Rows still carrying known TBC Vice Grips fingerprint (+20 Str @ 7.9%).
 * After full Classic apply, this should be 0 for cached items.
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const genDir = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "GearQuest", "_generated");
let total = 0;
for (const name of fs.readdirSync(genDir)) {
  if (!name.endsWith(".generated.lua")) continue;
  const text = fs.readFileSync(path.join(genDir, name), "utf8");
  const n = (text.match(/suffixChance=7\.9,suffixId=312,suffixRange="\+20 Strength"/g) || []).length;
  if (n) console.log(name, n);
  total += n;
}
console.log("Total stale TBC +20/@7.9 rows:", total);
process.exit(total > 0 ? 1 : 0);
