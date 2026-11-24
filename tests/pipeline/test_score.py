"""Scorer rules from .cursor/rules/forever-scoring.mdc, run on pipeline/scripts/score.py.

Run: python -m unittest discover -s tests/pipeline -v
"""
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "pipeline" / "scripts"))
import score  # noqa: E402

BASE = {"sta": 1.0, "health": 0.1, "hp5": 0.5, "armor": 0.01, "int": 0.4, "spi": 0.2,
        "mp5": 0.3, "mana": 0.02, "agi": 1.0, "str": 0.5, "hit": 2.0, "crit": 1.5, "sp": 0.8}


class LevelingWeights(unittest.TestCase):
    def test_sheet_row_is_the_score_at_every_level(self):
        for level in (1, 22, 59, 60, 70):
            w = score.weights_at_level(BASE, level)
            self.assertEqual(w, BASE, msg=f"level {level} must keep the sheet row")
            self.assertIsNot(w, BASE)

    def test_base_row_is_not_changed(self):
        before = dict(BASE)
        score.weights_at_level(BASE, 30)
        self.assertEqual(BASE, before)


class ForeverStats(unittest.TestCase):
    def test_damage_done_folds_into_spell_power_once(self):
        out = score.forever_stats({"heal": 20, "damageDone": 20})
        self.assertEqual(out["sp"], 20)
        self.assertEqual(out["damageDone"], 0)
        self.assertEqual(out["heal"], 20)
        again = score.forever_stats(out)
        self.assertEqual(again["sp"], 20, "a second pass must not count damageDone twice")

    def test_unequal_healing_and_damage_stay_apart(self):
        out = score.forever_stats({"heal": 48, "damageDone": 16})
        self.assertEqual(out["heal"], 48)
        self.assertEqual(out["sp"], 16)

    def test_heal_only_line_grants_a_third_as_spell_power(self):
        out = score.forever_stats({"heal": 30})
        self.assertAlmostEqual(out["sp_from_heal"], 10.0)

    def test_tbc_ratings_fold_into_one_hit_and_crit(self):
        out = score.forever_stats({"spellHit": 1, "hitRanged": 2, "spellCrit": 3, "expertise": 9})
        self.assertEqual(out["hit"], 3)
        self.assertEqual(out["crit"], 3)
        self.assertEqual(out["expertise"], 9)


class JackpotRoll(unittest.TestCase):
    ITEM = "999999901"

    def setUp(self):
        self.saved = score.rand.get(self.ITEM)
        self.saved_policy = score.ROLL_POLICY
        score.rand[self.ITEM] = [
            {"suffix": "of Agility", "chance": 9.5, "stats": {"agi": 7}, "statsMin": {"agi": 6}},
            {"suffix": "of Stamina", "chance": 50.0, "stats": {"sta": 2}, "statsMin": {"sta": 1}},
        ]

    def tearDown(self):
        score.ROLL_POLICY = self.saved_policy
        if self.saved is None:
            score.rand.pop(self.ITEM, None)
        else:
            score.rand[self.ITEM] = self.saved

    def test_policy_is_best_roll(self):
        self.assertEqual(score.ROLL_POLICY, "bestRoll")

    def test_ranks_on_the_top_of_the_best_suffix(self):
        item = {"id": int(self.ITEM), "stats": {"agi": 3}}
        result = score.best_variant(item, {"agi": 1.0, "sta": 1.0}, 22, None)
        total, suffix, chance = result[0], result[1], result[2]
        self.assertAlmostEqual(total, 10.0, msg="3 base agility + the +7 jackpot")
        self.assertEqual(suffix, "of Agility")
        self.assertEqual(chance, 9.5, "a slim chance is kept as a hint and does not bury the roll")
        self.assertEqual(result[6], "+6-7 Agility", "the hunt shows the range, not just the top")

    def test_a_roll_worse_than_the_base_is_not_a_variant(self):
        item = {"id": int(self.ITEM), "stats": {"agi": 3}}
        result = score.best_variant(item, {"int": 1.0}, 22, None)
        self.assertIsNone(result[1])


class HunterWeaponRoute(unittest.TestCase):
    def test_dual_wield_pair_uses_off_hand_list(self):
        """After Dual Wield, hunter one-handers live on SecondaryHand only."""
        mh_only_2h = [(20.0, {"id": 1, "inv": 17})]
        oh_swords = [
            (12.0, {"id": 2, "inv": 13}),
            (11.0, {"id": 3, "inv": 13}),
        ]
        per = {
            ("Alliance", 30, "MainHand"): mh_only_2h,
            ("Alliance", 30, "SecondaryHand"): oh_swords,
        }
        rt = score.route_for(per, "Alliance", 30, "HUNTER", 20)
        self.assertEqual(rt[0], "onehand")
        self.assertEqual(rt[1], 20.0)
        self.assertEqual(rt[2], 23.0)


class LaterBandsAndFactionZones(unittest.TestCase):
    def test_viable_depth_constants(self):
        self.assertEqual(score.VIABLE_SHARE, 0.25)
        self.assertEqual(score.VIABLE_LATER, 30)
        self.assertEqual(score.VIABLE_KEEP, 40)
        self.assertIn("The Barrens", score.HORDE_ZONES)

    def test_barrens_zone_does_not_decide_a_quest_drop_or_rare(self):
        prof = score.ARMOR_PROF["MAGE"]
        saved_src = {}
        saved_quest = {}

        def add(iid, source):
            key = str(iid)
            saved_src[key] = score.srcs.get(key)
            score.srcs[key] = source

        cases = {
            990001: {"obtainable": True, "sourceType": "world_drop", "zone": "The Barrens"},
            990002: {"obtainable": True, "sourceType": "rare_npc", "zone": "The Barrens"},
            990003: {"obtainable": True, "sourceType": "quest_reward", "zone": "The Barrens"},
            990004: {"obtainable": True, "sourceType": "vendor", "zone": "The Barrens", "npc": "Halija Whitestrider"},
            990005: {"obtainable": True, "sourceType": "vendor", "zone": "The Barrens", "npc": "Grazlix"},
            990006: {"obtainable": True, "sourceType": "profession", "zone": "The Barrens", "npc": "A Barrens Trainer"},
            990007: {"obtainable": True, "sourceType": "profession", "zone": None, "npc": None},
            990008: {"obtainable": True, "sourceType": "world_drop", "zone": "Elwynn Forest"},
            990009: {"obtainable": True, "sourceType": "vendor", "zone": "Elwynn Forest", "npc": "Kurran Steele"},
            990010: {"obtainable": True, "sourceType": "quest_reward", "zone": "Elwynn Forest"},
        }
        try:
            for iid, source in cases.items():
                add(iid, source)
            saved_quest[990003] = score.QUEST_FACTION.get(990003)
            item = {
                "id": 0, "name": "Probe", "allowClass": -1, "allowRace": -1,
                "rlvl": 1, "ilvl": 10, "cls": 4, "kind": "Cloth", "slot": "Chest",
                "inv": 5, "reqRep": [],
            }
            both = dict(item)
            both["id"] = 990003
            self.assertTrue(score.eligible(dict(item, id=990001), "MAGE", "affliction", 20, "Alliance", prof, set()))
            self.assertTrue(score.eligible(dict(item, id=990002), "MAGE", "affliction", 20, "Alliance", prof, set()))
            self.assertTrue(score.eligible(both, "MAGE", "affliction", 20, "Alliance", prof, set()))
            score.QUEST_FACTION[990003] = "Horde"
            self.assertFalse(score.eligible(both, "MAGE", "affliction", 20, "Alliance", prof, set()))
            self.assertTrue(score.eligible(both, "MAGE", "affliction", 20, "Horde", prof, set()))
            self.assertFalse(score.eligible(dict(item, id=990004), "MAGE", "affliction", 20, "Alliance", prof, set()))
            self.assertTrue(score.eligible(dict(item, id=990004), "MAGE", "affliction", 20, "Horde", prof, set()))
            self.assertTrue(score.eligible(dict(item, id=990005), "MAGE", "affliction", 20, "Alliance", prof, set()))
            self.assertFalse(score.eligible(dict(item, id=990006), "MAGE", "affliction", 20, "Alliance", prof, set()))
            self.assertTrue(score.eligible(dict(item, id=990007), "MAGE", "affliction", 20, "Alliance", prof, set()))
            self.assertTrue(score.eligible(dict(item, id=990008), "MAGE", "affliction", 20, "Horde", prof, set()))
            self.assertFalse(score.eligible(dict(item, id=990009), "MAGE", "affliction", 20, "Horde", prof, set()))
            self.assertTrue(score.eligible(dict(item, id=990009), "MAGE", "affliction", 20, "Alliance", prof, set()))
            elwynn = dict(item, id=990010)
            score.QUEST_FACTION[990010] = "Alliance"
            self.assertFalse(score.eligible(elwynn, "MAGE", "affliction", 20, "Horde", prof, set()))
            self.assertTrue(score.eligible(elwynn, "MAGE", "affliction", 20, "Alliance", prof, set()))
        finally:
            for key, prev in saved_src.items():
                if prev is None:
                    score.srcs.pop(key, None)
                else:
                    score.srcs[key] = prev
            if saved_quest.get(990003) is None:
                score.QUEST_FACTION.pop(990003, None)
            else:
                score.QUEST_FACTION[990003] = saved_quest[990003]
            score.QUEST_FACTION.pop(990010, None)

    def test_display_locks_match_the_exclusive_json(self):
        root = Path(__file__).resolve().parents[2]
        pairs = (
            ("vendor_side.json", "Data.VendorSide.generated.lua"),
            ("drop_faction.json", "Data.DropFaction.generated.lua"),
        )
        for json_name, lua_name in pairs:
            sides = json.loads((root / "pipeline" / "data" / json_name).read_text(encoding="utf-8"))
            text = (root / "GearQuest" / "_generated" / lua_name).read_text(encoding="utf-8")
            self.assertGreater(len(sides), 0)
            for iid, side in sides.items():
                self.assertIn(f'[{int(iid)}] = "{side}"', text)

    def test_barrens_is_not_a_horde_quest_map(self):
        text = Path(__file__).resolve().parents[2].joinpath("pipeline/scripts/index_coordinates.py").read_text(encoding="utf-8")
        start = text.index("HORDE_MAPS = {")
        block = text[start:text.index("}", start)]
        self.assertNotIn('"The Barrens"', block)
        self.assertIn("6898", text)


if __name__ == "__main__":
    unittest.main()
