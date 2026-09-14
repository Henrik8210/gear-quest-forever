const items = [
  [31014, "Skyshatter Headguard", "vendor"],
  [32525, "Cowl of the Illidari High Lord", "boss"],
  [29035, "Cyclone Faceguard", "vendor"],
  [31023, "Skyshatter Mantle", "vendor"],
  [32587, "Mantle of Nimble Thought", "profession"],
  [30884, "Hatefury Mantle", "boss"],
  [32331, "Cloak of the Illidari Council", "boss"],
  [28797, "Brute Cloak of the Ogre-Magi", "boss"],
  [31017, "Skyshatter Breastplate", "vendor"],
  [32592, "Chestguard of Relentless Storms", "raid_trash"],
  [30169, "Cataclysm Chestpiece", "vendor"],
  [32586, "Bracers of Nimble Thought", "profession"],
  [30870, "Cuffs of Devastation", "boss"],
  [32259, "Bands of the Coming Storm", "boss"],
  [31008, "Skyshatter Gauntlets", "vendor"],
  [32328, "Botanist's Gloves of Growth", "boss"],
  [32275, "Spiritwalker Gauntlets", "boss"],
  [32276, "Flashfire Girdle", "boss"],
  [32256, "Waistwrap of Infinity", "boss"],
  [30038, "Belt of Blasting", "profession"],
  [30916, "Leggings of Channeled Elements", "boss"],
  [31020, "Skyshatter Legguards", "vendor"],
  [30167, "Cataclysm Legguards", "vendor"],
  [32239, "Slippers of the Seacaller", "boss"],
  [32352, "Naturewarden's Treads", "boss"],
  [32242, "Boots of Oceanic Fury", "boss"],
  [30015, "The Sun King's Talisman", "quest"],
  [32349, "Translucent Spellthread Necklace", "boss"],
  [32527, "Ring of Ancient Knowledge", "raid_trash"],
  [29305, "Band of the Eternal Sage", "vendor"],
  [32247, "Ring of Captured Storms", "boss"],
  [32483, "The Skull of Gul'dan", "boss"],
  [28785, "The Lightning Capacitor", "boss"],
  [29370, "Icon of the Silver Crescent", "vendor"],
  [32374, "Zhar'doom, Greatstaff of the Devourer", "boss"],
  [32237, "The Maelstrom's Fury", "boss"],
  [33687, "Vengeful Gladiator's Gavel", "vendor"],
  [30909, "Antonidas's Aegis of Rapt Concentration", "boss"],
  [30872, "Chronicle of Dark Secrets", "boss"],
  [30049, "Fathomstone", "boss"],
  [32330, "Totem of Ancestral Guidance", "boss"],
  [28248, "Totem of the Void", "boss"],
];

function parseTooltip(tooltip) {
  const text = tooltip.replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim();
  const drop = text.match(/Dropped by: ([^.]+)/);
  const sold = text.match(/Sold by: ([^.]+)/);
  const classes = text.match(/Classes: ([^.]+?) Requires/);
  const slotArmor = text.match(
    / (Head|Shoulder|Chest|Wrist|Hands|Waist|Legs|Feet|Back|Neck|Finger|Trinket|Relic|Totem|Main Hand|Off Hand|Two-Hand|Staff|Mail|Cloth|Leather|Plate) /
  );
  return {
    drop: drop?.[1]?.replace(/ Drop Chance:.*/, "")?.trim(),
    sold: sold?.[1]?.trim(),
    classes: classes?.[1]?.trim(),
    slotArmor: slotArmor?.[1],
    text,
  };
}

const results = [];
for (const [id, expected, kind] of items) {
  const r = await fetch(`https://nether.wowhead.com/tbc/tooltip/item/${id}?dataEnv=8&locale=0`);
  const j = await r.json();
  const info = parseTooltip(j.tooltip || "");
  results.push({
    id,
    expected,
    actual: j.name,
    kind,
    drop: info.drop || null,
    sold: info.sold || null,
    nameOk: j.name?.toLowerCase() === expected.toLowerCase(),
  });
  await new Promise((resolve) => setTimeout(resolve, 120));
}

console.log(JSON.stringify(results, null, 2));
