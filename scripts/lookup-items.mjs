const items = [
  "Skyshatter Headguard",
  "Cowl of the Illidari High Lord",
  "Cyclone Faceguard",
  "Skyshatter Mantle",
  "Mantle of Nimble Thought",
  "Hatefury Mantle",
  "Cloak of the Illidari Council",
  "Brute Cloak of the Ogre-Magi",
  "Skyshatter Breastplate",
  "Chestguard of Relentless Storms",
  "Cataclysm Chestpiece",
  "Bracers of Nimble Thought",
  "Cuffs of Devastation",
  "Bands of the Coming Storm",
  "Skyshatter Gauntlets",
  "Botanist's Gloves of Growth",
  "Spiritwalker Gauntlets",
  "Flashfire Girdle",
  "Waistwrap of Infinity",
  "Belt of Blasting",
  "Leggings of Channeled Elements",
  "Skyshatter Legguards",
  "Cataclysm Legguards",
  "Slippers of the Seacaller",
  "Naturewarden's Treads",
  "Boots of Oceanic Fury",
  "The Sun King's Talisman",
  "Translucent Spellthread Necklace",
  "Ring of Ancient Knowledge",
  "Band of the Eternal Sage",
  "Ring of Captured Storms",
  "The Skull of Gul'dan",
  "The Lightning Capacitor",
  "Icon of the Silver Crescent",
  "Zhar'doom, Greatstaff of the Devourer",
  "The Maelstrom's Fury",
  "Vengeful Gladiator's Gavel",
  "Antonidas's Aegis of Rapt Concentration",
  "Chronicle of Dark Secrets",
  "Fathomstone",
  "Totem of Ancestral Guidance",
  "Totem of the Void",
];

async function search(name) {
  const url = "https://www.wowhead.com/tbc/search?q=" + encodeURIComponent(name);
  const r = await fetch(url, { headers: { "User-Agent": "Mozilla/5.0" } });
  const t = await r.text();
  const m = t.match(/item=(\d+)/);
  return { name, id: m ? m[1] : null };
}

for (const name of items) {
  const res = await search(name);
  console.log(`${res.id ?? "MISSING"}\t${name}`);
  await new Promise((r) => setTimeout(r, 250));
}
