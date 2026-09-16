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
6. After the Forever beta client exists, set `## Interface:` from `WTF/Config.wtf` `lastAddonVersion` (see [README.md](README.md)).

## Release steps

Only when explicitly publishing:

1. Bump `## Version:` in `GearQuest/GearQuestForever.toc` and `GearQuest/Core.lua` (`GQ.VERSION`).
2. Add a `## vX.Y.Z` section to `CHANGELOG.md`.
3. Commit and push to `main`.
4. Tag and push: `git tag vX.Y.Z` then `git push origin vX.Y.Z` (tag must match version with `v` prefix).
5. Verify **GitHub Actions → Release** succeeds.
6. Check CurseForge → **Files** — new file appears as Processing, then Approved.

## Rules

- **Never tag** unless explicitly publishing a release.
- **Do not** delete and re-push tags — bump the patch version instead.
- Pushing to `main` alone is **not** a release.
- **Never** copy `X-Curse-Project-ID` from the TBC GearQuest repo.

## First upload

After `CF_API_KEY` is set and the **new** CurseForge project ID is in the toc. Tag must match `## Version:` with a `v` prefix (beta strings keep CurseForge on the beta channel):

```powershell
git tag v0.1.0-beta.1-forever
git push origin v0.1.0-beta.1-forever
```

Then confirm the Release workflow and CurseForge Files tab.
