#!/usr/bin/env node
/**
 * Emit GearQuest/_generated/CraftSkills.generated.lua from Wowhead TBC spell pages.
 * Craft skill (orange difficulty) is on the recipe spell, not the item tooltip.
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "..");
const genDir = path.join(root, "GearQuest", "_generated");

const UA = { "User-Agent": "GearQuest/1.0 (craft skill generator)" };
const DELAY_MS = 200;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function extractProfessionItems() {
  const items = new Map();
  const re =
    /\[(\d+)\]=\{name="([^"]+)",sourceType="profession",instructions="([^"]*)",profession="([^"]+)"/g;

  for (const file of fs.readdirSync(genDir)) {
    if (!file.startsWith("Data.") || !file.endsWith(".generated.lua")) continue;
    const text = fs.readFileSync(path.join(genDir, file), "utf8");
    let m;
    while ((m = re.exec(text))) {
      const itemId = Number(m[1]);
      if (!items.has(itemId)) {
        items.set(itemId, {
          itemId,
          name: m[2],
          instructions: m[3],
          profession: m[4],
        });
      }
    }
  }
  return [...items.values()].sort((a, b) => a.itemId - b.itemId);
}

async function fetchText(url) {
  const r = await fetch(url, { headers: UA });
  if (!r.ok) throw new Error(`${r.status} ${url}`);
  return r.text();
}

// Known item -> recipe spell when Wowhead item pages omit the craft link.
const KNOWN_SPELLS = {
  29964: 36074, // Blackstorm Leggings
};

async function findSpellIdForItem(item) {
  if (KNOWN_SPELLS[item.itemId]) {
    return KNOWN_SPELLS[item.itemId];
  }

  const searchText = await fetchText(
    `https://www.wowhead.com/tbc/search?q=${encodeURIComponent(item.name)}&json`,
  );

  const itemBlock = searchText.match(
    new RegExp(`\\{"appearances"[\\s\\S]*?"id":${item.itemId},[\\s\\S]*?\\}\\}`),
  );
  if (itemBlock) {
    const ti = itemBlock[0].match(/"ti":(\d+)/);
    if (ti) {
      return Number(ti[1]);
    }
  }

  const nearId = searchText.match(
    new RegExp(`"id":${item.itemId}[\\s\\S]{0,400}?"ti":(\\d+)`),
  );
  if (nearId) {
    return Number(nearId[1]);
  }

  return null;
}

function parseCraftSkillFromSpellHtml(html, profession) {
  const requires = html.match(
    new RegExp(`Requires ${profession.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\s*\\((\\d+)\\)`, "i"),
  );
  if (requires) return Number(requires[1]);

  const difficulty = html.match(/Difficulty:\s*(\d+)/i);
  if (difficulty) return Number(difficulty[1]);

  const quickFacts = html.match(/Quick Facts[\s\S]{0,800}?(\d{2,3})\s+\d{2,3}\s+\d{2,3}\s+\d{2,3}/i);
  if (quickFacts) return Number(quickFacts[1]);

  const jsonSkill = html.match(/"learnedat"\s*:\s*(\d+)/i);
  if (jsonSkill) return Number(jsonSkill[1]);

  return null;
}

async function fetchCraftSkill(item) {
  const spellId = await findSpellIdForItem(item);
  if (!spellId) {
    console.warn(`  no spell for ${item.itemId} ${item.name}`);
    return null;
  }

  await sleep(DELAY_MS);
  const html = await fetchText(
    `https://www.wowhead.com/tbc/spell=${spellId}/${encodeURIComponent(item.name.replace(/\s+/g, "-").toLowerCase())}`,
  );
  const skill = parseCraftSkillFromSpellHtml(html, item.profession);
  if (!skill) {
    console.warn(`  no skill on spell ${spellId} for ${item.itemId} ${item.name}`);
    return null;
  }

  return { spellId, skill };
}

function luaEscape(s) {
  return s.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

async function main() {
  const items = extractProfessionItems();
  const onlyPlaceholder = process.argv.includes("--placeholder-only");
  const itemArg = process.argv.find((a) => a.startsWith("--item="));
  const itemFilter = itemArg ? Number(itemArg.split("=")[1]) : null;
  let toFetch = onlyPlaceholder
    ? items.filter((i) => i.instructions.includes("requires skill 1"))
    : items;
  if (itemFilter) {
    toFetch = items.filter((i) => i.itemId === itemFilter);
  }

  console.log(`Fetching craft skills for ${toFetch.length} profession items...`);

  const out = {};
  for (const item of toFetch) {
    process.stdout.write(`${item.itemId} ${item.name}... `);
    try {
      const data = await fetchCraftSkill(item);
      if (data) {
        out[item.itemId] = {
          profession: item.profession,
          skill: data.skill,
          spellId: data.spellId,
        };
        console.log(`${data.skill} (spell ${data.spellId})`);
      } else {
        console.log("skip");
      }
    } catch (e) {
      console.log(`error: ${e.message}`);
    }
    await sleep(DELAY_MS);
  }

  const outPath = path.join(genDir, "CraftSkills.generated.lua");
  const merged = {};
  if (fs.existsSync(outPath)) {
    const prev = fs.readFileSync(outPath, "utf8");
    for (const m of prev.matchAll(
      /GQ\.CraftSkills\[(\d+)\]\s*=\s*\{\s*profession\s*=\s*"([^"]*)",\s*skill\s*=\s*(\d+),\s*spellId\s*=\s*(\d+)\s*\}/g,
    )) {
      merged[m[1]] = {
        profession: m[2],
        skill: Number(m[3]),
        spellId: Number(m[4]),
      };
    }
  }

  for (const [itemId, row] of Object.entries(out)) {
    merged[itemId] = row;
  }

  let lua = `-- AUTO-GENERATED by scripts/generate-craft-skills.mjs — do not edit.
-- Source: Wowhead TBC recipe spells (orange Difficulty / Requires Profession (N)).
-- Item tooltips do not include craft skill; only recipe pages do.

local _, GQ = ...
GQ.CraftSkills = GQ.CraftSkills or {}

`;

  for (const itemId of Object.keys(merged).sort((a, b) => Number(a) - Number(b))) {
    const row = merged[itemId];
    lua += `GQ.CraftSkills[${itemId}] = { profession = "${luaEscape(row.profession)}", skill = ${row.skill}, spellId = ${row.spellId} }\n`;
  }

  fs.writeFileSync(outPath, lua);
  console.log(`\nWrote ${outPath} (${Object.keys(merged).length} items)`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
