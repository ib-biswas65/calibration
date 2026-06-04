#Requires -RunAsAdministrator
<#
.SYNOPSIS
    ITE Calibration — First-time setup for Windows PC.

.DESCRIPTION
    Loads Docker images, restores the database and certificate files,
    then starts the application. Run this ONCE after copying deploy-package/
    to the Windows PC.

    Requirements:
      - Docker Desktop for Windows installed and running (https://docs.docker.com/desktop/install/windows/)
      - PowerShell 5+ (built into Windows 10/11)

.EXAMPLE
    Right-click setup-windows.ps1 → "Run with PowerShell"
    — or —
    powershell -ExecutionPolicy Bypass -File .\setup-windows.ps1
#>

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

function Write-Step($n, $msg) {
    Write-Host ""
    Write-Host "[$n] $msg" -ForegroundColor Cyan
}

function Wait-Healthy($container, $timeoutSec = 90) {
    $elapsed = 0
    while ($elapsed -lt $timeoutSec) {
        $status = (docker inspect --format "{{.State.Health.Status}}" $container 2>$null)
        if ($status -eq "healthy") { return }
        Start-Sleep -Seconds 3
        $elapsed += 3
    }
    Write-Error "Container $container did not become healthy in ${timeoutSec}s."
    exit 1
}

Write-Host "==================================================" -ForegroundColor Yellow
Write-Host "   ITE Calibration — Windows Setup               " -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Yellow

# ── Preflight checks ─────────────────────────────────────────────────────────
Write-Step "0" "Checking prerequisites..."

try { docker version | Out-Null }
catch {
    Write-Error "Docker is not running. Start Docker Desktop and try again."
    exit 1
}
Write-Host "    Docker: OK" -ForegroundColor Green

# ── .env setup ───────────────────────────────────────────────────────────────
Write-Step "1" "Configuring environment..."

$envFile = Join-Path $scriptDir ".env"
if (-not (Test-Path $envFile)) {
    Copy-Item (Join-Path $scriptDir ".env.example") $envFile
    Write-Host "    Created .env from .env.example" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    IMPORTANT: You must edit .env before continuing." -ForegroundColor Red
    Write-Host "    At minimum, change:" -ForegroundColor Red
    Write-Host "      POSTGRES_PASSWORD=<strong password>" -ForegroundColor Red
    Write-Host "      ITE_DATABASE_URL=postgresql+psycopg://ite:<same password>@postgres:5432/ite" -ForegroundColor Red
    Write-Host "      ITE_JWT_SECRET=<random 32+ char string>" -ForegroundColor Red
    Write-Host "      ITE_ALLOWED_ORIGINS=http://localhost" -ForegroundColor Red
    Write-Host ""
    Write-Host "    Opening .env in Notepad..." -ForegroundColor Yellow
    Start-Process notepad $envFile -Wait
}
Write-Host "    .env: OK" -ForegroundColor Green

# ── Load Docker images ────────────────────────────────────────────────────────
Write-Step "2" "Loading Docker images (this takes a minute)..."

foreach ($img in @("api", "web")) {
    $tarPath = Join-Path $scriptDir "images\$img.tar.gz"
    if (-not (Test-Path $tarPath)) {
        Write-Error "Missing image file: $tarPath"
        exit 1
    }
    Write-Host "    Loading $img..." -NoNewline
    Get-Content $tarPath -Encoding Byte -ReadCount 0 | docker load
    Write-Host " done" -ForegroundColor Green
}

# Pull nginx (small, from Docker Hub)
Write-Host "    Pulling nginx:1.27-alpine..." -NoNewline
docker pull nginx:1.27-alpine | Out-Null
Write-Host " done" -ForegroundColor Green

# ── Start PostgreSQL ──────────────────────────────────────────────────────────
Write-Step "3" "Starting PostgreSQL..."
docker compose up -d postgres
Write-Host "    Waiting for PostgreSQL to be healthy..."
Wait-Healthy "ite-calibration-postgres-1"
Write-Host "    PostgreSQL: ready" -ForegroundColor Green

# ── Restore database ──────────────────────────────────────────────────────────
Write-Step "4" "Restoring database (all calibration history)..."

$dbDump = Join-Path $scriptDir "seed\db_full.sql"
if (-not (Test-Path $dbDump)) {
    Write-Error "Missing database dump: $dbDump"
    exit 1
}

Get-Content $dbDump | docker exec -i ite-calibration-postgres-1 `
    psql -U ite -d ite -q

Write-Host "    Database restored" -ForegroundColor Green

# ── Restore certificate volume ────────────────────────────────────────────────
Write-Step "5" "Restoring certificate files..."

$calData = Join-Path $scriptDir "cal_data.tar.gz"
if (-not (Test-Path $calData)) {
    Write-Error "Missing volume backup: $calData"
    exit 1
}

# Use a temporary alpine container to unpack the tarball into the named volume.
# Docker bind-mount paths on Windows need forward slashes.
$scriptDirFwd = $scriptDir.Replace("\", "/")

docker run --rm `
    -v "ite-calibration_cal_data:/target" `
    -v "${scriptDirFwd}:/backup" `
    alpine `
    sh -c "cd /target && tar xzf /backup/cal_data.tar.gz"

Write-Host "    Certificate files restored" -ForegroundColor Green

# ── Start all services ────────────────────────────────────────────────────────
Write-Step "6" "Starting all services..."
docker compose up -d

# Wait a moment then verify
Start-Sleep -Seconds 5
$apiStatus = (docker inspect --format "{{.State.Status}}" ite-calibration-api-1 2>$null)
$webStatus = (docker inspect --format "{{.State.Status}}" ite-calibration-web-1 2>$null)

if ($apiStatus -eq "running" -and $webStatus -eq "running") {
    Write-Host "    All services running" -ForegroundColor Green
} else {
    Write-Host "    Some services may not have started. Check: docker compose logs" -ForegroundColor Yellow
}

# ── Done ──────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "   Setup complete!                               " -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
Write-Host "   Application:  http://localhost" -ForegroundColor White
Write-Host ""
Write-Host "   To stop:      docker compose down" -ForegroundColor Gray
Write-Host "   To start:     docker compose up -d" -ForegroundColor Gray
Write-Host "   To view logs: docker compose logs -f" -ForegroundColor Gray
Write-Host ""
Write-Host "   Services restart automatically when Windows boots." -ForegroundColor Gray
Write-Host ""
Write-Host "   IMPORTANT — Set up daily backups:" -ForegroundColor Yellow
Write-Host "   Run backup-windows.ps1 manually to test, then schedule it:" -ForegroundColor Yellow
Write-Host "   Task Scheduler → Daily 02:00 → powershell.exe -ExecutionPolicy Bypass -File .\backup-windows.ps1" -ForegroundColor Yellow
Write-Host "   Backups are saved to C:\ite-calibration-backups (change -BackupDir for USB drive)" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to close"
