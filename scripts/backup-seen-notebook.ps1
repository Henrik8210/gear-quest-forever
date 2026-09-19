# Copy GearQuest Forever seenItems out of WoW WTF into this repo.
# WoW addons cannot write outside SavedVariables; this is the external backup.
#
# One shot (also run at the end of sync-addon.ps1):
#   .\scripts\backup-seen-notebook.ps1
#
# Keep watching for logout /reload flushes:
#   .\scripts\backup-seen-notebook.ps1 -Watch
#
# latest.lua is never replaced by a smaller notebook.

param(
    [switch]$Watch
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$destRoot = Join-Path $repoRoot "notebook\seenItems"
$snapshotDir = Join-Path $destRoot "snapshots"
$latestPath = Join-Path $destRoot "latest.lua"
$wowRoot = "C:\Program Files (x86)\World of Warcraft"
$foreverClients = @(
    $env:GEARQUEST_WOW_CLIENT,
    "_classic_beta_",
    "_forever_",
    "_forever_beta_",
    "_wow_forever_",
    "_classic_forever_"
) | Where-Object { $_ -and $_ -ne "_anniversary_" } | Select-Object -Unique

$clientPrefer = $foreverClients

function Get-SeenItemCount([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        return 0
    }
    $text = Get-Content -LiteralPath $Path -Raw -ErrorAction SilentlyContinue
    if (-not $text) {
        return 0
    }
    return [regex]::Matches($text, '\["id"\]\s*=\s*\d+').Count
}

function Get-NotebookSources {
    $clients = @()
    foreach ($name in $clientPrefer) {
        $folder = Join-Path $wowRoot $name
        if (Test-Path -LiteralPath $folder) {
            $clients += $folder
        }
    }
    if (-not $clients -and (Test-Path -LiteralPath $wowRoot)) {
        $clients = @(Get-ChildItem -LiteralPath $wowRoot -Directory | ForEach-Object { $_.FullName })
    }

    $files = @()
    foreach ($client in $clients) {
        $accountRoot = Join-Path $client "WTF\Account"
        if (-not (Test-Path -LiteralPath $accountRoot)) {
            continue
        }
        $files += Get-ChildItem -LiteralPath $accountRoot -Recurse -Filter "GearQuestForever.lua" -ErrorAction SilentlyContinue |
            Where-Object { $_.Directory.Name -eq "SavedVariables" }
    }
    return $files
}

function Backup-SeenNotebook {
    New-Item -ItemType Directory -Force -Path $destRoot | Out-Null
    New-Item -ItemType Directory -Force -Path $snapshotDir | Out-Null

    $sources = @(Get-NotebookSources)
    if (-not $sources) {
        Write-Host "No GearQuestForever.lua SavedVariables found under $wowRoot"
        return
    }

    $best = $null
    $bestCount = -1
    foreach ($file in $sources) {
        $count = Get-SeenItemCount $file.FullName
        if ($count -gt $bestCount) {
            $best = $file
            $bestCount = $count
        }
        Write-Host ("  {0}  ({1} ids)" -f $file.FullName, $count)
    }

    if (-not $best -or $bestCount -le 0) {
        Write-Host "Notebook sources exist but none have seenItems ids yet."
        return
    }

    $latestCount = Get-SeenItemCount $latestPath
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $snapshotPath = Join-Path $snapshotDir ("seenItems-{0}-{1}ids.lua" -f $stamp, $bestCount)

    if ($bestCount -ge $latestCount) {
        Copy-Item -LiteralPath $best.FullName -Destination $latestPath -Force
        if ($bestCount -gt $latestCount) {
            Copy-Item -LiteralPath $best.FullName -Destination $snapshotPath -Force
            Write-Host ("Updated latest.lua  {0} -> {1} ids" -f $latestCount, $bestCount)
        } else {
            Write-Host ("Kept latest.lua at {0} ids (source matched)" -f $bestCount)
        }
    } else {
        Write-Host ("Skipped shrink  source {0} ids < latest {1} ids" -f $bestCount, $latestCount)
    }

    Get-ChildItem -LiteralPath $snapshotDir -Filter "seenItems-*.lua" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -Skip 20 |
        Remove-Item -Force

    $repoCount = Get-SeenItemCount $latestPath
    if ($bestCount -eq $repoCount) {
        Write-Host ("1:1 OK  WTF {0} == repo {1}" -f $bestCount, $repoCount)
    } else {
        Write-Host ("1:1 GAP  WTF {0} vs repo {1}" -f $bestCount, $repoCount)
    }
}

Backup-SeenNotebook

if (-not $Watch) {
    return
}

Write-Host "Watching for WTF flushes (logout /reload). Ctrl+C to stop."
$lastWrite = $null
foreach ($file in @(Get-NotebookSources)) {
    if (-not $lastWrite -or $file.LastWriteTime -gt $lastWrite) {
        $lastWrite = $file.LastWriteTime
    }
}
while ($true) {
    $sources = @(Get-NotebookSources)
    $newest = $null
    foreach ($file in $sources) {
        if (-not $newest -or $file.LastWriteTime -gt $newest) {
            $newest = $file.LastWriteTime
        }
    }
    if ($newest -and (-not $lastWrite -or $newest -gt $lastWrite)) {
        Start-Sleep -Milliseconds 800
        Backup-SeenNotebook
        $lastWrite = $newest
    }
    Start-Sleep -Seconds 3
}
