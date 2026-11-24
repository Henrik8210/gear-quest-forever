"""Ring and trinket baseline when a worn piece is not on the hunt list (GearQuest/Data.lua)."""
from __future__ import annotations

import unittest
from pathlib import Path

from lupa.lua51 import LuaRuntime

REPO = Path(__file__).resolve().parents[2]
DATA_LUA = REPO / "GearQuest" / "Data.lua"

SETUP = """
    local GQ = { L = setmetatable({}, { __index = function(_, k) return k end }) }
    GQ.LocaleTable = function(t) return t end
    GQ.Log = { GetSlotRankList = function() return LIST end }
    GQ.Compare = { ScoreItemLinkStats = function(_, link) return STATS[link] end }
    GQ.Equip = { IsItemDataCached = function() return true end }
    GetInventoryItemLink = function(_, invSlot) return "link:" .. WORN[invSlot] end
    GetItemInfo = function(itemId) return nil, "link:" .. itemId end
    local chunk = assert(loadstring(DATA_SOURCE, "Data.lua"))
    chunk("GearQuestForever", GQ)
    local D = GQ.Data
    D.GetActiveBandCacheKey = function() return "band" end
    D.GetInventorySlots = function() return { 11, 12 } end
    D.EquippedItemId = function(_, invSlot) return WORN[invSlot] end
    D.EquippedPipelineScore = function(_, itemId) return SCORES[itemId] end
    D.WeaponLoadoutPipelineDelta = function() return nil end
    return D
"""


def upgrade_delta(worn: dict, scores: dict, stats: dict, candidate: dict) -> float:
    lua = LuaRuntime(unpack_returned_tuples=True)
    g = lua.globals()
    g.DATA_SOURCE = DATA_LUA.read_text(encoding="utf-8-sig")
    g.WORN = lua.table_from(worn)
    g.SCORES = lua.table_from(scores)
    g.STATS = lua.table_from(stats)
    g.LIST = lua.table_from([lua.table_from(candidate)])
    data = lua.execute(SETUP)
    result, _ = data.GearScoreUpgradeDelta(data, lua.table_from(candidate), "Finger")
    return result


CANDIDATE = {"itemId": 3, "slot": "Finger", "pipelineScore": 80}


class UnscoredWornRing(unittest.TestCase):
    def test_weaker_unscored_ring_is_the_baseline(self) -> None:
        delta = upgrade_delta(
            worn={11: 1, 12: 2},
            scores={1: 50},
            stats={"link:2": 10, "link:3": 40},
            candidate=CANDIDATE,
        )
        self.assertEqual(delta, 60)

    def test_scored_ring_stays_the_baseline_when_the_unscored_ring_is_stronger(self) -> None:
        delta = upgrade_delta(
            worn={11: 1, 12: 2},
            scores={1: 50},
            stats={"link:2": 100, "link:3": 40},
            candidate=CANDIDATE,
        )
        self.assertEqual(delta, 30)


if __name__ == "__main__":
    unittest.main()
