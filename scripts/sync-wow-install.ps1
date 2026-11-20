# Copy dev GearQuest into the Forever WoW install (main + class data add-ons).
# Usage:
#   pwsh scripts/sync-wow-install.ps1
#   pwsh scripts/sync-wow-install.ps1 -WowRoot "C:\Program Files (x86)\World of Warcraft\_classic_beta_"

param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string[]]$WowRoots = @(
        "C:\Program Files (x86)\World of Warcraft\_forever_",
        "C:\Program Files (x86)\World of Warcraft\_classic_beta_",
        "C:\Program Files (x86)\World of Warcraft\_anniversary_"
    )
)

$src = Join-Path $RepoRoot "GearQuest"
if (-not (Test-Path $src)) { throw "Missing $src" }

$classMap = @{
    DRUID  = @("Data.Druid.generated.lua", "Data.Druid.Early.1to9.generated.lua")
    SHAMAN = @("Data.Shaman.generated.lua", "Data.Shaman.Early.1to9.generated.lua")
    HUNTER = @("Data.Hunter.generated.lua", "Data.Hunter.Early.1to9.generated.lua")
    MAGE   = @("Data.Mage.generated.lua", "Data.Mage.Early.1to9.generated.lua")
    PALADIN = @("Data.Paladin.generated.lua", "Data.Paladin.Early.1to9.generated.lua")
    PRIEST = @("Data.Priest.generated.lua", "Data.Priest.Early.1to9.generated.lua")
    ROGUE  = @("Data.Rogue.generated.lua", "Data.Rogue.Early.1to9.generated.lua")
    WARLOCK = @("Data.Warlock.generated.lua", "Data.Warlock.Early.1to9.generated.lua")
    WARRIOR = @("Data.Warrior.generated.lua", "Data.Warrior.Early.1to9.generated.lua")
}
$gen = Join-Path $src "_generated"

foreach ($WowRoot in $WowRoots) {
    if (-not (Test-Path $WowRoot)) {
        Write-Host "Skip missing client: $WowRoot"
        continue
    }
    $addons = Join-Path $WowRoot "Interface\AddOns"
    $main = Join-Path $addons "GearQuestForever"
    if (-not (Test-Path $addons)) {
        Write-Host "Skip no AddOns: $WowRoot"
        continue
    }

    Write-Host "`n=== $WowRoot ==="
    Write-Host "Main addon -> $main"
    robocopy $src $main /MIR /XD ".git" /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy failed $LASTEXITCODE" }

    foreach ($cls in $classMap.Keys) {
        $dest = Join-Path $addons "GearQuestForever_$cls"
        if (-not (Test-Path $dest)) { continue }
        foreach ($file in $classMap[$cls]) {
            $from = Join-Path $gen $file
            if (Test-Path $from) {
                Copy-Item -Force $from (Join-Path $dest $file)
                Write-Host "  $cls <- $file"
            }
        }
    }

    $sw = Join-Path $main "_generated\ScoringWeights.generated.lua"
    if (Test-Path $sw) {
        $bear = Select-String -Path $sw -Pattern "^\s+sta = " -Context 0,0 |
            Select-String -Pattern "bear" -NotMatch |
            Select-Object -First 1
        $rev = Select-String -Path $sw -Pattern "SCORING_WEIGHTS_REVISION"
        Write-Host "  $($rev.Line.Trim())"
        Write-Host "  (first sta= in bear block should be 0.72 raw in file)"
    }
}
Write-Host "`nDone."