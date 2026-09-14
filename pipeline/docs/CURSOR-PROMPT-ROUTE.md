# GearQuest — the `route` field: never show a staff and an off-hand as the same answer (R41)

## The problem

For any spec that can legally wield either a two-hander or a one-hander plus an off-hand,
the model ranks MainHand and SecondaryHand **independently**. So it can name a staff as the
best main hand *and* an off-hand item as the best off hand — a pair you cannot equip.

This is not an edge case. Over three quarters of caster main-hand picks are staves, so for
priest, warlock and mage it is the normal state of the list. For a hunter or an enhancement
shaman it is the same question in its two-hand-versus-dual-wield form.

## The fix, data side (done — files attached)

Each pick row on the two weapon slots may now carry:

```lua
{22589,"MainHand",57,69,1,"holy","Alliance",94.11,route="onehand"},
```

`route` is `"twohand"` or `"onehand"`, computed per spec, faction and level band from the
same scores that produced the ranks:

* **twoHandScore** = best two-handed candidate in MainHand
* **pairScore** = best one-handed candidate in MainHand **+** best SecondaryHand candidate
* `route = "twohand"` when twoHandScore ≥ pairScore, else `"onehand"`

**5,563 rows carry it.** It appears only where the choice is real — the spec's weapon style
is `twohand_or_onehand`:

| class | specs with a route |
|---|---|
| priest, warlock, mage | all three specs each |
| hunter | all three |
| druid | all four |
| shaman | enhancement only |
| paladin, warrior, rogue | levels 1–9 only |

It is deliberately **absent** on rogue combat/assassination/subtlety and warrior fury
(always dual wield), warrior arms and paladin retribution (always two-hand), and paladin
protection/holy and shaman elemental/restoration (always one-hand plus shield). Those specs
have no choice to make, so there is nothing to grey out.

**Zero picks changed in any class.** This is purely additive — verified across all nine.

## What the answer actually looks like

Worth seeing, because it flips more than you would expect:

```
priest  holy          10:1H  11-27:2H  28-55:1H  56:2H  57-69:1H
priest  shadow        10-14:1H  15-21:2H  22-34:1H  35-67:2H  68-69:1H
warlock affliction    10-14:1H  15-21:2H  22-34:1H  35-60:2H  61-69:1H
mage    frost         10:2H  11-12:1H  13-29:2H  30-34:1H  35-67:2H  68-69:1H
hunter  beast_mastery 10:2H  11-13:1H  14-16:2H  17-23:1H  24-30:2H  31-39:1H  40-59:2H  60-69:1H
shaman  enhancement   10-12:2H  13:1H  14-69:2H
druid   feral         10-15:2H  16-17:1H  18-69:2H
druid   balance       10-12:1H  13-31:2H  32-34:1H  35-67:2H  68-69:1H
```

Note the ends: a level-69 priest, warlock, mage, hunter and balance druid all want a
one-hander and an off-hand, while an enhancement shaman and a feral druid want a
two-hander almost the whole way.

## Change 1 — `DataAdapter.lua`

Pass it through in `Expand()`, next to the other row-level extras:

```lua
                suffix       = r.suffix,
                suffixChance = r.suffixChance,
                suffixId     = r.suffixId,
                suffixRange  = r.suffixRange,
                route        = r.route,        -- NEW
                origin       = r.origin,
```

## Change 2 — the UI rule

For a slot list where the entries carry a `route`:

* `route == "twohand"` — the **SecondaryHand** slot is not part of the answer. Grey the
  off-hand rows, or collapse the slot with a one-line note.
* `route == "onehand"` — two-handed items in **MainHand** are not part of the answer. Grey
  those rows; the one-handers stay live.
* `route == nil` — no change. Render exactly as today.

Two things to get right:

1. **Grey, don't hide.** The information is still useful — a player who already owns the
   staff wants to see it ranked. Dimming says "not the build you are on"; hiding says
   "does not exist", which is wrong.
2. **Say which build it is.** A short header on the two weapon slots — "Two-hand build" or
   "Dual-wield build" for hunter and enhancement shaman, "Staff build" / "One-hand + off-hand"
   for casters — turns a greyed row from a bug into an explanation. Without it the greying
   looks like a rendering fault.

Deciding which items are two-handed is a client call, not a data one:
`select(9, GetItemInfo(itemId)) == "INVTYPE_2HWEAPON"`.

## Verification

```
18/18 generated files compile
luatest: total entries 68209, malformed 0, duplicate ids 0
rows carrying a route: 5563
picks changed vs before: 0, in all nine classes
```

In-game, four checks:

1. **Level 60 priest holy, MainHand + SecondaryHand** — route is `onehand`, so the staves
   in the main-hand list should be greyed and the off-hand list live.
2. **Level 50 enhancement shaman** — route is `twohand`, so the off-hand list should be
   greyed instead.
3. **Level 60 rogue, any weapon slot** — no route at all; nothing may change.
4. **Level 68 hunter versus level 50 hunter** — the route flips between them, so the greying
   should move from one slot to the other as you change level in the simulate panel.
