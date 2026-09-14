/** Parse Wowhead random-enchant stat lines into normalized stat totals (midpoint of ranges). */
const STAT_PATTERNS = [
  { key: "str", re: /\+\(?(\d+)\s*-\s*(\d+)\)?\s*Strength|\+(\d+)\s*Strength/gi },
  { key: "agi", re: /\+\(?(\d+)\s*-\s*(\d+)\)?\s*Agility|\+(\d+)\s*Agility/gi },
  { key: "sta", re: /\+\(?(\d+)\s*-\s*(\d+)\)?\s*Stamina|\+(\d+)\s*Stamina/gi },
  { key: "int", re: /\+\(?(\d+)\s*-\s*(\d+)\)?\s*Intellect|\+(\d+)\s*Intellect/gi },
  { key: "spi", re: /\+\(?(\d+)\s*-\s*(\d+)\)?\s*Spirit|\+(\d+)\s*Spirit/gi },
  { key: "ap", re: /\+(\d+)\s*Attack Power/gi },
  { key: "heal", re: /\+(\d+)\s*Healing Spells/gi },
  { key: "sp", re: /\+(\d+)\s*Spell Damage|\+(\d+)\s*damage and healing/gi },
];

function readAmount(m) {
  if (m[1] != null && m[2] != null) {
    return (Number(m[1]) + Number(m[2])) / 2;
  }
  return Number(m[3] ?? m[1]);
}

export function parseStatsText(statsText) {
  const stats = {};
  if (!statsText) return stats;
  const text = statsText.replace(/\s+/g, " ");
  for (const { key, re } of STAT_PATTERNS) {
    re.lastIndex = 0;
    let m;
    while ((m = re.exec(text))) {
      stats[key] = (stats[key] || 0) + readAmount(m);
    }
  }
  return stats;
}

export function scoreStats(stats, weights) {
  let total = 0;
  for (const [k, v] of Object.entries(stats)) {
    const w = weights[k];
    if (w && v) total += v * w;
  }
  return total;
}

export function expectedSuffixStatScore(enchants, weights) {
  let sum = 0;
  let mass = 0;
  for (const e of enchants) {
    const p = e.chance / 100;
    sum += p * scoreStats(parseStatsText(e.statsText), weights);
    mass += p;
  }
  if (mass < 0.99) {
    sum += (1 - mass) * 0;
  }
  return sum;
}

export function formatSuffixRange(statsText) {
  if (!statsText) return "";
  return statsText
    .replace(/\s*,\s*/g, ", ")
    .replace(/\+\((\d+)\s*-\s*(\d+)\)/g, "+$1-$2")
    .replace(/\s+/g, " ")
    .trim();
}
