# GearQuest Forever

**GearQuest Forever** (`/gq`) is the WoW Forever fork of GearQuest. It answers: *"What should I upgrade next, and how do I get it?"*

This is a **new repo and a new CurseForge project**. The TBC Anniversary addon stays at [Henrik8210/gear-quest](https://github.com/Henrik8210/gear-quest). Do not copy that project's CurseForge ID or GitHub `CF_API_KEY` secret into this repo.

Click a gear slot on your character panel (right-click), browse from the log, or click the minimap icon to open GearQuest.

## WoW Forever beta (17 September 2026)

Forever is a new 1–60 Classic+ client (original continents, before Molten Core). TOC interface is **16001** (CurseForge game version **1.60.1**). After you launch the client, confirm `lastAddonVersion` in:

   `World of Warcraft\<forever-folder>\WTF\Config.wtf`

Install folder is `_classic_beta_` (Forever beta). `scripts/sync-addon.ps1` looks for that first, then a few other likely names, or set `$env:GEARQUEST_WOW_CLIENT`.

Lists are the Forever scoring model for all nine classes, levels 1–60. Alliance paladin and warrior levels 1–9 stay curated. Scoring rules: [pipeline/docs/FOREVER-SCORING.md](pipeline/docs/FOREVER-SCORING.md).

**Play style** sits at the bottom of the log. Five cards, names under the pictures, three then two. **No Dungeons!** hides hunts that send you into a dungeon or raid, including a quest that enters one. A world drop stays even when its zone is a dungeon name. World bosses and crafts you can buy stay. **Dungeon Enjoyer** keeps only those dungeon and raid hunts. The two turn each other off. **Get it now!** hides a hunt until this character meets the reputation on that item, or can make a bind-on-pickup craft. A bind-on-equip craft stays unless the item itself requires the profession to wear. **Don't look back** hides a hunt once its required level would be a gray quest. **Buy it** keeps vendor pieces and anything that is not bind on pickup, unless a vendor sells that bind-on-pickup piece. Get it now, Don't look back, and Buy it can be on with either dungeon card.

The source **Filter** is alphabetical. Profession, Boss drop, and Dungeon & Raid trash each open a flyout when checked. The trash boxes are separate from Boss drop. Select all / Deselect all covers the sources and all three flyouts. A filter or a play style fills a slot back up to three matching hunts, then keeps the notable when that notable still fits.

The parchment shows **Rank #N** in a black box above the item name. That number is the slot rank, so a filtered list still shows the real place. Hovering the box says best, 2nd, 3rd, or 4th, and why a later rank is on the list.

The green upgrade arrow stays on the unfiltered best pieces when a filter or a play style hides them, and on every hunt still showing. The obtain toast follows the unfiltered top three, the notable, and any hunt you Track. A filter does not stop a tracked toast.

A crafted hunt lists the recipe materials, and the skill line just before Source. That clause is green when you meet the recipe and red when you are short or do not have the profession.

## Commands

| Command | Action |
|---------|--------|
| `/gq` or `/gearquest` | Toggle GearQuest log |
| `/gq log` | Toggle log |
| `/gq class hunter` | Set preview class |
| `/gq level 37` | Set preview level |
| `/gq spec holy` | Set preview specialization |
| `/gq faction alliance` | Set preview faction |
| `/gq set on` / `/gq set off` | Enable or disable preview mode |
| `/gq set me` | Copy your real character into preview (Reset on the Simulator tab) |
| `/gq help` | List commands |
| `/gq seen` | The seen-item notebook is retired. Item facts come from Wowhead Forever. |

**Minimap:** any click opens GearQuest. Use the **Simulator** handle tab (class, faction, spec, level 1–60). Reset = `/gq set me`.

## Local WoW install

After **every** edit under `GearQuest/` (Lua, `_generated/`, art), sync to your game folder — the repo is not what WoW loads until you do. The install folder is **`GearQuestForever`** (TBC Anniversary uses **`GearQuest`** — same repo name, different products).

```powershell
.\scripts\sync-addon.ps1
```

The log shows a line under the **GearQuest** title: **simulation mode** (level, spec, class, faction) or **live character** + spec picker hint.

No Forever client yet? You can still sync beside TBC GearQuest on Anniversary for rough UI testing (enable **Load out of date AddOns**):

```powershell
$env:GEARQUEST_WOW_CLIENT = "_anniversary_"
.\scripts\sync-addon.ps1
```

## Development

- Source in repo: `GearQuest/`; game folder / CurseForge package: **`GearQuestForever`** (`GearQuestForever.toc`)
- In-game title: **GearQuest Forever**
- Interface: `## Interface: 16001` (CurseForge **WoW Forever 1.60.1**)
- Project brief: [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md)
- Data rules: [docs/DATA_RULES.md](docs/DATA_RULES.md)
- Changelog: [CHANGELOG.md](CHANGELOG.md)
- BiS scorer (authors only, not in CurseForge zip): [pipeline/README.md](pipeline/README.md) — adding Forever beta items: [pipeline/docs/FOREVER-SCORING.md](pipeline/docs/FOREVER-SCORING.md)
- CurseForge: [RELEASE.md](RELEASE.md)

## CurseForge

CurseForge project **1698950** (`## X-Curse-Project-ID: 1698950`). Follow [RELEASE.md](RELEASE.md). Never use TBC GearQuest `1669225`.

## License

See repository license file when added.
