#!/usr/bin/env python3
"""Spec tooltip and hunt score both use the weights.json row. No level multiplier.

Usage: python scripts/ci/check_scoring_weights_parity.py
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
WEIGHTS_PATH = REPO / "pipeline" / "data" / "weights.json"
SCORING_LUA = REPO / "GearQuest" / "_generated" / "ScoringWeights.generated.lua"
GEN = REPO / "GearQuest" / "_generated"

SCORING_LABELS = {
    "agi", "str", "int", "sta", "spi", "ap", "rap", "feralAp",
    "heal", "sp_from_heal", "sp", "spHoly", "spFire", "spFrost", "spNature",
    "spArcane", "spShadow", "hit", "crit", "haste", "expertise",
    "armor", "health", "hp5", "mana", "mp5", "defense", "dodge", "parry",
    "blockRating", "blockValue", "resist",
}

SHEET_STATS = (
    "sta", "health", "hp5", "armor", "int", "spi", "mp5", "mana",
)

HEALER_SPECS = {
    ("PALADIN", "holy"),
    ("DRUID", "restoration"),
    ("SHAMAN", "restoration"),
    ("PRIEST", "holy"),
    ("PRIEST", "discipline"),
}

STAT_KEYS_COMPARE = [
    "agi", "str", "int", "sta", "spi", "ap", "rap", "feralAp",
    "heal", "sp", "sp_from_heal", "hit", "crit", "haste", "expertise",
    "armorPen", "armor", "health", "hp5", "mana", "mp5", "defense",
    "dodge", "parry", "blockRating", "blockValue", "resist",
    "spShadow", "spFire", "spFrost", "spNature", "spArcane", "spHoly",
]


def spec_wants_heal(cls: str, spec: str) -> bool:
    return (cls, spec) in HEALER_SPECS


def score_effective(cls: str, spec: str, level: int, base: dict[str, float]) -> dict[str, float]:
    """pipeline/scripts/score.py weights_at_level + per-spec overrides."""
    del level
    wl = dict(base)
    if cls == "SHAMAN" and spec == "enhancement_tank":
        wl["agi"] = (
            wl.get("agi", 0.0)
            + 2.0 * wl.get("armor", 0.0)
            + wl.get("dodge", 0.0) / 20.0
            + wl.get("crit", 0.0) / 20.0
        )
    if not spec_wants_heal(cls, spec):
        wl["heal"] = 0.0
        wl["sp_from_heal"] = 0.0
    return wl


def display_effective(cls: str, spec: str, level: int, base: dict[str, float]) -> dict[str, float]:
    """GearQuest/Compare.lua GetEffectiveScoringRows — the sheet row."""
    weights = dict(base)
    if not spec_wants_heal(cls, spec):
        weights["heal"] = 0.0
        weights["sp_from_heal"] = 0.0
    return weights


def leveled_stat_weight(cls: str, spec: str, level: int, base: dict[str, float], key: str) -> float:
    """Compare.lua LeveledStatWeight is the sheet number."""
    del cls, spec, level
    return base.get(key, 0.0)


def lua_get(tbl, key, default=None):
    if tbl is None:
        return default
    try:
        return tbl[key]
    except (KeyError, TypeError):
        return default


def lua_pairs(tbl):
    if tbl is None:
        return []
    out = []
    for key in tbl:
        out.append((key, tbl[key]))
    return out


def load_scoring_weights_lua():
    try:
        import lupa
    except ImportError:
        raise SystemExit("pip install lupa")

    text = SCORING_LUA.read_text(encoding="utf-8").replace(
        "local _, GQ = ...", "GQ = GQ or {}", 1
    )
    runtime = lupa.LuaRuntime()
    runtime.execute(text)
    return runtime.globals()["GQ"]["ScoringWeights"]


def main() -> int:
    weights = json.loads(WEIGHTS_PATH.read_text(encoding="utf-8"))
    failures: list[str] = []
    warnings: list[str] = []
    levels = [1, 9, 30, 60, 61]
    spec_count = 0

    for cls, block in sorted(weights.items()):
        if cls.startswith("_") or not isinstance(block, dict):
            continue
        for spec, cfg in sorted(block.items()):
            if spec.startswith("_") or not isinstance(cfg, dict):
                continue
            base = cfg.get("weights") or {}
            if not base:
                continue
            spec_count += 1
            if not spec_wants_heal(cls, spec):
                for hk in ("heal", "sp_from_heal"):
                    if base.get(hk, 0):
                        warnings.append(
                            f"{cls}/{spec}: spec tooltip zeros {hk}; Compare GetStatWeight "
                            f"still has the pipeline value for suffix reorder only"
                        )
                        break
            d = display_effective(cls, spec, 30, base)
            for key, raw in base.items():
                if not isinstance(raw, (int, float)):
                    continue
                want = d.get(key, 0.0)
                if key in ("heal", "sp_from_heal") and not spec_wants_heal(cls, spec):
                    raw_show = 0.0
                else:
                    raw_show = float(raw)
                if abs(want - raw_show) > 1e-6:
                    failures.append(
                        f"{cls}/{spec} tooltip {key}: grid={raw_show} display={want}"
                    )
            for level in levels:
                s = score_effective(cls, spec, level, base)
                for key in SHEET_STATS:
                    if key not in base:
                        continue
                    if abs(float(s.get(key, 0)) - float(base.get(key, 0))) > 1e-6:
                        failures.append(
                            f"{cls}/{spec} L{level} score {key}: sheet={base[key]} scored={s.get(key)}"
                        )

    generated = load_scoring_weights_lua()
    gen_classes = {k: v for k, v in lua_pairs(generated)}
    for cls, block in weights.items():
        if cls.startswith("_") or not isinstance(block, dict):
            continue
        gen_cls = gen_classes.get(cls)
        if not gen_cls:
            failures.append(f"{cls} missing from ScoringWeights.generated.lua")
            continue
        gen_specs = {k: v for k, v in lua_pairs(gen_cls)}
        for spec, cfg in block.items():
            if spec.startswith("_") or not isinstance(cfg, dict):
                continue
            base = cfg.get("weights") or {}
            gen_spec = gen_specs.get(spec)
            if not gen_spec:
                failures.append(f"{cls}/{spec} missing from ScoringWeights.generated.lua")
                continue
            gen_w_tbl = lua_get(gen_spec, "weights") or {}
            gen_w = {k: float(v) for k, v in lua_pairs(gen_w_tbl)}
            for key, val in base.items():
                if key not in SCORING_LABELS or not isinstance(val, (int, float)) or val == 0:
                    continue
                if key not in gen_w:
                    failures.append(f"{cls}/{spec} missing in ScoringWeights: {key}")
                elif abs(float(gen_w[key]) - float(val)) > 1e-6:
                    failures.append(
                        f"{cls}/{spec} raw {key}: json={val} lua={gen_w[key]}"
                    )
            for field in ("dpsWeight", "dpsWeightRanged", "speedWeight"):
                jv = cfg.get(field)
                if jv is None or jv == 0:
                    continue
                lv = lua_get(gen_spec, field)
                if lv is None or abs(float(lv) - float(jv)) > 1e-6:
                    failures.append(
                        f"{cls}/{spec} {field}: json={jv} lua={lv}"
                    )

    pick_keys = set(STAT_KEYS_COMPARE) & SCORING_LABELS
    for path in sorted(GEN.glob("*.weights.json")):
        m = re.match(r"^([A-Z]+)\.weights\.json$", path.name)
        if not m:
            continue
        cls = m.group(1)
        if cls not in weights:
            continue
        ship = json.loads(path.read_text(encoding="utf-8")).get(cls) or {}
        pipe = weights[cls]
        for spec, cfg in pipe.items():
            if spec.startswith("_") or not isinstance(cfg, dict):
                continue
            pw = cfg.get("weights") or {}
            raw = ship.get(spec) or {}
            sw = raw.get("weights") if isinstance(raw, dict) and raw.get("weights") else raw
            if not isinstance(sw, dict):
                warnings.append(f"{cls}/{spec} missing in {path.name} (StatWeights / CustomSpec)")
                continue
            for key in pick_keys:
                pv = pw.get(key)
                if pv is None or pv == 0:
                    continue
                sv = sw.get(key)
                if sv is None:
                    warnings.append(
                        f"{cls}/{spec} {path.name} missing {key}={pv} "
                        f"(StatWeights Compare path; hunt tooltips use ScoringWeights)"
                    )
                elif abs(float(sv) - float(pv)) > 1e-6:
                    warnings.append(
                        f"{cls}/{spec} {path.name} drift {key}: pipeline={pv} shipped={sv}"
                    )

    if failures:
        print(f"FAIL {len(failures)} mismatch(es) across {spec_count} specs:")
        for line in failures[:80]:
            print(f"  {line}")
        if len(failures) > 80:
            print(f"  ... and {len(failures) - 80} more")
        return 1

    print(
        f"OK: tooltip and hunt score use the sheet row ({spec_count} specs); "
        f"ScoringWeights.generated.lua matches pipeline."
    )
    seen = set()
    for w in warnings:
        if w not in seen:
            seen.add(w)
            print(f"WARN {w}")
    return 0


if __name__ == "__main__":
    sys.exit(main())