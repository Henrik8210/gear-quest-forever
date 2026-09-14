/**
 * Convert GearQuest/Art/GearQuest-Logo.png → .tga for WoW (requires: npm install pngjs)
 * Usage: node scripts/png-to-tga.mjs [input.png] [output.tga]
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { PNG } from "pngjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const inPath = process.argv[2] || path.join(__dirname, "../GearQuest/Art/GearQuest-Logo.png");
const outPath = process.argv[3] || inPath.replace(/\.png$/i, ".tga");

const png = PNG.sync.read(fs.readFileSync(inPath));
const { width: w, height: h, data } = png;
const buf = Buffer.alloc(18 + w * h * 4);
buf[2] = 2;
buf[12] = w & 255;
buf[13] = w >> 8;
buf[14] = h & 255;
buf[15] = h >> 8;
buf[16] = 32;
buf[17] = 0x28;
let o = 18;
for (let y = h - 1; y >= 0; y--) {
  for (let x = 0; x < w; x++) {
    const i = (w * y + x) * 4;
    buf[o++] = data[i + 2];
    buf[o++] = data[i + 1];
    buf[o++] = data[i];
    buf[o++] = data[i + 3];
  }
}
fs.writeFileSync(outPath, buf);
console.log("Wrote", outPath, `(${w}x${h})`);
