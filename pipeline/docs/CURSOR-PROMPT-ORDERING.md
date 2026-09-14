# GearQuest — order every BiS list best-first, worst-last (R39)

Henrik's requirement: **best BiS at the top, least-best at the bottom, everywhere — not
just for Edgemaster's.** Two runtime sorts currently prevent that. Both need changing.
This is addon code only; no data files change.

---

## The evidence

Level 47 fury warrior, Hands slot. The log shows:

```
1  Vice Grips of Strength
2  Truesilver Gauntlets
3  Edgemaster's Handguards
```

`Data.Warrior.generated.lua` — warrior fury, Hands, Alliance, the band covering 47 — says:

```
rank 1   Edgemaster's Handguards      score 45.92
rank 2   Vice Grips                   score 26.78
rank 3   Truesilver Gauntlets         score 23.75
```

The addon displayed ranks **2, 3, 1**. The data is correct; the display is not. This is
not the old Edgemaster patch — that script is deleted and the underlying rows are right.

---

## Change 1 (required) — `Compare.lua`: trust the pipeline rank for every class

### Current code, around line 87

```lua
--- Classes whose generated picks are fully stat-weighted in the pipeline; runtime
--- ilvl re-ranking would wrongly promote high-dps staves/wands over stat sticks.
local PIPELINE_RANK_CLASSES = {
    PRIEST = true,
    MAGE = true,
    WARLOCK = true,
}
```

and inside `GQ.Compare:RankEntries`, around line 118:

```lua
    local function PrefersRank(entry)
        if not entry then
            return false
        end
        if entry.origin == "guide" then
            return true
        end
        if not entry.generated then
            return true
        end
        if PIPELINE_RANK_CLASSES[classFile] then
            return true
        end
        return false
    end
```

### Replace with

```lua
    -- Every class is now fully stat-weighted in the pipeline, and every generated row
    -- carries a rank computed from that spec's own weights -- 67,033 picks rows across
    -- the 18 generated files, none of them missing one. Runtime ilvl re-ranking predates
    -- that and now fights it: a level-49 mail glove carrying +19 hit and +17 expertise
    -- loses to plate gloves whose only edge is armour the spec barely values, which is
    -- exactly the trade-off the pipeline already priced. If the pipeline ranked it, that
    -- rank is the answer.
    --
    -- This subsumes the three cases the old code special-cased: hand-curated rows,
    -- origin="guide" rows and the PRIEST/MAGE/WARLOCK allowlist all carry a curatedRank.
    local function PrefersRank(entry)
        if not entry then
            return false
        end
        return entry.curatedRank ~= nil
    end
```

Then **delete the `PIPELINE_RANK_CLASSES` table** — nothing else references it. `classFile`
may become unused inside `RankEntries`; leave it if other code in the function still needs
it, remove it if not.

### Why this is safe for the two cases the allowlist was protecting

**Guide rows at level 60 keep the guide's order.** At 60 the Classic BiS guide's own
ordering is the answer rather than descending score — that is deliberate. Those rows
encode the guide's order *in* `curatedRank`, so trusting `curatedRank` preserves it. I
verified this across all 18 generated files: there are 309 bands where a lower rank
carries a higher score, and **every single one is at exactly level 60. Zero anywhere
else.** The guide override is the only thing that should ever reorder ranks, and it still
will.

**Notable rows still land last.** They arrive via `GQ.Data:GetNotableForSlot()`, appended
after the picks loop in `GetActiveSlotListEntries` and capped at one per slot, and they
carry no `curatedRank`. The comparator already handles that — `if rankA and not rankB then
return true end` puts a ranked row ahead of an unranked one — so notables stay at the
bottom, which is right: they are the "value is a proc the score cannot price" shelf, not
part of the top 3.

---

## Change 2 (required) — `Log.lua`: order the Completed tab by rank too

Around line 938, `GetCompletedSlotListEntries` sorts by acquisition time:

```lua
    table.sort(results, function(a, b)
        if a.completedAt ~= b.completedAt then
            return a.completedAt > b.completedAt
        end
        return a.entry.id < b.entry.id
    end)
```

So the Completed tab is most-recently-obtained first and never reflects BiS order at all.
Make rank primary and keep the existing keys as tiebreaks:

```lua
    -- Same ordering rule as the active list: best BiS first, least-best last. Rows with
    -- no pipeline rank (notables) fall to the bottom via math.huge. Acquisition time
    -- survives as the tiebreak between two rows of equal rank.
    table.sort(results, function(a, b)
        local rankA = a.entry.curatedRank or math.huge
        local rankB = b.entry.curatedRank or math.huge
        if rankA ~= rankB then
            return rankA < rankB
        end
        if a.completedAt ~= b.completedAt then
            return a.completedAt > b.completedAt
        end
        return a.entry.id < b.entry.id
    end)
```

---

## Verification

1. **Level 47 fury warrior, Hands** — must read **Edgemaster's Handguards, Vice Grips,
   Truesilver Gauntlets**. This is the exact case in the screenshot.
2. **Level 60 protection warrior**, any guide-covered slot — order must still match the
   guide, *not* descending score. This is the one case where a lower rank legitimately
   carries a higher score, and it must not regress.
3. **Any slot with a Notable** — the notable must still be last.
4. **A priest, mage or warlock slot** — those three were already on the allowlist, so
   nothing about them should move. If something does, `PrefersRank` is wrong.
5. **The Completed tab** — should now read in BiS order rather than newest-first.

## Regression guard worth adding

The check that caught this class of problem, if you want it as a script: for every band in
every generated file, assert that pick scores are non-increasing as rank increases. Any
violation outside a level-60 band is a bug. Current state: 309 violations, all at level 60,
none elsewhere.
