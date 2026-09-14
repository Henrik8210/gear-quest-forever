# Follow-up: re-import four data files (no addon code change)

The bug I found after you imported was in **my generator, not in the addon**. There is
nothing to fix in `DataAdapter.lua`, `Data.lua`, the `.toc` or any UI code. The fix is
data: replace four generated files and re-run the counts.

## What was wrong

Classic PvP rank rewards are faction-exclusive, but **the item rows do not say so** —
every one carries `AllowableRace = -1`. The restriction lived on the quartermaster
(Sergeant Major Clate for Alliance, First Sergeant Hola'mahi for Horde), one join away
from the item. So the generator emitted both halves of every rank-set pair to **both**
factions. 14 name families were affected, including:

| Alliance item | Horde item | both were emitted for both factions |
|---|---|---|
| Field Marshal's Plate Helm (16478) | Warlord's Plate Headpiece (16542) | yes |
| Field Marshal's Plate Armor (16477) | Warlord's Plate Armor (16541) | yes |
| Marshal's Plate Legguards (16479) | General's Plate Leggings (16543) | yes |
| Marshal's Plate Boots (16483) | General's Plate Boots (16545) | yes |
| Grand Marshal's Aegis (18825) | High Warlord's Shield Wall (18826) | yes |

## Do I already have the fix?

Run this against the loaded data. It needs no game client — a Lua REPL or an in-game
`/dump` both work.

```lua
-- Expect exactly: 16478 -> Alliance, 16542 -> Horde
local function factionsOf(itemId)
    local seen = {}
    for _, e in ipairs(GQ.Data.entries) do
        if e.itemId == itemId and e.factions then
            for f in pairs(e.factions) do seen[f] = true end
        end
    end
    local out = {}
    for f in pairs(seen) do out[#out+1] = f end
    table.sort(out)
    return table.concat(out, ",")
end
print("16478 Field Marshal's Plate Helm ->", factionsOf(16478))
print("16542 Warlord's Plate Headpiece  ->", factionsOf(16542))
```

- `Alliance` and `Horde` respectively — you already have the fixed data, stop here.
- Either one printing `Alliance,Horde` — you have the old data. Re-import.

## Re-import

From the newest `GearQuest-Warrior-BiS.zip`, overwrite in place. Same filenames, same
table names, same load order — a pure file swap:

- `Data.Warrior.generated.lua` → 9,582 picks
- `Data.Warrior.Horde.1to9.generated.lua` → 248 picks
- `Data.Paladin.generated.lua` → 9,180 picks (paladin leaked too: 252 cells, 13 at level 60)
- `Data.Paladin.Horde.1to9.generated.lua` → 221 picks

Then re-verify:

- `#GQ.Data.entries` == **20,410** (1,179 curated + 19,231 generated). It was 20,389
  before this fix, so a stale 20,389 means a file did not get replaced.
- Zero duplicate `id` values.
- The two `factionsOf` lines above return one faction each.

## Worth adding as a permanent regression test

This class of bug is invisible unless something checks for it, and it will recur for
every class that has PvP rank gear — which is all of them. A test over these id pairs
asserting "no entry offers both halves to the same faction" is cheap and would have
caught it:

```lua
local PVP_PAIRS = {
    {16478, 16542}, {16477, 16541}, {16479, 16543},
    {16483, 16545}, {18825, 18826},
}
```

Alliance side of each pair first. For every pair, the two ids must never share a
faction.
