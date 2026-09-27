# Player stat weights (not built)

Prepared 27 Sep 2026. Do not implement until Henrik asks. Defaults stay as they are until then.

## What the player gets

A **Spec scoring** tab in Settings. Account-wide, not per character. Every spec lists the default weights. The player can override any stat, save, and later hit **Reset to default weights** for that spec only. Other specs they changed stay overridden.

The log, including the simulator, uses the weights for the spec on screen (`GetEffectiveSpec`). A simulated Enhancement shaman and a real one share the same saved overrides.

Saving only stores numbers. It does not rebuild every edited spec. The rebuild runs when that spec and level are the ones being viewed.

## Why it is not a small toggle

Today's hunts are scored in `pipeline/scripts/score.py` and shipped as winners. Each class file keeps the **top 8** per slot and level band (the log shows 3, plus a notable). Rows carry a finished score, not stat lines. `pipeline/data/items.json` (~14 MB) is the equippable catalog and is **not** in the addon. Generated hunt Lua is already ~41 MB.

Custom weights cannot surface a new piece until the addon ships a compact stat table for that catalog (the stats the scorer actually multiplies, not the whole JSON). Then a live score for **one spec and one level** can produce a new top 3.

## How to build it later

1. Emit a compact stat table from `items.json` into `GearQuest/_generated/`. Include weapon DPS, armor type, and the suffix jackpot stats. Leave procs and set packages out of the first version.
2. Port the level 1–59 multipliers next to `GQ.ScoringLeveling` (`sta` / `health` / `hp5` ×3, `armor` ×2, `int` / `spi` / `mp5` / `mana` ×2). Level 60 uses the raw weights.
3. When a spec has no overrides, keep using the prebuilt generated lists. Do not rescore on a normal spec switch.
4. When a spec has overrides, score that spec and level on apply and when the log shows it. One pass, plain arithmetic, no `GetItemInfo` per item. Not on every slider tick, and not for the other specs that were edited.
5. Store overrides on `GearQuestForeverDB` (account-wide), keyed by class and spec. Reset clears one spec.

A spec-picker change (Elemental to Enhancement) stays the cheap path: it only points at the other prebuilt list. A custom rebuild is a short hitch, heavier than that switch, and it must not run for every spec at save time.

Procs (`procs.py`) and set packages (Embrace of the Viper and the rest) stay on the default model until they are ported. A reset should look like today's lists because the default path never leaves the generated files.

## Load

Everyone pays the extra table at login, including players who never edit a weight. The rescore cost is only for a spec that has overrides, and only for the spec and level on screen.
