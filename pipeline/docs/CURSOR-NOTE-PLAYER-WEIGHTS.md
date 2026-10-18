# Player stat weights (shipped in v0.6.0-beta)

The settings-tab plan below was not built. Players edit weights from the spec menu, not from Settings.

## What shipped

The spec menu has a divider, then that class's custom specs, then **+ custom stat weights**. The window sits on the log. The name is at most 20 characters. The player picks the premade spec it is based on. An empty box shows that spec's weight through level 60, including the leveling multipliers. A typed number replaces it, including 0, with no extra multiplier.

A typed Spell power weight scores the Spell Power stat only. The Equip line "Increases damage and healing done by magical spells and effects by up to N" stays on Healing. An empty Spell power box still counts that line's damage half as spell power.

**Save and score items!** reorders that spec's existing hunts. It does not pull in a piece the base spec never ranked. The portrait spins on the GearQuest window until the hunt list is painted and can scroll. Weights are account-wide (`GearQuestForeverDB.customSpecs`). The selected spec stays on the character. Right-click edits. Delete removes it.

Weapon style, pins, and the item pool stay the base spec's. Stats, weapon damage, armor class, the best suffix, Embrace of the Viper, and Rotmender's Raiment are scored again. A proc such as Thunderfury ranks on the printed stats. Stat rows are `GearQuest/_generated/Data.ItemStats.generated.lua`, written by `pipeline/scripts/emit_item_stats.py`.

Simulating another class scores that class's custom spec after the class hunts are indexed. Turning simulation off scores the character's saved custom spec. A left click on a custom spec selects it after a reload.

Premade weights still change only when a sheet suggestion is copied into `weights.json` and that class is re-scored. Do not retune from the sheet unless asked.

## The old plan (do not build this)

A **Spec scoring** tab in Settings, overriding every premade spec in place, was the 27 Sep 2026 sketch. Do not add that tab. Do not rescore a premade spec when the player types a custom weight.
