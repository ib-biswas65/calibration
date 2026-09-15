<#
.SYNOPSIS
    ITE Calibration — Backup script for Windows deployment.

.DESCRIPTION
    Dumps the PostgreSQL database and certificate volume to a timestamped
    folder. Safe to run while the application is running.

    Schedule this with Windows Task Scheduler for automatic daily backups:
      1. Open Task Scheduler → Create Basic Task
      2. Trigger: Daily at 02:00
      3. Action: Start a program
         Program: powershell.exe
         Arguments: -ExecutionPolicy Bypass -File "C:\path\to\backup-windows.ps1"

.PARAMETER BackupDir
    Destination folder for backups. Defaults to C:\ite-calibration-backups.
    Set to a USB drive path (e.g. E:\Backups) for off-machine storage.

.EXAMPLE
    .\backup-windows.ps1
    .\backup-windows.ps1 -BackupDir "E:\Backups\ITE"
#>

param(
    [string]$BackupDir = "C:\ite-calibration-backups"
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# Preflight: ensure Docker is accessible (fails fast under Task Scheduler if not in docker-users group).
# Note: try/catch does NOT catch a failing native command in Windows PowerShell 5.1 (it only
# sets $LASTEXITCODE, it doesn't throw) — check the exit code directly or this never fires.
docker version | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker is not running or this account cannot reach Docker. Backup aborted."
    exit 1
}

$Date = Get-Date -Format "yyyyMMdd_HHmmss"
$Dest = Join-Path $BackupDir $Date
New-Item -ItemType Directory -Path $Dest -Force | Out-Null

Write-Host "[$(Get-Date)] Starting backup → $Dest" -ForegroundColor Cyan

# ── PostgreSQL dump ───────────────────────────────────────────────────────────
# Dump inside the container and docker cp the bytes out — piping through PowerShell's
# `>` redirect re-encodes as UTF-16 via the console codepage, which corrupts the
# Japanese text in certificate/batch data. This bit us for real: every nightly backup
# before 2026-09-16 has broken Japanese text because of that redirect.
Write-Host "  Dumping database..." -NoNewline
$dbOut = Join-Path $Dest "db.sql"
$tmp = "/tmp/db-$Date.sql"
docker exec ite-calibration-postgres-1 pg_dump -U ite --clean --if-exists -f $tmp ite
if ($LASTEXITCODE -ne 0) { throw "pg_dump failed" }
docker cp "ite-calibration-postgres-1:$tmp" $dbOut
if ($LASTEXITCODE -ne 0) { throw "docker cp failed" }
docker exec ite-calibration-postgres-1 rm $tmp
if ((Get-Item $dbOut).Length -eq 0) { throw "empty dump" }
# Compress with PowerShell built-in
Compress-Archive -Path $dbOut -DestinationPath "$dbOut.zip" -Force
Remove-Item $dbOut
Write-Host " done ($([Math]::Round((Get-Item "$dbOut.zip").Length / 1MB, 1)) MB)" -ForegroundColor Green

# ── Certificate volume ────────────────────────────────────────────────────────
Write-Host "  Backing up certificate volume..." -NoNewline
$destFwd = $Dest.Replace("\", "/")
docker run --rm `
    -v "ite-calibration_cal_data:/source:ro" `
    -v "${destFwd}:/backup" `
    alpine `
    tar czf /backup/cal_data.tar.gz -C /source .
if ($LASTEXITCODE -ne 0) { throw "certificate volume backup failed" }
Write-Host " done ($([Math]::Round((Get-Item (Join-Path $Dest "cal_data.tar.gz")).Length / 1MB, 1)) MB)" -ForegroundColor Green

# ── Prune backups older than 30 days ─────────────────────────────────────────
$cutoff = (Get-Date).AddDays(-30)
Get-ChildItem $BackupDir -Directory | Where-Object { $_.CreationTime -lt $cutoff } | ForEach-Object {
    Remove-Item $_.FullName -Recurse -Force
    Write-Host "  Pruned old backup: $($_.Name)" -ForegroundColor Gray
}

Write-Host "[$(Get-Date)] Backup complete → $Dest" -ForegroundColor Green
