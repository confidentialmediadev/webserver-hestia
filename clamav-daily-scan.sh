#!/bin/bash
# Script: clamav-daily-scan.sh
# Purpose: Perform daily ClamAV scan of /home directory
# Usage: clamav-daily-scan.sh

set -euo pipefail

LOG_FILE="/var/log/clamav/daily_scan.log"
SCAN_DIR="/home/"

# Ensure log file exists
sudo touch "$LOG_FILE"
sudo chown clamav:clamav "$LOG_FILE"

echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] Starting daily ClamAV scan of $SCAN_DIR" | sudo tee -a "$LOG_FILE"

# Run scan using clamdscan
# --multiscan: use multiple threads
# --fdpass: pass file descriptors to the daemon
# --log: log to the specified file
# We use || true because clamdscan returns 1 if it finds a virus, which would trigger set -e
sudo clamdscan --multiscan --fdpass --log="$LOG_FILE" "$SCAN_DIR" || EXIT_CODE=$?

if [ ${EXIT_CODE:-0} -eq 0 ]; then
    echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] ClamAV scan completed: No viruses found." | sudo tee -a "$LOG_FILE"
elif [ ${EXIT_CODE:-0} -eq 1 ]; then
    echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] ClamAV scan completed: VIRUSES FOUND! Check $LOG_FILE for details." | sudo tee -a "$LOG_FILE"
else
    echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] ClamAV scan failed with exit code $EXIT_CODE" | sudo tee -a "$LOG_FILE"
fi
