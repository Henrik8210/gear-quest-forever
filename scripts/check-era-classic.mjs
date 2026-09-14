/**
 * Forever era guard: random-enchant tables must match Wowhead Classic, not TBC.
 * Fingerprint: Vice Grips (9640) — of Strength +17 @ 9.0% (Classic) vs +20 @ 7.9% (TBC).
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { parseRandomEnchantsFromHtml } from "./parse-wh-random-enchants.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const cachePath = path.join(__dirname, "..", "GearQuest", "_generated", "data", "items_random.classic.json");

const UA = "GearQuestForever-data/1.0";

async function liveEnchants(era, id = 9640) {
  const url = `https://www.wowhead.com/${era}/item=${id}/random-enchants`;
  const r = await fetch(url, { headers: { "User-Agent": UA } });
  if (!r.ok) return null;
  return parseRandomEnchantsFromHtml(await r.text());
}

function findStrength(rows) {
  return rows?.find((e) => e.suffix === "of Strength");
}

let fail = 0;

const classicLive = await liveEnchants("classic");
const tbcLive = await liveEnchants("tbc");
if (classicLive && tbcLive) {
  const cStr = findStrength(classicLive);
  const tStr = findStrength(tbcLive);
  console.log("Live Classic of Strength:", cStr?.statsText, cStr?.chance + "%");
  console.log("Live TBC of Strength:", tStr?.statsText, tStr?.chance + "%");
  if (!cStr || !cStr.statsText.includes("17") || Math.abs(cStr.chance - 9) > 0.2) {
    console.error("FAIL: Classic Vice Grips live fingerprint unexpected");
    fail++;
  }
} else {
  console.warn("WARN: Wowhead rate-limited — using cache-only checks");
}

if (fs.existsSync(cachePath)) {
  const cache = JSON.parse(fs.readFileSync(cachePath, "utf8"));
  const cached = cache["9640"]?.enchants;
  const cCached = cached && findStrength(cached);
  if (!cCached || !cCached.statsText.includes("17")) {
    const warriorPath = path.join(__dirname, "..", "GearQuest", "_generated", "Data.Warrior.generated.lua");
    const wText = fs.readFileSync(warriorPath, "utf8");
    const genOk =
      wText.includes('9640,"Hands"') &&
      wText.includes('suffixRange="+17 Strength"') &&
      !wText.includes('suffixRange="+20 Strength"');
    if (genOk) {
      console.warn(
        "WARN: cache missing 9640 Classic table — re-run: node scripts/scrape-classic-random-enchants.mjs --ids=9640",
      );
    } else {
      console.error("FAIL: cache and generated both lack Classic Vice Grips +17");
      fail++;
    }
  } else {
    console.log("Cache 9640 of Strength OK");
  }

  const highIlvl = Object.values(cache).filter(
    (v) => v.enchants?.length && v.enchants.some((e) => e.statsText?.includes("117")),
  );
  if (highIlvl.length > 0) {
    console.error(`FAIL: ${highIlvl.length} cached items look TBC (ilvl 117 suffix text)`);
    fail++;
  }
} else {
  console.warn("WARN: no items_random.classic.json yet — run scrape-classic-random-enchants.mjs");
}

// Spot-check generated row still TBC-stale?
const warriorPath = path.join(__dirname, "..", "GearQuest", "_generated", "Data.Warrior.generated.lua");
const wText = fs.readFileSync(warriorPath, "utf8");
if (wText.includes('9640,"Hands"') && wText.includes('suffixRange="+20 Strength"')) {
  console.warn("WARN: Warrior 9640 rows still show TBC +20 Strength — run apply-classic-random-enchants.mjs");
} else if (wText.includes('9640,"Hands"') && wText.includes('suffixRange="+17 Strength"')) {
  console.log("Generated 9640 rows: Classic +17 Strength OK");
}

process.exit(fail ? 1 : 0);
