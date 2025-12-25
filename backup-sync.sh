#!/bin/bash
# Backup Sync Script for HestiaCP to Google Drive
# Syncs local backups to Google Drive: web-217-216-40-207/backups

LOG_FILE="/var/log/backup-sync.log"
BACKUP_DIR="/backup"
GDRIVE_REMOTE="gdrive:web-217-216-40-207/backups"

echo "=== Backup Sync Started: $(date) ===" >> "$LOG_FILE"

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo "ERROR: Backup directory $BACKUP_DIR does not exist" >> "$LOG_FILE"
    exit 1
fi

# Sync backups to Google Drive
echo "Syncing $BACKUP_DIR to $GDRIVE_REMOTE..." >> "$LOG_FILE"
/usr/bin/rclone sync "$BACKUP_DIR" "$GDRIVE_REMOTE" \
    --log-file="$LOG_FILE" \
    --log-level INFO \
    --stats 1m \
    --exclude "*.tmp" \
    --exclude "*.part"

if [ $? -eq 0 ]; then
    echo "SUCCESS: Backup sync completed at $(date)" >> "$LOG_FILE"
else
    echo "ERROR: Backup sync failed at $(date)" >> "$LOG_FILE"
    exit 1
fi

echo "=== Backup Sync Finished: $(date) ===" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
