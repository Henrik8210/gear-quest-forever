#!/usr/bin/env python3
"""The ranking JSON matches the addon catalogs.

Usage: python scripts/ci/check_export_json.py
"""
from __future__ import annotations

import runpy
import sys
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[2] / "pipeline" / "scripts" / "export_bot_json.py"
sys.argv = [str(SCRIPT), "--check"]
runpy.run_path(str(SCRIPT), run_name="__main__")
