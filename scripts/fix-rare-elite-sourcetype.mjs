/**
 * Reclassify dungeon/rare-elite boss drops that were tagged world_drop.
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const generatedDir = path.join(__dirname, "..", "GearQuest", "_generated");

const zoneByNpc = {
  Grizzle: "Blackrock Depths",
  "Gorosh the Dervish": "Blackrock Depths",
  "Anub'shiah": "Blackrock Depths",
  "Hedrum the Creeper": "Blackrock Depths",
  "Hurley Blackbreath": "Blackrock Depths",
  "Watchman Doomgrip": "Blackrock Depths",
};

for (const file of fs.readdirSync(generatedDir).filter((f) => f.endsWith(".generated.lua"))) {
  const full = path.join(generatedDir, file);
  let text = fs.readFileSync(full, "utf8");
  let count = 0;

  text = text.replace(
    /sourceType="world_drop",instructions="Drops from (.+?) \(rare elite\)(?: in ([^"]+))?\."(?:,zone="([^"]*)")?,npc="([^"]+)"/g,
    (_, who, zoneInText, zoneField, npc) => {
      count++;
      const zone = zoneInText || zoneField || zoneByNpc[npc];
      if (zone) {
        return `sourceType="boss_drop",instructions="Drops from ${who} in ${zone}.",zone="${zone}",npc="${npc}"`;
      }
      return `sourceType="boss_drop",instructions="Drops from ${who}.",npc="${npc}"`;
    },
  );

  fs.writeFileSync(full, text);
  if (count) console.log(`${file}: reclassified ${count} rare-elite drop(s)`);
}
