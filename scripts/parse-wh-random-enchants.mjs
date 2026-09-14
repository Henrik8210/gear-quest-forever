/**
 * Parse Wowhead item random-enchant list from ?power or /random-enchants HTML.
 */
export function parseRandomEnchantsFromHtml(html) {
  const enchants = [];
  const re =
    /<span class="q[23]">\.\.\.([^<]+)<\/span>\s*<small class="q0">\(([\d.]+)% chance\)<\/small><br\s*\/?>\s*([^<]*(?:<[^>]+>[^<]*)*?)\s*<\/div>/gi;
  let m;
  while ((m = re.exec(html))) {
    const suffix = m[1].trim();
    const chance = Number(m[2]);
    const statsHtml = m[3];
    const statsText = statsHtml
      .replace(/<br\s*\/?>/gi, ", ")
      .replace(/<[^>]+>/g, "")
      .replace(/\s+/g, " ")
      .trim();
    enchants.push({ suffix, chance, statsText });
  }
  return enchants;
}

if (process.argv[1]?.includes("parse-wh-random-enchants")) {
  const id = process.argv[2] || "9640";
  const era = process.argv[3] || "classic";
  const url = `https://www.wowhead.com/${era}/item=${id}/random-enchants`;
  const r = await fetch(url, { headers: { "User-Agent": "GearQuestForever-data/1.0" } });
  const html = await r.text();
  const rows = parseRandomEnchantsFromHtml(html);
  console.log(JSON.stringify(rows, null, 2));
  console.log("count", rows.length, "chance sum", rows.reduce((s, x) => s + x.chance, 0).toFixed(2));
}
