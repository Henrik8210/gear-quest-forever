/**
 * Scrape Classic random enchants (slow), apply to generated lua, report stale TBC rows.
 * Usage: node scripts/classic-suffix-sync.mjs [--retry-403] [--phase2-gate]
 */
import { spawnSync } from "child_process";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "..");

const retry403 = process.argv.includes("--retry-403");
const env = { ...process.env, GQ_SCRAPE_DELAY_MS: process.env.GQ_SCRAPE_DELAY_MS || "2500" };

function run(label, script, extraArgs = [], envExtra = null) {
  console.log("\n=== " + label + " ===\n");
  const r = spawnSync(process.execPath, [path.join(__dirname, script), ...extraArgs], {
    cwd: root,
    env: envExtra ? { ...env, ...envExtra } : env,
    stdio: "inherit",
    shell: false,
  });
  if (r.status !== 0 && label !== "Stale TBC suffix rows" && label !== "Era check (cache)") {
    process.exit(r.status ?? 1);
  }
  return r.status ?? 0;
}

const reprobeEmpty = process.argv.includes("--reprobe-empty");
run("Scrape Classic random enchants", "scrape-classic-random-enchants.mjs", [
  ...(retry403 ? ["--retry-403"] : []),
  ...(reprobeEmpty ? ["--reprobe-empty"] : []),
]);
run("Era fingerprint items (9640)", "scrape-classic-random-enchants.mjs", ["--ids=9640"]);
run("Apply Classic suffix metadata", "apply-classic-random-enchants.mjs", []);
run("Suffix Classic coverage", "count-suffix-coverage.mjs", []);
const phase2Gate = process.argv.includes("--phase2-gate") || process.env.GQ_PHASE2_COMPLETE === "1";
if (phase2Gate) {
  run("Phase 2 gate (80% scrapeable)", "count-suffix-coverage.mjs", [], { GQ_SUFFIX_COVERAGE_MIN: "80" });
}
run("Stale TBC suffix rows", "count-stale-tbc-suffix-rows.mjs", []);
run("Era check (cache)", "check-era-classic.mjs", []);
