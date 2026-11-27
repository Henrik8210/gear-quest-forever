#!/usr/bin/env python3
"""Addon code keeps the rules in .cursor/rules/forever-scoring.mdc.

Comments are stripped before matching, so a comment that explains a rule does
not trip it.

- No full garbage collection. GQ:CollectGarbageSoon steps the cycle.
- The world map: no AddDataProvider, no write to WorldMapFrame.pinPools, no
  WorldMapFrame OnShow hook, no SetIgnoreParentScale(true), no replacement of
  a WaypointLocationPinMixin method. Those taint the gamepad and the map.
- The gamepad: no SetUIFocusState and no FrameControlsManager method call.
  Reading FrameControlsManager.currentFrame is fine.
- Log.lua's main chunk is close to Lua 5.1's 200-local limit. It may not gain
  a file-scope local; put new state on GQ.Log instead.
- v1.3.8 idle memory. Only Guide Gear's upgrade cache, the unfiltered weapon
  pool, and the play-style reclaim stay wired. A mismatched cache key rebuilt
  the hunt list about once a second, and each toggle left another copy.

Usage: python scripts/ci/check_rules.py
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
ADDON = REPO / "GearQuest"
LOG_FILE_LOCALS = 189

BANNED = [
    (r"collectgarbage\s*\(\s*\)|collectgarbage\s*\(\s*[\"']collect[\"']|collectgarbage\s*[\"']collect[\"']",
     "full garbage collection; use GQ:CollectGarbageSoon"),
    (r"\bAddDataProvider\s*\(", "WorldMapFrame data provider taints the map"),
    (r"pinPools\s*(\[[^\]]*\]\s*)?=(?!=)", "writing WorldMapFrame.pinPools taints the map"),
    (r"WaypointLocationPinMixin\s*\.\s*\w+\s*=",
     "replacing a waypoint pin method taints AcquirePin and SetPassThroughButtons"),
    (r"WorldMapFrame\s*:\s*HookScript\s*\(\s*[\"']OnShow", "hooking WorldMapFrame OnShow taints the map"),
    (r"hooksecurefunc\s*\(\s*WorldMapFrame\s*,\s*[\"']OnShow", "hooking WorldMapFrame OnShow taints the map"),
    (r"SetIgnoreParentScale\s*\(\s*true", "ignoring the canvas scale makes map pins gigantic"),
    (r"\bSetUIFocusState\s*\(", "SetUIFocusState changes the gamepad binding stack"),
    (r"FrameControlsManager\s*:\s*\w+\s*\(|FrameControlsManager\s*\.\s*\w+\s*\(",
     "FrameControlsManager methods change the gamepad binding stack; read currentFrame only"),
    (r"GQ\.Log\.GQ\.Log\.", "double GQ.Log prefix; define as GQ.Log.Something only"),
]

BLOCK_COMMENT = re.compile(r"--\[(=*)\[.*?\]\1\]", re.S)
LINE_COMMENT = re.compile(r"--[^\n]*")


def strip_comments(text: str) -> str:
    text = BLOCK_COMMENT.sub(lambda m: "\n" * m.group(0).count("\n"), text)
    return LINE_COMMENT.sub("", text)


def file_scope_locals(text: str) -> int:
    count = 0
    for line in strip_comments(text).splitlines():
        if re.match(r"^local\s+function\s+\w+", line):
            count += 1
            continue
        match = re.match(r"^local\s+([\w\s,]+?)\s*(=|$)", line)
        if match:
            count += len([n for n in match.group(1).split(",") if n.strip()])
    return count


def function_body(text: str, signature: str) -> str:
    start = text.find(signature)
    if start < 0:
        return ""
    rest = text[start + len(signature):]
    match = re.search(r"\n(?:local )?function ", rest)
    return rest[: match.start()] if match else rest


# v1.3.8. Only Guide Gear looked up slot:3 while it stored slot:3:guide, so the
# warm never finished and rebuilt the hunt list about once a second. A play
# style that only hides rows must reuse the weapon pool, and turning one off
# has to step the collector. Closing the guide arrow still does the same.
MEMORY_WIRING = [
    ("GearQuest/Data.lua", "function GQ.Data:InvalidateQueryCache()", "_warmUnfinished = nil"),
    ("GearQuest/Data.lua", "function GQ.Data:InvalidateSpecCache()", "_warmUnfinished = nil"),
    ("GearQuest/Data.lua", "function GQ.Data:BuildTopUpgradesForSlot(", "self:TopUpgradeCacheKey("),
    ("GearQuest/Data.lua", "function GQ.Data:IsQueryCacheWarm()", "self:TopUpgradeCacheKey("),
    ("GearQuest/Data.lua", "function GQ.Data:TopUpgradeCacheKey(", '":guide"'),
    ("GearQuest/Log.lua", "function GQ.Log:CheckAutoCompletion(", "_warmUnfinished"),
    ("GearQuest/Log.lua", "function GQ.Log:GetRankCacheKey()", "OnlyGuideGearEnabled"),
    ("GearQuest/Log.lua", "function GQ.Log:SetPlayStyleFlag(", "CollectGarbageSoon"),
    ("GearQuest/Log.lua", "function GQ.Log:SetOnlyGuideGear(", "_weaponPool = nil"),
    ("GearQuest/Log.lua", "function GQ.Log:SetFocusZone(", "CollectGarbageSoon"),
    ("GearQuest/Log.lua", "function GQ.Log:BuildCollectWeaponPool()", "GetRankCacheKey"),
    ("GearQuest/Log.lua", "function GQ.Log:UnfilteredWeaponList()", "GetRankCacheKey"),
    ("GearQuest/Log.lua", "function GQ.Log:HeldOffHandEntries()", "GetRankCacheKey"),
    ("GearQuest/Log.lua", "function GQ.Log:CasterBisOffHand()", "GetRankCacheKey"),
    ("GearQuest/Core.lua", "function GQ:CollectGarbageSoon()", "_gcTicker:Cancel"),
    ("GearQuest/Guide.lua", "local function HideGuide(", "CollectGarbageSoon"),
]


def check_memory_wiring() -> int:
    failures = 0
    loaded: dict[str, str] = {}
    for rel, signature, needle in MEMORY_WIRING:
        if rel not in loaded:
            loaded[rel] = (REPO / rel).read_text(encoding="utf-8-sig")
        body = function_body(loaded[rel], signature)
        if not body:
            print(f"FAIL {rel}: missing {signature}")
            failures += 1
        elif needle not in body:
            print(f"FAIL {rel}: {signature} no longer contains {needle}")
            failures += 1
    return failures


def main() -> int:
    failures = 0
    files = [p for p in sorted(ADDON.rglob("*.lua")) if "_generated" not in p.parts]
    for path in files:
        code = strip_comments(path.read_text(encoding="utf-8-sig"))
        rel = path.relative_to(REPO).as_posix()
        for pattern, why in BANNED:
            for match in re.finditer(pattern, code):
                line = code.count("\n", 0, match.start()) + 1
                print(f"FAIL {rel}:{line}: {why}")
                failures += 1

    failures += check_memory_wiring()

    log_locals = file_scope_locals((ADDON / "Log.lua").read_text(encoding="utf-8-sig"))
    if log_locals > LOG_FILE_LOCALS:
        print(f"FAIL GearQuest/Log.lua has {log_locals} file-scope locals, the limit is "
              f"{LOG_FILE_LOCALS}. Lua 5.1 stops at 200; put new state on GQ.Log.")
        failures += 1
    elif log_locals < LOG_FILE_LOCALS:
        print(f"Note: Log.lua has {log_locals} file-scope locals; lower LOG_FILE_LOCALS "
              f"in {Path(__file__).name} to {log_locals}")

    print(f"Checked {len(files)} addon files against the code rules, {failures} failures")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
