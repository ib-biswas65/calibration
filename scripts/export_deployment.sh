#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# ITE Calibration — Deployment export (run on Mac)
#
# Bundles everything the Windows PC needs into deploy-package/:
#   - Docker images (api, web, edge) as .tar files
#   - Full PostgreSQL dump (schema + data)
#   - cal_data volume backup (all certificate files)
#   - docker-compose.prod.yml + nginx.conf + .env.example
#   - setup-windows.ps1 (run once on the Windows PC)
#
# Usage:
#   cd /path/to/Calibration
#   bash scripts/export_deployment.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPLOY_DIR="$PROJECT_ROOT/deploy-package"

echo "=== ITE Calibration — Deployment Export ==="
echo "Output: $DEPLOY_DIR"
echo

rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/images" "$DEPLOY_DIR/seed"

# ── 1. Build images for linux/amd64 (Windows Docker runs amd64 via WSL2) ──
echo "[1/5] Building Docker images for linux/amd64..."
docker buildx build \
  --platform linux/amd64 \
  --tag ite-calibration-api:latest \
  --load \
  "$PROJECT_ROOT/apps/api"

docker buildx build \
  --platform linux/amd64 \
  --tag ite-calibration-web:latest \
  --load \
  "$PROJECT_ROOT/apps/web"

# ── 2. Save images as tarballs ──────────────────────────────────────────────
echo "[2/5] Saving images to tarballs..."
docker save ite-calibration-api:latest | gzip > "$DEPLOY_DIR/images/api.tar.gz"
echo "      api.tar.gz: $(du -sh "$DEPLOY_DIR/images/api.tar.gz" | cut -f1)"

docker save ite-calibration-web:latest | gzip > "$DEPLOY_DIR/images/web.tar.gz"
echo "      web.tar.gz: $(du -sh "$DEPLOY_DIR/images/web.tar.gz" | cut -f1)"

# nginx:1.27-alpine is pulled by docker-compose on Windows — no need to bundle it

# ── 3. Export PostgreSQL database ───────────────────────────────────────────
echo "[3/5] Exporting PostgreSQL database..."
docker exec ite-calibration-postgres-1 \
  pg_dump -U ite --clean --if-exists ite \
  > "$DEPLOY_DIR/seed/db_full.sql"
echo "      db_full.sql: $(du -sh "$DEPLOY_DIR/seed/db_full.sql" | cut -f1)"

# ── 4. Back up cal_data volume ───────────────────────────────────────────────
echo "[4/5] Backing up certificate volume (cal_data)..."
docker run --rm \
  -v ite-calibration_cal_data:/source:ro \
  -v "$DEPLOY_DIR":/backup \
  alpine \
  tar czf /backup/cal_data.tar.gz -C /source .
echo "      cal_data.tar.gz: $(du -sh "$DEPLOY_DIR/cal_data.tar.gz" | cut -f1)"

# ── 5. Copy deployment files ─────────────────────────────────────────────────
echo "[5/5] Copying deployment configuration..."
cp "$PROJECT_ROOT/infra/docker-compose.prod.yml" "$DEPLOY_DIR/docker-compose.yml"
cp "$PROJECT_ROOT/infra/nginx.conf"              "$DEPLOY_DIR/nginx.conf"
cp "$PROJECT_ROOT/infra/.env.example"            "$DEPLOY_DIR/.env.example"
cp "$PROJECT_ROOT/infra/setup-windows.ps1"       "$DEPLOY_DIR/setup-windows.ps1"
cp "$PROJECT_ROOT/infra/backup-windows.ps1"      "$DEPLOY_DIR/backup-windows.ps1"

# ── Done ─────────────────────────────────────────────────────────────────────
echo
echo "=== Export complete ==="
echo
du -sh "$DEPLOY_DIR"
echo
echo "Next steps:"
echo "  1. Copy the entire deploy-package/ folder to the Windows PC (USB / shared drive / OneDrive)"
echo "  2. On the Windows PC: right-click setup-windows.ps1 → Run with PowerShell (as Administrator)"
echo "  3. App will be at http://localhost"
