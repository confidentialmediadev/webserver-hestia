# Story 4.2: Security Enhancements

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a Server Administrator,
I want to verify Fail2Ban jails and setup daily ClamAV scans,
so that the server is protected against brute-force attacks and malware.

## Acceptance Criteria

1. [x] Fail2Ban is active and monitoring SSH, Hestia, and Dovecot/Exim. (FR5.2)
2. [x] ClamAV is installed and performing daily scans of `/home/`. (FR5.3)
3. [x] Scan results are logged to `/var/log/clamav/daily_scan.log`.
4. [x] A cron job is established for the daily ClamAV scan.
5. [x] Verification script confirms Fail2Ban jail status and ClamAV scan schedule.

## Tasks / Subtasks

- [x] Verify Fail2Ban Configuration (AC: 1)
  - [x] Check status of `ssh-iptables`, `hestia-iptables`, `dovecot-iptables`, and `exim-iptables` jails.
  - [x] `ssh -i ~/.ssh/web-cmdev cmdev@217.216.40.207 "sudo fail2ban-client status"`
- [x] Configure Daily ClamAV Scans (AC: 2, 3, 4)
  - [x] Create a scan script `/opt/cfe-automation/scripts/clamav-daily-scan.sh`.
  - [x] Script should scan `/home/` and log to `/var/log/clamav/daily_scan.log`.
  - [x] Add a cron job to `/etc/cron.d/clamav-daily-scan` to run the script daily at 02:00 UTC.
- [x] Verification (AC: 5)
  - [x] Run the scan script manually to verify logging.
  - [x] Verify cron job is active.

## Dev Notes

- **Fail2Ban**: HestiaCP uses `iptables` for the firewall. Fail2Ban jails are usually pre-configured but should be verified.
- **ClamAV**: Ensure `clamav-daemon` is running. The scan script should use `clamscan` or `clamdscan` (preferred for performance if daemon is running).
- **SSH Key**: Use `~/.ssh/web-cmdev` for all remote commands.
- **Automation Path**: Place scripts in `/opt/cfe-automation/scripts/` as per architecture.

### Project Structure Notes

- Scripts: `/opt/cfe-automation/scripts/`
- Logs: `/var/log/cfe-automation/` or `/var/log/clamav/`
- Cron: `/etc/cron.d/`

### References

- [Architecture: Security](file:///home/cmdev/cmdev-antigravity/webserver-hestia/docs/architecture.md#L734)
- [PRD: FR5.2, FR5.3](file:///home/cmdev/cmdev-antigravity/webserver-hestia/docs/prd.md#L59-L60)
- [Project Context: SSH](file:///home/cmdev/cmdev-antigravity/webserver-hestia/docs/project-context.md#L5)

## Dev Agent Record

### Agent Model Used

Antigravity (Gemini 2.0 Flash)

### Debug Log References

### Completion Notes List

### File List
