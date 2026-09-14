# Faction fix — 7,587 cells corrected, plus the ordering question answered

Henrik: Batskin Belt requires **Tranquillien — Honored**, a Horde-only reputation, and it
was appearing for an Alliance paladin. Chasing it found a whole missing gate class and
one over-gate I introduced while fixing it.

## 1. Reputation was never a gate

`Batskin Belt` carries `reqRep = [["Tranquillien","Honored"]]`. Tranquillien is the Horde
hub in the Blood Elf Ghostlands — an Alliance character can never earn it. The item's
`allowRace` is **-1** and its zone string is the *sub-zone* "Tranquillien", which the
faction-zone list did not have. Same shape as the class lock living on the quest and the
faction lock living on the quartermaster: the restriction is one join away from the item.

Which reputations are faction-exclusive is derived by the mirror rule, not asserted. Of
20 reputations in the data, exactly two pairs mirror strongly:

| pair | mirrored (slot, ilvl, kind) keys | next-best partner |
|---|---|---|
| Honor Hold ↔ Thrallmar | **16** | 8 |
| Kurenai ↔ The Mag'har | **5** | none closer |

Every other Outland reputation is genuinely shared by both factions, which is why none
of them has a strong mirror. Tranquillien has no mirror at all — a Horde levelling hub
with no Alliance counterpart. Five names, one hand-verified input: which side each is on.

## 2. The over-gate I caused, and the better signal

Fixing the above, I added missing sub-zones to the faction lists — and broke something.
**"Mor'shan Base Camp" hosts BOTH Warsong Gulch quartermasters**: Illiyana Moonblaze
(Alliance) and Kelm Hargunth (Horde). Putting that zone in the Horde list gated
*Sentinel's Medallion* out of Alliance **and** out of Horde, leaving it nowhere — 210
hunter cells and 188 rogue cells silently emptied.

The vendor is the reliable signal, not the camp. A vendor is claimed for a side only when
its entire faction-identifiable stock is that side, with at least three such items — 14
vendors qualify and **none stock both sides**.

That also settled three items whose names carry no faction hint, and corrected an
assumption of mine:

| item | I assumed | the data says |
|---|---|---|
| Rune of Duty / Rune of Perfection | a faction pair | **both Alliance** — both sold by Illiyana |
| Caretaker's Cape | Horde | **Alliance** — Illiyana |
| Battle Healer's Cloak | Alliance | **Horde** — Kelm Hargunth |

## 3. Scale

| class | cells corrected | share |
|---|---|---|
| paladin | 1,168 | 7.8% |
| warrior | 1,289 | 8.1% |
| hunter | 1,165 | 7.2% |
| druid | 1,525 | 7.6% |
| shaman | 1,079 | 7.0% |
| rogue | 1,361 | 8.4% |
| **total** | **7,587** | |

The dominant offenders were not Tranquillien but the **battleground reward sets** whose
vendors stand in faction camps — *Defiler's* (Horde AB) against *Highlander's* (Alliance
AB), *Talisman of Arathor* against *Defiler's Talisman*, the AV runes and cloaks. All 13
audited faction pairs and reputation cases now resolve to exactly one faction, zero leaks.

## 4. The ordering question

Audited every band: **16,032 bands, and the only 220 with a non-descending score are
level-60 guide bands, where that is deliberate.** Rank is score-ordered everywhere else.

So if a list looks misordered outside level 60, it is the addon's rendering, not `rank`.
And at level 60 the score column is *intentionally* non-monotonic — the guide's tier
order wins, e.g. *Dreadnaught Helmet* scores 130.7 behind *Conqueror's Crown*'s 104.9
because the guide calls the Crown the plain Best and the Helmet the Best Mitigation.
**Never re-sort an `origin="guide"` band by score.** `rank` is authoritative; `score` is
context.

One thing worth knowing about the screenshot: `Batskin Belt` (28158) is **not in any of
my picks or notables** for paladin, at any level, on either faction. So whatever surfaced
it came from elsewhere — worth checking where, since it should not have been reachable.

## Import

All twelve data files. `#GQ.Data.entries` == **1,177 + 47,066 = 48,243**. Guide agreement
unchanged: 40/41, 44/44, 45/45, 57/57, 44/44, 43/43. Zero duplicate ids. All five standing
checks pass.
