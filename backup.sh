#!/bin/bash
set -euo pipefail

# Minecraft server backup script
# Run manually or add to crontab:
#   crontab -e
#   0 */6 * * * /path/to/backup.sh >> /var/log/minecraft-backup.log 2>&1

BACKUP_DIR="./backups"
DATA_DIR="./data"
MAX_BACKUPS=10
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/minecraft_backup_${TIMESTAMP}.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "[$(date)] Starting backup..."

# Tell the server to save and disable autosave temporarily
docker exec minecraft-server rcon-cli save-all 2>/dev/null || true
sleep 5
docker exec minecraft-server rcon-cli save-off 2>/dev/null || true

# Create backup
tar -czf "$BACKUP_FILE" -C "$DATA_DIR" .

# Re-enable autosave
docker exec minecraft-server rcon-cli save-on 2>/dev/null || true

# Remove old backups (keep last N)
cd "$BACKUP_DIR"
ls -t minecraft_backup_*.tar.gz 2>/dev/null | tail -n +$((MAX_BACKUPS + 1)) | xargs -r rm --

echo "[$(date)] Backup complete: $BACKUP_FILE ($(du -h "$BACKUP_FILE" | cut -f1))"
