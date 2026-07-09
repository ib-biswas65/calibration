param(
    [string]$RepoPath = "C:\Calibration"
)

Write-Host "=== Pulling latest code ==="
git -C $RepoPath pull origin main

Write-Host "=== Restarting Docker services ==="
Set-Location "$RepoPath\deploy-package"
docker compose pull
docker compose up -d --build

Write-Host "=== Deploy complete ==="
docker compose ps
