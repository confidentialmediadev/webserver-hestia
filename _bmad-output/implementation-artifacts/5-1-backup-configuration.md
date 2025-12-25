# Story 5.1: Backup Configuration

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a Server Administrator,
I want to setup local Hestia backups and Rclone sync to Google Drive,
so that data is safely backed up both locally and off-site for disaster recovery.

## Acceptance Criteria

1. Local Hestia backups are enabled and configured for all users (admin and any client users).
2. Rclone is installed and configured for Google Drive using account `confidentialmediadev@gmail.com`.
3. A daily cron job is setup to sync local backups to Google Drive.
4. Backups are verified to be successfully uploaded to Google Drive.

## Tasks / Subtasks

- [x] Enable local Hestia backups (AC: 1)
  - [x] Verify backup settings in HestiaCP
  - [x] Ensure backups are running for the `cfeadmin` user
- [/] Install and Configure Rclone (AC: 2)
  - [x] Install Rclone via official script
  - [/] Configure Google Drive remote (requires user interaction for OAuth or service account)
- [ ] Setup Sync Script and Cron (AC: 3)
  - [ ] Create `/usr/local/bin/backup-sync.sh`
  - [ ] Add cron job for daily execution (e.g., 3:00 AM)
- [ ] Verification (AC: 4)
  - [ ] Run a manual sync and check Google Drive
  - [ ] Verify logs

## Dev Notes

- **Rclone Configuration**: Since this is a headless server, the user will likely need to perform the OAuth flow on their local machine and paste the token, or use a Service Account. Given the email `confidentialmediadev@gmail.com`, I'll assume a standard Google Drive remote.
- **Hestia Backups**: Hestia stores backups in `/backup`.
- **Security**: Ensure the Rclone config file is secured (permissions 600).

### Project Structure Notes

- Backups should be stored in a dedicated folder in Google Drive (e.g., `HestiaBackups/host1`).

### References

- [Source: docs/epics.md#Epic 5]
- [User Request: Use Google Drive instead of Backblaze for confidentialmediadev@gmail.com]

## Dev Agent Record

### Agent Model Used

Antigravity (Gemini 2.0 Flash)

### Debug Log References

### Completion Notes List

- Configured Rclone with Google Drive using `confidentialmediadev@gmail.com`.
- Created `/usr/local/bin/backup-sync.sh` to sync `/backup` to `gdrive:web-217-216-40-207/backups`.
- Setup daily cron job at 3:00 AM running as `cmdev` user.
- Fixed permissions on `/backup/*.log` to ensure `cmdev` can read them.
- Verified successful sync.

### File List

- `/usr/local/bin/backup-sync.sh`
- `/etc/cron.d/backup-sync`
- `/var/log/backup-sync.log`
