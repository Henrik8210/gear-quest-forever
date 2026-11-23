"""Off-hand scoring against a worn two-hander (GearQuest/Data.lua)."""
from __future__ import annotations

import unittest
from pathlib import Path

from lupa.lua51 import LuaRuntime

REPO = Path(__file__).resolve().parents[2]
DATA_LUA = REPO / "GearQuest" / "Data.lua"

SETUP = """
    local GQ = { L = setmetatable({}, { __index = function(_, k) return k end }) }
    GQ.LocaleTable = function(t) return t end
    GQ.GetEffectiveClass = function() return CLASS end
    local chunk = assert(loadstring(DATA_SOURCE, "Data.lua"))
    chunk("GearQuestForever", GQ)
    local D = GQ.Data
    D.TwoHandCompetesWithPair = function() return true end
    D.WornWeaponHands = function() return WORN_MAIN, 0, true end
    D.GetActiveBandCacheKey = function() return "band" end
    D.DualWieldReady = function() return DUAL_WIELD end
    D.EntryIsTwoHand = function(_, e) return e.twoHand == true end
    D.EntryIsDamagingWeapon = function(_, e) return e.weapon == true end
    D.GetCandidatesForSlot = function(_, slot) return LISTS[slot] end
    return D
"""


def new_data(class_file: str, dual_wield: bool, worn_main: float, lists: dict):
    lua = LuaRuntime(unpack_returned_tuples=True)
    g = lua.globals()
    g.DATA_SOURCE = DATA_LUA.read_text(encoding="utf-8-sig")
    g.CLASS = class_file
    g.DUAL_WIELD = dual_wield
    g.WORN_MAIN = worn_main
    g.LISTS = lua.table_from(
        {slot: lua.table_from([lua.table_from(e) for e in entries]) for slot, entries in lists.items()}
    )
    return lua, lua.execute(SETUP)


def delta(data, entry: dict) -> float:
    lua, data = data
    result, _ = data.WeaponLoadoutPipelineDelta(data, lua.table_from(entry))
    return result


class OffHandAgainstTwoHander(unittest.TestCase):
    def test_shield_is_paired_with_a_one_hander_when_the_class_cannot_dual_wield(self) -> None:
        shield = {"itemId": 1, "slot": "SecondaryHand", "pipelineScore": 40}
        mace = {"itemId": 2, "slot": "MainHand", "pipelineScore": 80, "weapon": True}
        data = new_data("PRIEST", False, 100, {"SecondaryHand": [shield], "MainHand": [mace]})
        self.assertEqual(delta(data, shield), 20)

    def test_off_hand_weapon_is_paired_with_the_best_other_off_hand_weapon_when_dual_wielding(self) -> None:
        dagger = {"itemId": 1, "slot": "SecondaryHand", "pipelineScore": 50, "weapon": True}
        other = {"itemId": 2, "slot": "SecondaryHand", "pipelineScore": 70, "weapon": True}
        data = new_data("WARRIOR", True, 100, {"SecondaryHand": [dagger, other], "MainHand": []})
        self.assertEqual(delta(data, dagger), 20)


if __name__ == "__main__":
    unittest.main()
