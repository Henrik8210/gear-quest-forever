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
6. TOC `## Interface:` is **16001** for CurseForge **WoW Forever 1.60.1**. Confirm `lastAddonVersion` in the beta `WTF/Config.wtf` after first login.

## Release steps

Only when explicitly publishing:

1. Bump `## Version:` in `GearQuest/GearQuestForever.toc` and `GearQuest/Core.lua` (`GQ.VERSION`) to **`X.Y.Z-forever-beta`** (e.g. `0.2.0-forever-beta`). Do not use `0.1.0-beta.7-forever`.
2. Add a `## vX.Y.Z-forever-beta` section to `CHANGELOG.md`.
3. Commit and push to `main`.
4. Tag and push: `git tag vX.Y.Z-forever-beta` then `git push origin vX.Y.Z-forever-beta` (tag matches toc, with `v` prefix). CurseForge **Files** shows `X.Y.Z-forever-beta` (the `v` is stripped). Uploads stay on the **beta** channel until `CF_RELEASE_TYPE` is changed to `release`.
5. Verify **GitHub Actions → Release** succeeds.
6. Check CurseForge → **Files** — new file appears as Processing, then Approved.

## Rules

- **Never tag** unless explicitly publishing a release.
- **Do not** delete and re-push tags — bump the patch version instead.
- Pushing to `main` alone is **not** a release.
- **Never** copy `X-Curse-Project-ID` from the TBC GearQuest repo.

## Next upload

Version string is **`X.Y.Z-forever-beta`**. Do not use `0.1.0-beta.N-forever`.

After `v0.2.0-forever-beta`, bump the patch (e.g. `0.2.1-forever-beta`) rather than deleting the tag.
