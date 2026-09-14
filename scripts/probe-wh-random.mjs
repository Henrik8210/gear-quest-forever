import { parseRandomEnchantsFromHtml } from "./parse-wh-random-enchants.mjs";

const id = process.argv[2] || "14926";
const r = await fetch(`https://www.wowhead.com/classic/item=${id}/random-enchants`, {
  headers: { "User-Agent": "GearQuestForever-data/1.0" },
});
console.log("status", r.status);
const html = await r.text();
console.log("parsed", parseRandomEnchantsFromHtml(html).length);
const idx = html.indexOf("of Strength");
console.log("of Strength at", idx);
if (idx >= 0) console.log(html.slice(idx - 80, idx + 350));
