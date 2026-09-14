const ids = [32527, 30015, 28248, 32328];

for (const id of ids) {
  const r = await fetch(`https://nether.wowhead.com/tbc/tooltip/item/${id}?dataEnv=8&locale=0`);
  const j = await r.json();
  const text = (j.tooltip || "").replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim();
  const drop = text.match(/Dropped by: ([^.]+)/);
  console.log(`${id} ${j.name}`);
  console.log(drop ? `  drop: ${drop[1]}` : "  drop: (none in tooltip)");
  console.log(`  snippet: ${text.slice(0, 180)}`);
  await new Promise((r) => setTimeout(r, 150));
}
