"""Re-saving the selected custom spec drops the weapon and loadout caches (GearQuest/CustomSpec.lua)."""
from __future__ import annotations

import re
import unittest
from pathlib import Path

from lupa.lua51 import LuaRuntime

REPO = Path(__file__).resolve().parents[2]
ADDON = REPO / "GearQuest"

SETUP = """
    local GQ = { L = setmetatable({}, { __index = function(_, k) return k end }) }
    GQ.LocaleTable = function(t) return t end
    GQ.GetEffectiveClass = function() return "PRIEST" end
    local function load(name, source)
        local chunk = assert(loadstring(source, name))
        chunk("GearQuestForever", GQ)
    end
    load("Data.lua", DATA_SOURCE)
    load("CustomSpec.lua", CUSTOM_SOURCE)
    local D = GQ.Data
    D.BuildIndex = function() end
    D.UsesTwoHandOnlyWeapons = function() return false end
    D.GetActiveBandCacheKey = function() return "60:PRIEST:Horde:custom1" end
    D.DualWieldReady = function() return false end
    D.EntryIsTwoHand = function(_, e) return e.twoHand == true end
    D.EntryIsDamagingWeapon = function(_, e) return e.weapon == true end
    D.GetCandidatesForSlot = function(_, slot) return LISTS[slot] end
    D.entries = {}
    GQ.Log = { InvalidateSourceFilterCache = function() end }
    assert(loadstring(LOG_INVALIDATE, "Log.lua"))(GQ)
    return GQ
"""

LOG_INVALIDATE_SOURCE = re.compile(
    r"^function GQ\.Log:InvalidateActiveListCaches\(\).*?^end$", re.MULTILINE | re.DOTALL
)


def read(name: str) -> str:
    return (ADDON / name).read_text(encoding="utf-8-sig")


def new_gq():
    lua = LuaRuntime(unpack_returned_tuples=True)
    g = lua.globals()
    g.DATA_SOURCE = read("Data.lua")
    g.CUSTOM_SOURCE = read("CustomSpec.lua")
    g.LOG_INVALIDATE = "local GQ = ...\n" + LOG_INVALIDATE_SOURCE.search(read("Log.lua")).group(0)
    shield = {"itemId": 1, "slot": "SecondaryHand", "pipelineScore": 40}
    mace = {"itemId": 2, "slot": "MainHand", "pipelineScore": 80, "weapon": True}
    g.LISTS = lua.table_from(
        {
            "SecondaryHand": lua.table_from([lua.table_from(shield)]),
            "MainHand": lua.table_from([lua.table_from(mace)]),
        }
    )
    return lua, lua.execute(SETUP), g.LISTS


def resave(lua, gq, lists, score: int) -> None:
    shield = {"itemId": 1, "slot": "SecondaryHand", "pipelineScore": score}
    mace = {"itemId": 2, "slot": "MainHand", "pipelineScore": score, "weapon": True}
    lists.SecondaryHand = lua.table_from([lua.table_from(shield)])
    lists.MainHand = lua.table_from([lua.table_from(mace)])
    job = lua.table_from({"classFile": "PRIEST", "record": lua.table_from({"base": "PRIEST"}), "bands": lua.table()})
    gq.Custom.Finish(gq.Custom, job)


class ResaveSelectedCustomSpec(unittest.TestCase):
    def test_one_hand_partner_is_rescored(self) -> None:
        lua, gq, lists = new_gq()
        self.assertEqual(gq.Data.BestOneHandPartner(gq.Data).pipelineScore, 80)
        resave(lua, gq, lists, 95)
        self.assertEqual(gq.Data.BestOneHandPartner(gq.Data).pipelineScore, 95)

    def test_off_hand_partner_is_rescored(self) -> None:
        lua, gq, lists = new_gq()
        self.assertEqual(gq.Data.BestOffHandPartner(gq.Data).pipelineScore, 40)
        resave(lua, gq, lists, 55)
        self.assertEqual(gq.Data.BestOffHandPartner(gq.Data).pipelineScore, 55)

    def test_weapon_loadout_score_is_rescored(self) -> None:
        lua, gq, lists = new_gq()
        self.assertEqual(gq.Data.BestWeaponLoadoutScore(gq.Data), 120)
        resave(lua, gq, lists, 50)
        self.assertEqual(gq.Data.BestWeaponLoadoutScore(gq.Data), 100)

    def test_weapon_lists_in_log_are_dropped(self) -> None:
        lua, gq, lists = new_gq()
        for field in ("_weaponPool", "_weaponTrueList", "_casterOffHand"):
            gq.Log[field] = lua.table()
        gq.Log._weaponPoolBand = gq.Log._weaponTrueBand = gq.Log._casterOffBand = "ctx"
        resave(lua, gq, lists, 95)
        for field in ("_weaponPool", "_weaponTrueList", "_casterOffHand"):
            self.assertIsNone(gq.Log[field], field)


if __name__ == "__main__":
    unittest.main()
