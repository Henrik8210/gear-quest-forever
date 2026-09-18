# Seen-item notebook (retired)

Forever item facts come from Wowhead ingest (`pipeline/data/forever_wowhead/` → `items.json` / `sources.json`), not from in-game collection.

Do **not** run `scripts/backup-seen-notebook.ps1`. Do not grow or commit `notebook/seenItems/`. `/gq seen` is a no-op message pointing at Wowhead.

See [docs/FOREVER-DATA-MIGRATION.md](../docs/FOREVER-DATA-MIGRATION.md) and [pipeline/docs/FOREVER-SCORING.md](../pipeline/docs/FOREVER-SCORING.md).
