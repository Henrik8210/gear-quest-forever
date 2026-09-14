# GearQuest Forever

**GearQuest Forever** (`/gq`) is the WoW Forever fork of GearQuest. It answers: *"What should I upgrade next, and how do I get it?"*

This is a **new repo and a new CurseForge project**. The TBC Anniversary addon stays at [Henrik8210/gear-quest](https://github.com/Henrik8210/gear-quest). Do not copy that project's CurseForge ID or GitHub `CF_API_KEY` secret into this repo.

Click a gear slot on your character panel (right-click), browse from the log, or **right-click the minimap icon** to simulate another class/level/spec.

## WoW Forever beta (17 September 2026)

Forever is a new 1–60 Classic+ client (original continents, before Molten Core). The beta client is not on this machine yet, so two values are placeholders until first login:

1. **`## Interface:`** in `GearQuest/GearQuest.toc` is currently `11507` (closest public 1–60 interface). After you launch the beta once, copy `lastAddonVersion` from:

   `World of Warcraft\<forever-folder>\WTF\Config.wtf`

2. **Install folder** is expected to be something like `_forever_` beside `_anniversary_`. `scripts/sync-addon.ps1` looks for a few likely names, or set `$env:GEARQUEST_WOW_CLIENT`.

Current BiS data is the Classic/TBC leveling snapshot from GearQuest. Forever has new quests, races, and stories — rankings will need a Forever pass after beta. Level 70 TBC lists will not apply.

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
| `/gq set me` | Copy your real character into preview (Reset in simulate panel) |
| `/gq help` | List commands |

**Minimap:** left-click → log; right-click → simulate panel (class, spec, level).

## Local WoW install

After editing addon files, sync to your game folder:

```powershell
.\scripts\sync-addon.ps1
```

## Development

- Addon lives in `GearQuest/` (folder matches toc name for CurseForge packager)
- In-game title: **GearQuest Forever**
- Interface placeholder: `## Interface: 11507` — update from the beta client
- Project brief: [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md)
- Data rules: [docs/DATA_RULES.md](docs/DATA_RULES.md)
- Changelog: [CHANGELOG.md](CHANGELOG.md)
- CurseForge: [RELEASE.md](RELEASE.md)

## CurseForge

Create a **new** project on [authors.curseforge.com](https://authors.curseforge.com/) for GearQuest Forever, then follow [RELEASE.md](RELEASE.md). The TBC project ID `1669225` must not appear in this toc.

## License

See repository license file when added.
