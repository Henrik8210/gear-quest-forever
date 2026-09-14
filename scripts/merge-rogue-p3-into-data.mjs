import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const dataPath = path.join(__dirname, "../GearQuest/Data.lua");
const roguePath = path.join(__dirname, "output/rogue-p3-data.lua");

let data = fs.readFileSync(dataPath, "utf8");
const rogue = fs.readFileSync(roguePath, "utf8");

if (!data.includes("local ROGUE =")) {
  data = data.replace(
    "local SPEC_ELEMENTAL = { elemental = true }",
    "local SPEC_ELEMENTAL = { elemental = true }\nlocal ROGUE = { ROGUE = true }\nlocal SPEC_COMBAT = { combat = true }"
  );
}

const insertRe =
  /(\s+npc = "Cache of the Legion",\r?\n\s+\},\r?\n)\}(\r?\n\r?\nlocal SLOT_TO_INVENTORY = \{)/;

if (!insertRe.test(data)) {
  console.error("Insert point not found");
  process.exit(1);
}

data = data.replace(insertRe, `$1\n${rogue}}$2`);

if (!data.includes("ROGUE = true,")) {
  data = data.replace(
    /GQ\.Data\.CLASS_RANGED = \{\r?\n    HUNTER = true,/,
    "GQ.Data.CLASS_RANGED = {\n    ROGUE = true,\n    HUNTER = true,"
  );
}

fs.writeFileSync(dataPath, data);
console.log("Merged rogue entries into Data.lua");
