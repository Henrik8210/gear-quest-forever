"""Optional isolated heap/timing report; run with GQ_LAZY_TEST_ROOT set.

Includes maps and item facts in both trees. This is not a WoW memory meter.
"""
import json
import time
from support import Harness, ROOT


def measure(tree, cls):
    start = time.perf_counter()
    h = Harness(tree, cls)
    row = {"tree": tree, "class": cls,
           "module_and_index_ms": round((time.perf_counter() - start) * 1000, 2),
           "cold_MiB": h.memory()}
    h.lua.execute("function G.Equip:WithoutItemPrime(fn,...)return fn(...)end")
    row["candidates"] = h.lua.eval("QueryCycle()")
    row["warm_MiB"] = h.memory()
    start = time.perf_counter()
    for _ in range(10):
        assert h.lua.eval("QueryCycle()") == row["candidates"]
    row["mean_query_ms"] = round((time.perf_counter() - start) * 100, 3)
    row["after_10_queries_MiB"] = h.memory()
    h.module("GearQuestForever/Log.lua")
    h.g.Log.EnsureLookupIndex(h.g.Log, cls)
    row["lookup_open_MiB"] = h.memory()
    h.g.Log.ReleaseLookupIndex(h.g.Log)
    row["lookup_closed_MiB"] = h.memory()
    for _ in range(5):
        h.g.Log.EnsureLookupIndex(h.g.Log, cls)
        h.g.Log.ReleaseLookupIndex(h.g.Log)
    row["after_6_lookup_cycles_MiB"] = h.memory()
    return row


if __name__ == "__main__":
    results = [measure(tree, cls) for cls in ["WARRIOR", "MAGE"]
               for tree in ["source", "optimized"]]
    print(json.dumps(results, indent=2))
    (ROOT / "benchmark-results.json").write_text(json.dumps(results, indent=2))
