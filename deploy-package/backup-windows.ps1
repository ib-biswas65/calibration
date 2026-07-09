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
try { docker version | Out-Null }
catch {
    Write-Error "Docker is not running or this account cannot reach Docker. Backup aborted."
    exit 1
}

$Date = Get-Date -Format "yyyyMMdd_HHmmss"
$Dest = Join-Path $BackupDir $Date
New-Item -ItemType Directory -Path $Dest -Force | Out-Null

Write-Host "[$(Get-Date)] Starting backup → $Dest" -ForegroundColor Cyan

# ── PostgreSQL dump ───────────────────────────────────────────────────────────
Write-Host "  Dumping database..." -NoNewline
$dbOut = Join-Path $Dest "db.sql"
docker exec ite-calibration-postgres-1 pg_dump -U ite --clean --if-exists ite > $dbOut
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
Write-Host " done ($([Math]::Round((Get-Item (Join-Path $Dest "cal_data.tar.gz")).Length / 1MB, 1)) MB)" -ForegroundColor Green

# ── Prune backups older than 30 days ─────────────────────────────────────────
$cutoff = (Get-Date).AddDays(-30)
Get-ChildItem $BackupDir -Directory | Where-Object { $_.CreationTime -lt $cutoff } | ForEach-Object {
    Remove-Item $_.FullName -Recurse -Force
    Write-Host "  Pruned old backup: $($_.Name)" -ForegroundColor Gray
}

Write-Host "[$(Get-Date)] Backup complete → $Dest" -ForegroundColor Green
