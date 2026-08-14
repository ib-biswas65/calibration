#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# ITE Calibration — Backup (run on the machine hosting Docker)
#
# Dumps the PostgreSQL database and backs up the certificate volume to a
# timestamped directory. Keeps the last 30 days of backups automatically.
#
# Usage:
#   bash scripts/backup.sh
#   BACKUP_DIR=/mnt/usb/backups bash scripts/backup.sh
#
# Schedule (Mac/Linux cron — daily at 02:00):
#   0 2 * * * cd /path/to/Calibration && bash scripts/backup.sh >> /tmp/ite-backup.log 2>&1
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-$HOME/ite-calibration-backups}"
DATE=$(date +%Y%m%d_%H%M%S)
DEST="$BACKUP_DIR/$DATE"

mkdir -p "$DEST"

echo "[$(date)] Starting backup → $DEST"

# ── PostgreSQL dump ──────────────────────────────────────────────────────────
echo "  Dumping database..."
docker exec ite-calibration-postgres-1 \
  pg_dump -U ite --clean --if-exists ite \
  | gzip > "$DEST/db.sql.gz"
echo "  db.sql.gz: $(du -sh "$DEST/db.sql.gz" | cut -f1)"

# ── Certificate volume ───────────────────────────────────────────────────────
echo "  Backing up certificate volume..."
docker run --rm \
  -v ite-calibration_cal_data:/source:ro \
  -v "$DEST":/backup \
  alpine \
  tar czf /backup/cal_data.tar.gz -C /source .
echo "  cal_data.tar.gz: $(du -sh "$DEST/cal_data.tar.gz" | cut -f1)"

# ── Prune old backups (keep 30 days) ─────────────────────────────────────────
find "$BACKUP_DIR" -maxdepth 1 -type d -mtime +30 -exec rm -rf {} + 2>/dev/null || true

echo "[$(date)] Backup complete. Total: $(du -sh "$DEST" | cut -f1)"
