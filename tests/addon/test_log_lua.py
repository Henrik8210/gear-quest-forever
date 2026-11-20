"""Guardrails for GearQuest/Log.lua (v1.2.5 regression: doubled GQ.Log prefix)."""
from __future__ import annotations

import re
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
LOG_LUA = REPO / "GearQuest" / "Log.lua"

# Helpers moved off file-scope locals must live on GQ.Log, not GQ.Log.GQ.Log.
LOG_EXPORTS = (
    "ApplyFilterButtonFont",
    "MouseOverFilterRow",
    "CreateSettingsCheck",
    "RefreshUnitGearTooltipSetting",
)

DOUBLE_PREFIX = re.compile(r"GQ\.Log\.GQ\.Log\.")
DEFINE_EXPORT = re.compile(r"^function\s+GQ\.Log\.(\w+)", re.MULTILINE)


class LogLuaGuardrails(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.text = LOG_LUA.read_text(encoding="utf-8-sig")

    def test_no_double_gq_log_prefix(self) -> None:
        for match in DOUBLE_PREFIX.finditer(self.text):
            line = self.text.count("\n", 0, match.start()) + 1
            self.fail(f"{LOG_LUA.name}:{line}: doubled GQ.Log prefix (use GQ.Log.Name only)")

    def test_critical_exports_defined(self) -> None:
        defined = set(DEFINE_EXPORT.findall(self.text))
        for name in LOG_EXPORTS:
            self.assertIn(name, defined, f"missing function GQ.Log.{name} in Log.lua")

    def test_exports_not_only_nested(self) -> None:
        for name in LOG_EXPORTS:
            bad = f"function GQ.Log.GQ.Log.{name}"
            self.assertNotIn(bad, self.text, f"found nested definition {bad}")


if __name__ == "__main__":
    unittest.main()