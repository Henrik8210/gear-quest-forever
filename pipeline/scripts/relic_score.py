"""Combat value for relics (Totem / Idol / Libram) from effect text."""
import re

# Specs that primarily cast in PvE — benefit from "mana reg while casting".
_CASTER_SPECS = {
    ("SHAMAN", "elemental"),
    ("SHAMAN", "restoration"),
    ("PRIEST", "holy"),
    ("PRIEST", "discipline"),
    ("PRIEST", "shadow"),
    ("MAGE", "arcane"),
    ("MAGE", "fire"),
    ("MAGE", "frost"),
    ("WARLOCK", "affliction"),
    ("WARLOCK", "demonology"),
    ("WARLOCK", "destruction"),
    ("DRUID", "balance"),
    ("DRUID", "restoration"),
    ("PALADIN", "holy"),
}

# Utility CD trims — small for DPS casters, modest for healers/enhancement.
_GROUNDING_CD_SPECS = {
    ("SHAMAN", "restoration"): 0.35,
    ("SHAMAN", "enhancement"): 0.12,
    ("SHAMAN", "enhancement_tank"): 0.22,
    ("SHAMAN", "elemental"): 0.04,
}


def relic_effect_text(it):
    parts = []
    for key in ("effects", "procs"):
        for line in it.get(key) or []:
            if line and line not in parts:
                parts.append(line)
    for flag in it.get("flags") or []:
        if isinstance(flag, str) and flag.startswith("unscored:"):
            parts.append(flag[9:])
    return " ".join(parts)


def score_relic(it, cls, spec, w):
    """Points in the same currency as stat weights (compare only within one slot)."""
    text = relic_effect_text(it)
    if not text:
        return 0.0

    low = text.lower()
    s = 0.0
    w = w or {}

    m = re.search(r"increases healing done by ([^b]+?) by up to (\d+)", low)
    if m:
        s += int(m.group(2)) * w.get("heal", w.get("sp", 1.0))

    m = re.search(r"increases the damage of (.+?) by up to (\d+)", low)
    if m:
        s += int(m.group(2)) * w.get("sp", 1.0)

    m = re.search(r"allows (\d+)% of your mana regeneration to continue while casting", low)
    if m and (cls, spec) in _CASTER_SPECS:
        pct = int(m.group(1))
        # Sustained casting mana — primary PvE value for elemental / other casters.
        s += pct * (
            w.get("mp5", 0.2) * 8.0
            + w.get("spi", 0.1) * 5.0
            + w.get("int", 0.3) * 2.0
        )

    m = re.search(r"reduces the cooldown of ([^.]+?) by (\d+)\s*sec", low)
    if m:
        sec = int(m.group(2))
        mult = _GROUNDING_CD_SPECS.get((cls, spec), 0.05)
        if "grounding" in m.group(1).lower():
            s += sec * mult
        else:
            s += sec * mult * 0.5

    if "lava burst" in low and cls == "SHAMAN" and spec == "elemental":
        # Rune unlock is strong but secondary to in-combat mana for levelling BiS.
        s += 12.0 * w.get("sp", 1.0)

    return s
