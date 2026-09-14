// Cross-check Data.lua boss NPCs against Wowhead tooltip drops for level-70 ele shaman.
const expected = {
  32525: "Illidan Stormrage",
  30884: "Anetheron",
  32331: "High Nethermancer Zerevor",
  28797: "High King Maulgar",
  30870: "Rage Winterchill",
  32259: "Supremus",
  32328: "Teron Gorefiend",
  32275: "Shade of Akama",
  32276: "Shade of Akama",
  32256: "Supremus",
  30916: "Kaz'rogal",
  32239: "High Warlord Naj'entus",
  32352: "Essence of Anger",
  32242: "High Warlord Naj'entus",
  32349: "Essence of Anger",
  32247: "High Warlord Naj'entus",
  32483: "Illidan Stormrage",
  28785: "Terestian Illhoof",
  32374: "Illidan Stormrage",
  32237: "High Warlord Naj'entus",
  30909: "Archimonde",
  30872: "Rage Winterchill",
  30049: "Hydross the Unstable",
  32330: "Teron Gorefiend",
};

// T6 token bosses (Protector set — shaman): Archimonde, Mother Shahraz, Illidan, Azgalor, Illidari Council
const t6Tokens = {
  head: { boss: "Archimonde", zone: "Hyjal Summit", tokenId: 31095 },
  shoulder: { boss: "Mother Shahraz", zone: "Black Temple", tokenId: 31103 },
  chest: { boss: "Illidan Stormrage", zone: "Black Temple", tokenId: 31091 },
  hands: { boss: "Azgalor", zone: "Hyjal Summit", tokenId: 31094 },
  legs: { boss: null, zone: "Black Temple", tokenId: 31100 }, // Illidari Council — not in tooltip API
};

// T5 token bosses (Defender set — shaman)
const t5Tokens = {
  head: { boss: "Lady Vashj", tokenId: 30243 },
  chest: { boss: "Kael'thas Sunstrider", tokenId: 30237 },
  legs: { boss: "Fathom-Lord Karathress", tokenId: 30246 },
};

let mismatches = 0;
for (const [id, expBoss] of Object.entries(expected)) {
  const r = await fetch(`https://nether.wowhead.com/tbc/tooltip/item/${id}?dataEnv=8&locale=0`);
  const j = await r.json();
  const text = (j.tooltip || "").replace(/<[^>]+>/g, " ").replace(/\s+/g, " ");
  const drop = text.match(/Dropped by: ([^.]+)/);
  const actual = drop?.[1]?.replace(/ Drop Chance:.*/, "")?.trim();
  const ok = actual === expBoss;
  if (!ok) {
    mismatches++;
    console.log(`MISMATCH ${id} ${j.name}: expected ${expBoss}, wowhead ${actual || "?"}`);
  }
  await new Promise((r) => setTimeout(r, 120));
}
for (const [slot, info] of Object.entries({ ...t6Tokens, ...t5Tokens })) {
  if (!info.tokenId || !info.boss) continue;
  const r = await fetch(`https://nether.wowhead.com/tbc/tooltip/item/${info.tokenId}?dataEnv=8&locale=0`);
  const j = await r.json();
  const text = (j.tooltip || "").replace(/<[^>]+>/g, " ").replace(/\s+/g, " ");
  const drop = text.match(/Dropped by: ([^.]+)/)?.[1]?.replace(/ Drop Chance:.*/, "")?.trim();
  if (drop && drop !== info.boss) {
    mismatches++;
    console.log(`TOKEN MISMATCH ${slot} ${j.name}: expected ${info.boss}, wowhead ${drop}`);
  }
  await new Promise((r) => setTimeout(r, 120));
}
console.log(mismatches === 0 ? "All boss drops verified." : `${mismatches} mismatches.`);
