# Sync GearQuest Forever addon files to a local WoW install.
# Run from repo root after making changes.
#
# Installs as Interface\AddOns\GearQuestForever (not GearQuest — that name is TBC Anniversary).
#
# Forever beta (default when present):
#   .\scripts\sync-addon.ps1
#
# Side-by-side test on TBC Anniversary (enable "Load out of date AddOns"; different Interface):
#   $env:GEARQUEST_WOW_CLIENT = "_anniversary_"
#   .\scripts\sync-addon.ps1
#
# Custom client folder name:
#   $env:GEARQUEST_WOW_CLIENT = "_forever_"

$ErrorActionPreference = "Stop"

$source = Join-Path $PSScriptRoot "..\GearQuest"
$wowRoot = "C:\Program Files (x86)\World of Warcraft"
$addonName = "GearQuestForever"

$clientCandidates = @(
    $env:GEARQUEST_WOW_CLIENT,
    "_forever_",
    "_forever_beta_",
    "_wow_forever_",
    "_classic_forever_"
) | Where-Object { $_ }

$clientFolder = $null
foreach ($name in $clientCandidates) {
    $candidate = Join-Path $wowRoot $name
    if (Test-Path $candidate) {
        $clientFolder = $candidate
        break
    }
}

if (-not $clientFolder) {
    $existing = @()
    if (Test-Path $wowRoot) {
        $existing = Get-ChildItem $wowRoot -Directory | Select-Object -ExpandProperty Name
    }
    $list = if ($existing) { $existing -join ", " } else { "(World of Warcraft folder not found)" }
    Write-Error @"
WoW client folder not found under $wowRoot
Looked for: $($clientCandidates -join ", ")
Installed folders: $list

Forever beta: install the client, then re-run this script.

To test on Anniversary next to TBC GearQuest (dev only):
  `$env:GEARQUEST_WOW_CLIENT = "_anniversary_"
  .\scripts\sync-addon.ps1
"@
}

$target = Join-Path $clientFolder "Interface\AddOns\$addonName"

if (-not (Test-Path $source)) {
    Write-Error "Source not found: $source"
}

if (-not (Test-Path (Join-Path $source "GearQuestForever.toc"))) {
    Write-Error "Missing GearQuestForever.toc in $source"
}

New-Item -ItemType Directory -Force -Path $target | Out-Null
Copy-Item -Path (Join-Path $source "*") -Destination $target -Recurse -Force

Write-Host "Synced GearQuest Forever -> $target"
Write-Host "In-game addon list: GearQuest Forever (folder $addonName). TBC GearQuest is a separate addon if installed."
