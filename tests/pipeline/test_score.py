"""Scorer rules from .cursor/rules/forever-scoring.mdc, run on pipeline/scripts/score.py.

Run: python -m unittest discover -s tests/pipeline -v
"""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "pipeline" / "scripts"))
import score  # noqa: E402

BASE = {"sta": 1.0, "health": 0.1, "hp5": 0.5, "armor": 0.01, "int": 0.4, "spi": 0.2,
        "mp5": 0.3, "mana": 0.02, "agi": 1.0, "str": 0.5, "hit": 2.0, "crit": 1.5, "sp": 0.8}


class LevelingWeights(unittest.TestCase):
    def test_survivability_and_endurance_through_60(self):
        for level in (1, 22, 59, 60):
            w = score.weights_at_level(BASE, level)
            self.assertAlmostEqual(w["sta"], 3.0, msg=f"stamina x3 at {level}")
            self.assertAlmostEqual(w["health"], 0.3, msg=f"health x3 at {level}")
            self.assertAlmostEqual(w["hp5"], 1.5, msg=f"health per 5 x3 at {level}")
            self.assertAlmostEqual(w["armor"], 0.02, msg=f"armor x2 at {level}")
            self.assertAlmostEqual(w["int"], 0.8, msg=f"intellect x2 at {level}")
            self.assertAlmostEqual(w["spi"], 0.4, msg=f"spirit x2 at {level}")
            self.assertAlmostEqual(w["mp5"], 0.6, msg=f"mana per 5 x2 at {level}")
            self.assertAlmostEqual(w["mana"], 0.04, msg=f"mana x2 at {level}")

    def test_damage_stats_stay_raw(self):
        w = score.weights_at_level(BASE, 30)
        for key in ("agi", "str", "hit", "crit", "sp"):
            self.assertEqual(w[key], BASE[key], key)

    def test_level_60_uses_the_leveling_multipliers(self):
        self.assertEqual(score.weights_at_level(BASE, 60), score.weights_at_level(BASE, 30))

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


if __name__ == "__main__":
    unittest.main()
