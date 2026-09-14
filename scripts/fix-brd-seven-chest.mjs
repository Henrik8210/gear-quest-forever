/**
 * Chest of The Seven (BRD) loot is boss reward chest loot, not a generic container.
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const genDir = path.join(__dirname, "..", "GearQuest", "_generated");

const SEVEN_CHEST_ITEMS = new Set([
  11921, // Impervious Giant
  11923, // The Hammer of Grace
  11925, // Ghostshroud
  11926, // Deathdealer Breastplate
  11927, // Legplates of the Eternal Guardian
  11929, // Haunting Specter Leggings
  11945, // Dark Iron Ring
  11946, // Fire Opal Necklace
]);

const BOSS_CHEST_META =
  'sourceType="boss_drop",instructions="Drops from the Chest of The Seven after defeating the Seven in Blackrock Depths.",zone="Blackrock Depths",npc="The Seven"';

const re =
  /\[(\d+)\]=\{name="([^"]+)",sourceType="object_drop",instructions="Found in a container.",npc="a container"\}/g;

let total = 0;
for (const file of fs.readdirSync(genDir)) {
  if (!file.startsWith("Data.") || !file.endsWith(".generated.lua")) continue;
  const filePath = path.join(genDir, file);
  const text = fs.readFileSync(filePath, "utf8");
  let n = 0;
  const next = text.replace(re, (full, id, name) => {
    if (!SEVEN_CHEST_ITEMS.has(Number(id))) return full;
    n++;
    return `[${id}]={name="${name}",${BOSS_CHEST_META}}`;
  });
  if (n > 0) {
    fs.writeFileSync(filePath, next);
    console.log(`${file}: ${n}`);
    total += n;
  }
}

console.log(`Updated ${total} Seven chest entries.`);
