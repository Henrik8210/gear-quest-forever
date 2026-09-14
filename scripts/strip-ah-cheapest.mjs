import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const generatedDir = path.join(__dirname, "..", "GearQuest", "_generated");

const files = fs.readdirSync(generatedDir).filter((f) => f.endsWith(".generated.lua"));
const phrase = " Often cheapest on the auction house.";

for (const file of files) {
  const full = path.join(generatedDir, file);
  const before = fs.readFileSync(full, "utf8");
  if (!before.includes(phrase)) continue;
  const count = before.split(phrase).length - 1;
  const after = before.replaceAll(phrase, "");
  fs.writeFileSync(full, after);
  console.log(`${file}: removed ${count} occurrence(s)`);
}
