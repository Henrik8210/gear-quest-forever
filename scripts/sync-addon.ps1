# Sync GearQuest Forever addon files to the live WoW Forever client.
# Run from repo root after making changes.
#
#   .\scripts\sync-addon.ps1
#
# Copies into:
#   C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\GearQuestForever
# Class hunt addons land beside that folder. This script does not copy to any other client.

$ErrorActionPreference = "Stop"

$source = Join-Path $PSScriptRoot "..\GearQuest"
$wowRoot = "C:\Program Files (x86)\World of Warcraft"
$addonName = "GearQuestForever"
$clientFolder = Join-Path $wowRoot "_forever_"

if (-not (Test-Path $clientFolder)) {
    $existing = @()
    if (Test-Path $wowRoot) {
        $existing = Get-ChildItem $wowRoot -Directory | Select-Object -ExpandProperty Name
    }
    $list = if ($existing) { $existing -join ", " } else { "(World of Warcraft folder not found)" }
    Write-Error @"
WoW Forever client not found: $clientFolder
Installed folders: $list
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

$addonsRoot = Join-Path $clientFolder "Interface\AddOns"
python (Join-Path $PSScriptRoot "stage-class-addons.py") --dest $addonsRoot --main $target
if ($LASTEXITCODE -ne 0) {
    Write-Error "stage-class-addons.py failed"
}

Write-Host "Synced GearQuest Forever -> $target"
Write-Host "Class hunt data is a separate addon per class (loaded when you play or simulate that class)."
Write-Host "In-game addon list: GearQuest Forever (folder $addonName)."
