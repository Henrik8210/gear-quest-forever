# GearQuest Forever

**GearQuest Forever** (`/gq`) is the WoW Forever fork of GearQuest. It answers: *"What should I upgrade next, and how do I get it?"*

This is a **new repo and a new CurseForge project**. The TBC Anniversary addon stays at [Henrik8210/gear-quest](https://github.com/Henrik8210/gear-quest). Do not copy that project's CurseForge ID or GitHub `CF_API_KEY` secret into this repo.

Click a gear slot on your character panel (right-click), browse from the log, or click the minimap icon to open GearQuest.

## WoW Forever beta (17 September 2026)

Forever is a new 1–60 Classic+ client (original continents, before Molten Core). TOC interface is **16001** (CurseForge game version **1.60.1**). After you launch the client, confirm `lastAddonVersion` in:

   `World of Warcraft\<forever-folder>\WTF\Config.wtf`

Install folder is expected to be something like `_forever_` beside `_anniversary_`. `scripts/sync-addon.ps1` looks for a few likely names, or set `$env:GEARQUEST_WOW_CLIENT`.

Current BiS data is still largely the Classic/TBC **leveling** snapshot from GearQuest (generated 10–69, curated 1–9 Alliance bands). **Max level is 60** — TBC level-70 endgame lists were removed. Forever has new quests, races, and item tweaks; see [docs/FOREVER-DATA-MIGRATION.md](docs/FOREVER-DATA-MIGRATION.md) for the data pass plan after beta.

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

**Minimap:** any click opens GearQuest. Use the **Simulator** handle tab (class, faction, spec, level 1–60). Reset = `/gq set me`.

## Local WoW install

After editing addon files, sync to your game folder. The install folder is **`GearQuestForever`** (TBC Anniversary uses **`GearQuest`** — same repo name, different products).

```powershell
.\scripts\sync-addon.ps1
```

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
