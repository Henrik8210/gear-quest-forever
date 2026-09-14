/**
 * Drop failed/empty Classic cache rows so scrape can refetch (keeps rows with enchants).
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const cachePath = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  "..",
  "GearQuest",
  "_generated",
  "data",
  "items_random.classic.json",
);

const cache = JSON.parse(fs.readFileSync(cachePath, "utf8"));
let removed = 0;
for (const [key, row] of Object.entries(cache)) {
  if (row.enchants?.length) continue;
  delete cache[key];
  removed++;
}
fs.writeFileSync(cachePath, JSON.stringify(cache, null, 2));
console.log(`Pruned ${removed} empty/failed rows; kept ${Object.keys(cache).length} with enchants.`);
