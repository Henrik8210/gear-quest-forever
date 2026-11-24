# CurseForge release (GearQuest Forever)

This repo is a **new CurseForge project**. Do not reuse the TBC Anniversary GearQuest project ID, GitHub secrets, or webhook.

Publishing uses **GitHub Actions**, not the CurseForge webhook. Keep any CurseForge GitHub webhook **inactive**.

## One-time setup

1. **Create a new CurseForge project** at [authors.curseforge.com](https://authors.curseforge.com/) named **GearQuest Forever** (WoW Forever / Classic+). Do not attach it to the existing TBC GearQuest project. **Done:** [project 1698950](https://authors.curseforge.com/#/projects/1698950).
2. Copy the **Project ID** from CurseForge → Overview → paste into `GearQuest/GearQuestForever.toc` as `## X-Curse-Project-ID:`. **Done:** `1698950` (not TBC `1669225`).
3. **API token:** [authors.curseforge.com → API tokens](https://authors.curseforge.com/#/settings/api-tokens) → create a token (or reuse your author token — it is account-level, not project-level).
4. **GitHub secret:** this repo → Settings → Secrets and variables → Actions → New repository secret:
   - Name: `CF_API_KEY`
   - Value: your CurseForge API token. **Done** on `gear-quest-forever` (do not copy the TBC repo secret).
5. **CurseForge Source (optional):** Link this GitHub repo for metadata only. Uploads come from Actions.
6. TOC `## Interface:` is **16001** for CurseForge **WoW Forever 1.60.1**. Confirm `lastAddonVersion` in `_forever_\WTF\Config.wtf` after first login. Local sync is only `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns`.

## Release steps

Only when explicitly publishing:

1. Bump `## Version:` in `GearQuest/GearQuestForever.toc` and `GearQuest/Core.lua` (`GQ.VERSION`) to **`X.Y.Z`** (the current release is `1.3.5`). The language addon version comes from that same TOC line when `scripts/stage-locale-addons.py` runs. The release workflow runs that stager, so a new player-facing sentence is already in `GearQuest/Locales/` before the tag. A beta tag is `X.Y.Z-beta` only when that upload should stay on the beta channel. The log window header is **`GearQuest Forever v`** plus `GQ.VERSION` (`GearQuest/Log.lua`, `GearQuestWindowTitle`). It must stay that string — do not hardcode a different version in the header. Bumping `GQ.VERSION` is what updates the band on every release.
2. Add a `## vX.Y.Z` section at the top of `CHANGELOG.md` and demote the previous `## ` heading to `###`. `scripts/upload-curseforge-forever.py` sends markdown from that first `## ` line through the end of the file. Older versions stay as `###` so there is only one level-2 heading. Write the new section for players: a short lead, then a subsection per change, with the classes, specs, levels, and what they will see. A one-line summary is not enough.
3. Commit and push to `main`. Wait for **GitHub Actions → CI** to pass on that commit before tagging (see [Checks](#checks)).
4. Tag and push: `git tag vX.Y.Z` then `git push origin vX.Y.Z`. CurseForge **Files** shows that tag (keep the `v`). A tag that does not end in `-beta` uploads on the **release** channel. A tag that ends in `-beta` uploads on the **beta** channel. `.github/workflows/release.yml` sets `CF_RELEASE_TYPE` from the tag name.
5. Verify **GitHub Actions → Release** succeeds. The job first runs `scripts/ci/check_release.py --tag`, so a tag that does not match the toc version stops before anything is uploaded. It then copies `GearQuest/` as `GearQuestForever`, runs `scripts/stage-class-addons.py` and `scripts/stage-locale-addons.py`, and zips `GearQuestForever` plus every `GearQuestForever_*` folder (the nine classes, `GearQuestForever_ItemStats`, and `GearQuestForever_Languages`). The class stager fails the job if a packed pick table or the shared coordinate file does not read back the same as the repo file. Fix the data, then bump the patch version. Do not retag. Run `scripts/sync-addon.ps1` before tagging, because it runs the same stagers locally. Layout details: [docs/ADDON-DATA-LAYOUT.md](docs/ADDON-DATA-LAYOUT.md).
6. Check CurseForge → **Files** — new file appears as Processing, then Approved.
7. **Discord changelog** — post **only the latest release** to **📖changelog** on the GearQuest server: the top `## vX.Y.Z` block **through the line before the first `### v…` older version** (same player-facing detail as the new CurseForge section, **not** the archived `### v1.2.7` list below it). CurseForge still uploads the **full** `CHANGELOG.md` from that `## ` heading to EOF. Channel id **`1570179420260532315`**. Helper: `python scripts/post_changelog_discord.py` (`--dry-run` to preview). Required on **every** tagged release (release and `-beta`).

## Checks

`.github/workflows/ci.yml` runs on every push to `main` and every pull request, including pull requests from forks (read-only token, no secrets). A fork contributor's first run can wait for **Approve and run** on the pull request. Branch protection on `main` requires the **Addon checks** job before a pull request can merge.

Each step is a script you can run locally after `pip install lupa`:

| Step | Command | What fails it |
| --- | --- | --- |
| Protected files (pull requests only) | `python scripts/ci/check_protected.py --base origin/main` | A weights change (`weights.json`, the generated weight tables, or `weights_at_level()` in `score.py`) without the `weights-change` label; any change under `notebook/seenItems/` |
| Release metadata | `python scripts/ci/check_release.py` | Toc version and `GQ.VERSION` differ; the project id is not 1698950; `CHANGELOG.md` does not have exactly one `## v<version>` heading first; `RELEASE.md` names another current release; the toc lists a missing file |
| Code rules | `python scripts/ci/check_rules.py` | A full `collectgarbage`, a world-map or gamepad call the rules forbid, a new file-scope local in `Log.lua` |
| Translations | `python scripts/ci/check_locales.py` | A `GQ.L` key missing in any of the eight languages, or a language file that loads under another locale |
| Scoring vs tooltip | `python scripts/ci/check_scoring_weights_parity.py` | Spec tooltip or hunt score drifts from the `weights.json` row, or `ScoringWeights.generated.lua` drifts from that file |
| Gear lists | `python scripts/ci/check_gear.py` | Ranks that do not close up, bad or overlapping level bands, a row without facts, a lower rank with a higher score outside the weapon slots (set pieces excepted), a banned or test item, a fishing pole, a non-bow/gun/crossbow on a hunter ranged list, a faction-locked item on the other faction's list, Heavy Woolen Pants leaving the warlock bands they still belong in, a rare or a Both-side quest missing from one faction, a one-faction vendor on the other faction's list, or any other known answer in `scripts/ci/gear_expectations.json` that moved |
| Recommended enchants | `python scripts/ci/check_enchants.py` | A hunt row on an enchantable slot with no `Enchant.lua` formula at that item's level (after ingest, rescrape, or a new slot type) |
| Sheet weights, no level multiplier | `python scripts/ci/check_no_leveling_multipliers.py` | `weights_at_level()` changes a sheet stat, `GQ.ScoringLeveling` is not 1, hunt or enchant code multiplies by that table, or a live doc tells the scorer to multiply stamina, armor, or mana by level |
| Scorer tests | `python -m unittest discover -s tests/pipeline -v` | The sheet-weight identity, `forever_stats`, the jackpot-roll ranking, or the faction-zone gate in `score.py` (a quest, a world drop, and a rare stay available in the other faction's zone; a one-faction vendor, trainer, or quest does not) |
| Log.lua guardrails | `python -m unittest discover -s tests/addon -v` | A doubled `GQ.Log.GQ.Log.` prefix or a missing `GQ.Log` helper export in `Log.lua` |
| Lua 5.1 compile | `python scripts/ci/check_lua.py GearQuest .ci-stage` | A file that does not compile or is not UTF-8, in the source or the staged addons, or a toc entry that does not exist |

A deliberate rescore that moves a known answer updates `scripts/ci/gear_expectations.json` in the same change. An entry with `knownIssue` is reported as a warning and fails once it passes, so the note gets removed.

The lazy catalog comparison (`tests/lazy_catalog/run.py`, about 50 minutes) is not run on every push. Start it from **Actions → CI → Run workflow** with **catalog_suite** checked.

## Rules

- **Never tag** unless explicitly publishing a release.
- **Do not** delete and re-push tags — bump the patch version instead.
- Pushing to `main` alone is **not** a release.
- **Never** copy `X-Curse-Project-ID` from the TBC GearQuest repo.

## Next upload

`v1.0.0` is the first file on the CurseForge **release** channel. `v1.3.5` is the current file on that channel. The next version is the next `X.Y.Z` unless a beta was asked for.

After a tag exists, bump the version rather than deleting the tag.

## Pipeline: open-world drop % (resume optional)

v1.2.5 ships averaged outdoor sample rates for most generic world drops (`build_world_drop_open_chance.py`, `world_drop_open_chance.json`). Resume with **10–15 seconds per Wowhead item page** (`GQ_COORD_DELAY=12`) to fill the remaining ids. Full steps: [pipeline/docs/WORLD-DROP-OPEN-CHANCE.md](pipeline/docs/WORLD-DROP-OPEN-CHANCE.md).
