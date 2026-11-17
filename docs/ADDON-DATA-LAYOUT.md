# Addon data layout and memory (for agents)

How GearQuest Forever's generated data gets from the repo into the game, what
the game keeps in memory, and what to check before changing any of it. Read
this before you touch `GearQuest/DataAdapter.lua`, `scripts/stage-class-addons.py`,
`scripts/stage_pack.py`, the main TOC, or any code that looks up hunt entries
by id or by item.

This layout shipped in v1.2.1. The last commit with the old layout is
`ed63083` (v1.2.0). In that layout both factions were expanded at login, the
class files held plain row arrays, item stats loaded at login, and every item
had its own coordinate spot tables.

## Short version

- The repo files under `GearQuest/_generated/` stay readable. The pipeline
  and its checks read those files. Do not hand-edit them into another form.
- Staging writes a compact copy into the WoW AddOns folder or the release zip.
  `scripts/sync-addon.ps1` and `.github/workflows/release.yml` both run
  `scripts/stage-class-addons.py`. Staging packs the class pick rows, moves
  item stats into their own addon, and shares repeated coordinate spots.
  Every packed form is read back and compared with the repo file, and staging
  stops on any difference.
- In game, only the class on screen is expanded, and only for the faction on
  screen. The other faction's rows stay as packed text. Code that needs them
  reads them on demand.
- Hunt ids did not change, so saved progress keeps working.
- Measured Lua heap at login (old layout, then new): Mage 99.8 MB to 50.1 MB,
  Warrior 81.6 MB to 41.5 MB, Priest 68.7 MB to 32.5 MB.

## The addon folders

| Folder (in AddOns or the zip) | Built from | Loads |
|---|---|---|
| `GearQuestForever` | `GearQuest/` copied as is, then staging rewrites `_generated/Data.ForeverAudit.generated.lua` (class tips stripped) and `_generated/Data.Coordinates.generated.lua` (shared spots), and deletes the class files and `Data.ItemStats.generated.lua` from the copy | At login |
| `GearQuestForever_<CLASS>` (9 folders) | `Data.<Class>.generated.lua` and `Data.<Class>.Early.1to9.generated.lua` with packed picks, plus `AuditTips.lua` (that class's Wowhead tooltip text) | Load on demand, when you play or simulate the class (`EnsureClassLoaded`) |
| `GearQuestForever_ItemStats` | `Data.ItemStats.generated.lua`, unchanged except the header | Load on demand, the first time a custom spec is scored (`GQ.Data:EnsureItemStats`) |
| `GearQuestForever_Languages` | `GearQuest/Locales/*` (built by `scripts/stage-locale-addons.py`) | Load on demand, when a language other than English is chosen |

Neither the class files nor `Data.ItemStats.generated.lua` are listed in
`GearQuest/GearQuestForever.toc`. Do not add them back, and do not list the
load-on-demand addons in `## OptionalDeps`. That loads them before `Core.lua`
sets `_G.GearQuest`, every file errors, and the hunt list stays empty.

A staged data file starts with `local GQ = _G.GearQuest` (and errors without
the main addon) instead of the repo's `local _, GQ = ...`. `swap_header` in
the stager does that swap.

The release zip contains `GearQuestForever GearQuestForever_*`, so a new
load-on-demand folder ships without changing the workflow. The release job
runs on plain Python 3 (no lupa), so the stager must stay pure Python.

## What staging does

`python scripts/stage-class-addons.py --dest <AddOns dir> --main <staged GearQuestForever dir>`

1. Splits the Wowhead `tip` text out of the main `foreverAudit` into each
   class's `AuditTips.lua` (older step, unchanged).
2. For each class file, swaps the header, then `stage_pack.pack_class_text`
   replaces `GQ.Data.<class>Picks` or `GQ.Data.<class>Early1to9` with
   `GQ.Data.<name>Packed`. Facts tables are copied unchanged.
3. Writes `GearQuestForever_ItemStats` (file and TOC) and deletes the staged
   main copy of that file.
4. Rewrites the staged coordinate file with shared spots.

It takes about 20 seconds. You can stage into a temporary folder to test
without touching the game:

```powershell
python scripts/stage-class-addons.py --dest $env:TEMP\gq-stage --main $env:TEMP\gq-stage\GearQuestForever
```

### Why staging can fail, and what to do

The packer is strict on purpose. It raises `PackError` (printed as
`stage-class-addons: ...`) on:

- a pick row that is not `{itemId,"slot",min,max,rank,"spec","faction",score[,named...]}`
  with exactly 8 positional values;
- a named field that is not one of `reserve`, `suffix`, `suffixChance`,
  `suffixId`, `suffixRange`, `hand`, `route`, `healOnly`, `origin`;
- more than nine specs in one pick table (the spec mask uses one digit per spec);
- unpacking that does not give back every row, spec mask, and suffix row exactly;
- a coordinate row or spot that does not parse, a spot that holds a nested
  table, or a shared row that does not rebuild to the original line.

If the pipeline adds a new row field, add it to `EXTRA_KEYS` in
`scripts/stage_pack.py` and to `OPTIONAL_ROW_FIELDS` in
`GearQuest/DataAdapter.lua` in the same change. Otherwise staging stops,
which is the intended result.

## The packed pick format

The shape, with sample values:

```lua
GQ.Data.magePicksPacked = {
    slots = {"Back","Chest",...},          -- slot names, 1-based
    specs = {"frost","fire",...},          -- in the order they first appear in the file
    extras = {                             -- each distinct set of named fields, written once
        {suffix="of the Owl",suffixChance=9.5,suffixId=...},
    },
    rows = {
        ["Alliance"] = "itemId slotIx min max rank specIx score extraIx\n...",
        ["Horde"]    = "...",
    },
    specMask = {                           -- which specs list each item, per faction
        ["Alliance"] = "\n2950 13\n...",   -- item 2950 is listed by specs 1 and 3
    },
    suffixRows = "itemId minLevel extraIx\n...",  -- every row with a suffix, both factions, file order
}
```

- `extraIx` 0 means no named fields.
- The score is copied as written, so `tonumber` gives the same double as the
  old literal.
- A row with no faction would go under `"_"`. No current row has one.
- `ReadRows` in `DataAdapter.lua` reads one faction's text with an anchored
  `string.find` pattern, a slice at a time. It still reads a raw row array,
  so an unstaged copy works too, but the raw path is slow for the
  other-faction lookups below. Always test through staging.

### The sort order is load-bearing

The generated files are sorted by spec (in first-appearance order), then
faction (Alliance before Horde), then slot, level, and rank. Lookup relies on
this. `GQ.Data:FileBlockKey(entry)` gives `sourceIndex * 100 + specIndex * 3 +
factionIndex`. Merging the expanded rows and the other faction's rows by that
key gives back the exact old file order. If the emitter ever changes its row
order, update `FileBlockKey` too, or Lookup's item order and slot header will
drift from what they were.

## Runtime flow

### Login

`Core.lua` PLAYER_LOGIN calls `GQ.Data:EnsureActiveHuntClasses()`, then
`BuildIndex()`. `EnsureActiveHuntClasses` loads and expands your class and,
if the Simulator is on, the simulated class. It then drops idle classes and
sets `_huntDataReady`.

`EnsureClassLoaded(classFile)` loads the class addon if needed, then expands
each of the class's two sources (`SOURCES` in `DataAdapter.lua`: picks first,
then Early 1-9) for one faction:

- `HuntFactionFor(classFile)`: for the class on screen, the Simulator faction
  (`GQ:GetEffectiveFaction()`). For your own class while another class is
  simulated, your real faction.
- It records `_expandedClasses[class]`, `_expandedFaction[class]`, and
  `_classEntrySpan[class]`, bumps `_entryGeneration`, builds the suffix
  lookup, and enriches the new entries.
- The packed text stays in memory. Nothing is dropped after expansion, so a
  class can be released and expanded again for the other faction.

### Simulator changes

Every Simulator transition (`Preview:SetEnabled`, `SetClass`, `SetFaction`,
`ApplySimulation`, `ApplyCurrentCharacter`) ends in
`GQ.Data:SyncEffectiveHuntData()`:

1. If the class on screen is expanded for the wrong faction, release it
   (`ReleaseExpandedClass`).
2. Expand the class on screen for the right faction.
3. Release idle classes: anything that is not your class and not the class
   on screen (`ReleaseIdleHuntClasses`). Their addons stay loaded until
   `/reload`, because WoW cannot unload an addon.
4. If `_entryGeneration` changed, run `BuildIndex`, `InvalidateClassCache`,
   and a full garbage collection, then return true.

`ApplySimulation` stores the faction before it calls `SetClass`, so a
simulated class is expanded once, for the right side. `SetFaction` rebuilds
the custom spec on screen when the faction changed. Custom-spec copies are
removed with the rows they came from (`Custom:OnClassReleased`), and
`Custom:EnsureBuilt` scores them again for the expanded rows.

### Entries

Each row becomes one entry table with `id`, `slot`, `minLevel`, `maxLevel`,
`curatedRank`, `pipelineScore`, `specs`, and `factions`. Everything else
(`itemId`, `classes`, `generated`, the item facts, and the named row fields)
comes through a shared metatable (`SharedMetatable`):

- `__index` / `__gqShared` is the shared field table.
- `__gqBase` is the variant without named fields (`CopyEntry` uses it).
- `__gqSource` is the `SOURCES` index the row came from (`FileBlockKey`
  uses it). It is a metatable field, so it is not visible as `entry.__gqSource`.

The id is unchanged from v1.2.0:
`gen:<class lower>:<itemId>:<slot>:<minLevel>:<spec>:<faction>`. A custom-spec
copy adds `:<customSpecId>`.

## Code that reads the other faction

Only one faction is in `GQ.Data.entries`, `byId`, and `byItemId`. These read
the other faction's packed rows, so behavior matches the old layout:

| Function (`DataAdapter.lua` unless noted) | Used by | What it gives |
|---|---|---|
| `OtherFactionReader(class)` | Lookup index build (`Log.lua`) | A stepping reader: `read(limit, out)` appends up to `limit` new entries and returns true when done |
| `HoldDetachedEntries(list)` / `ReleaseDetachedEntries()` | Lookup | Makes Lookup's other-faction entries findable by `GetEntryById` (`Data.lua`) while the Lookup index exists, so Track works from Lookup |
| `UnexpandedRowSpecs(itemId)` | `GearScoreMissText`, `LinkIsGear` (`Data.lua`) | `{ [CLASS] = { [spec] = true, _any = true? } }` from the spec masks, so the tooltip still says Not ranked for your faction |
| `UnexpandedItemEntries(itemId)` | `Log:UntrackHunt` on the Completed tab | Fresh entries for that item's other-faction rows, so dismissing a completed hunt dismisses those ids too |
| `IsUnexpandedHuntId(id)` | Completed prune, `Log:IsItemIdObtained` | True for a saved id of a loaded class whose faction is not expanded |
| `FileBlockKey(entry)`, `SpecFileOrder(src)` | Lookup merge | The file-order key described above |

Everything else filters to the player's faction already (`EntryMatchesPlayer`,
`EntryMatchesPlayerBand`, `EntryMatchesTrackedHunt`, the tracker), so it only
ever used the expanded faction anyway. If you add code that walks
`GetEntriesByItemId` or `GetEntryById` and must see both factions, use one of
the functions above. Do not expand both factions again.

### Lookup

`Log:EnsureLookupIndex(class)` builds the index in slices of 2000 rows per frame:

1. Read the whole other faction through `OtherFactionReader`.
2. Walk the expanded span (`_classEntrySpan`) and the other-faction list
   together, taking whichever entry has the lower `FileBlockKey`, and index
   each one (`Log:AddLookupIndexEntry`).
3. `FinishLookupIndex` holds the other-faction entries for `GetEntryById`.

The index rebuilds when `_entryGeneration` changes. `ReleaseLookupIndex`
(leaving the tab) drops the index and the held entries. While the Lookup tab
is open, the other faction costs about as much memory as the expanded faction
(about 34 MB for Mage).

### Saved progress

- The Completed-tab prune (`_prunedStaleObtained`, once a session) deletes a
  saved id only when `GetEntryById` misses it and `IsUnexpandedHuntId` is
  false. It also waits while a custom spec is still scoring
  (`GQ.Custom._job`), because those ids have no rows yet.
- `IsItemIdObtained` reads the item id from the third field of an
  other-faction saved id.
- The tracker and the Completed tab show only entries for the faction on
  screen, the same as before.

## Coordinates

The repo `Data.Coordinates.generated.lua` stays one spot list per item.
`index_coordinates.py --ids` keeps patching that file, and nothing about the
pipeline changes.

The staged copy writes each distinct spot once (`local S = {...}`) and each
distinct spot list once (`local P = {{S[1],S[7]},...}`). A row then says
`spots=P[n]`. Currently 7,415 items share 14,841 spots and 2,958 lists
(18.8 MB to 6.0 MB). `check_coordinates` rebuilds every original row line
from the staged file and stops staging on any difference.

Because spots are shared, nothing may write into a spot or a spot list at
runtime. Every current reader is read-only: `VisibleCoordinateSpots` returns
a new list, `SameCoordinateSpot` compares by content, Map's `SpotForEntry`
copies, and Guide only compares identity to decide on a refresh. Do not
intern or deduplicate coordinates at runtime. That was tried once and
removed after world-drop pins looked gone.

## Item stats for custom specs

`GQ.Data.itemStats` and `GQ.Data.itemRolls` are read only by `CustomSpec.lua`
(`Prepare`, `Consume`, `ScorePiece`). `Custom:Prepare` calls
`GQ.Data:EnsureItemStats()` first. That loads `GearQuestForever_ItemStats`. If
the addon is missing or disabled, it prints the translated chat line
`could not load the item stats for custom specs (%s)...` once and the custom
spec is not scored. The file is still written by
`pipeline/scripts/emit_item_stats.py` into `GearQuest/_generated/`.

## Checklist before you change this area

1. Stage into a temporary folder (command above). It must finish without a
   `stage-class-addons:` error.
2. Compile every changed Lua file under Lua 5.1 (lupa `lua51` is installed:
   `loadstring` each file). Log.lua is close to the 200 file-scope local
   limit (about 190; this layout change added none). Add methods on `GQ.Log`
   or `GQ.Data` instead of new file-level locals.
3. For a change to expansion, packing, or the other-faction readers, compare
   against the old adapter. In a lupa `lua51` runtime with stubs for
   `UnitClass`, `UnitFactionGroup`, `GQ:GetEffectiveClass`,
   `GQ:GetEffectiveFaction`, `C_AddOns`, `GQ.Data:IsForeverMissing`, and
   `GQ.Data:EnrichBossChestEntry`:
   - load the repo class files and `git show ed63083:GearQuest/DataAdapter.lua`,
     call `EnsureClassLoaded`, and serialize every entry, raw fields plus
     `getmetatable(e).__gqShared`;
   - load the staged class files and the working `DataAdapter.lua` for each
     faction, and compare the expanded entries with the old entries of that
     faction, in order;
   - compare `OtherFactionReader` output with the old entries of the other
     faction, and the Lookup merge order with the old entry order.
   The v1.2.0 to packed change passed all of this for all nine classes, both
   factions, packed and raw, with zero differences.
4. Run `scripts/sync-addon.ps1`, `/reload`, and check in game:
   - the hunt list;
   - the Simulator on the other faction and another class, then turning it off;
   - Lookup, including Track from Lookup;
   - a custom spec scoring (Item Stats loads);
   - the world map pins.

## Do not

- Do not expand both factions, or keep the other faction's entries outside
  the Lookup tab.
- Do not change the hunt id format. Saved progress is keyed by it.
- Do not drop the packed text after expansion. A faction switch and Lookup
  read it again.
- Do not hand-edit staged files or commit them. They are rebuilt on every sync.
- Do not add class files, `Data.ItemStats.generated.lua`, or the
  load-on-demand addons to the main TOC or `## OptionalDeps`.
- Do not write into coordinate spots at runtime, and do not intern them at runtime.
- Do not loosen `stage_pack.py`'s checks to get past an error. Fix the row
  shape or extend both field lists.
