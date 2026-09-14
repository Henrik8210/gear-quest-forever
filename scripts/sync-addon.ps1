# Sync GearQuest Forever addon files to the local WoW Forever install.
# Run from repo root after making changes.
#
# Override the client folder if Battle.net uses a different name:
#   $env:GEARQUEST_WOW_CLIENT = "_forever_"
#   .\scripts\sync-addon.ps1

$ErrorActionPreference = "Stop"

$source = Join-Path $PSScriptRoot "..\GearQuest"
$wowRoot = "C:\Program Files (x86)\World of Warcraft"
$addonName = "GearQuest"

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
WoW Forever client folder not found under $wowRoot
Looked for: $($clientCandidates -join ", ")
Installed folders: $list

After the Sept 17 beta installs, set the folder name:
  `$env:GEARQUEST_WOW_CLIENT = "_folder_name_"
  .\scripts\sync-addon.ps1
"@
}

$target = Join-Path $clientFolder "Interface\AddOns\$addonName"

if (-not (Test-Path $source)) {
    Write-Error "Source not found: $source"
}

New-Item -ItemType Directory -Force -Path $target | Out-Null
Copy-Item -Path (Join-Path $source "*") -Destination $target -Recurse -Force

Write-Host "Synced GearQuest Forever -> $target"
