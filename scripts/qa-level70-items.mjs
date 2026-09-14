const items = [
  [31014, "Skyshatter Headguard"],
  [32525, "Cowl of the Illidari High Lord"],
  [29035, "Cyclone Faceguard"],
  [31023, "Skyshatter Mantle"],
  [32587, "Mantle of Nimble Thought"],
  [30884, "Hatefury Mantle"],
  [32331, "Cloak of the Illidari Council"],
  [28797, "Brute Cloak of the Ogre-Magi"],
  [31017, "Skyshatter Breastplate"],
  [32592, "Chestguard of Relentless Storms"],
  [30169, "Cataclysm Chestpiece"],
  [32586, "Bracers of Nimble Thought"],
  [30870, "Cuffs of Devastation"],
  [32259, "Bands of the Coming Storm"],
  [31008, "Skyshatter Gauntlets"],
  [32328, "Botanist's Gloves of Growth"],
  [32275, "Spiritwalker Gauntlets"],
  [32276, "Flashfire Girdle"],
  [32256, "Waistwrap of Infinity"],
  [30038, "Belt of Blasting"],
  [30916, "Leggings of Channeled Elements"],
  [31020, "Skyshatter Legguards"],
  [30167, "Cataclysm Legguards"],
  [32239, "Slippers of the Seacaller"],
  [32352, "Naturewarden's Treads"],
  [32242, "Boots of Oceanic Fury"],
  [30015, "The Sun King's Talisman"],
  [32349, "Translucent Spellthread Necklace"],
  [32527, "Ring of Ancient Knowledge"],
  [29305, "Band of the Eternal Sage"],
  [32247, "Ring of Captured Storms"],
  [32483, "The Skull of Gul'dan"],
  [28785, "The Lightning Capacitor"],
  [29370, "Icon of the Silver Crescent"],
  [32374, "Zhar'doom, Greatstaff of the Devourer"],
  [32237, "The Maelstrom's Fury"],
  [33687, "Vengeful Gladiator's Gavel"],
  [30909, "Antonidas's Aegis of Rapt Concentration"],
  [30872, "Chronicle of Dark Secrets"],
  [30049, "Fathomstone"],
  [32330, "Totem of Ancestral Guidance"],
  [28248, "Totem of the Void"],
];

function parseTooltip(tooltip) {
  const text = tooltip.replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim();
  const drop = text.match(/Dropped by: ([^.]+)/);
  const sold = text.match(/Sold by: ([^.]+)/);
  const classes = text.match(/Classes: ([^.]+)/);
  return { text, drop: drop?.[1]?.trim(), sold: sold?.[1]?.trim(), classes: classes?.[1]?.trim() };
}

for (const [id, expected] of items) {
  const r = await fetch(`https://nether.wowhead.com/tbc/tooltip/item/${id}?dataEnv=8&locale=0`);
  const j = await r.json();
  const info = parseTooltip(j.tooltip || "");
  const ok = j.name?.toLowerCase() === expected.toLowerCase();
  console.log(
    [
      ok ? "OK" : "NAME!",
      id,
      j.name,
      info.drop ? `drop=${info.drop}` : "",
      info.sold ? `sold=${info.sold}` : "",
      info.classes ? `classes=${info.classes}` : "",
    ]
      .filter(Boolean)
      .join("\t")
  );
  await new Promise((resolve) => setTimeout(resolve, 150));
}
