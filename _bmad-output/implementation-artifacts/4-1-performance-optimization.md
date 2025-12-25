# Story 4.1: Performance Optimization

Status: ready-for-dev

## Story

As a Server Administrator,
I want to install Redis, configure PHP OPcache, and enable ModSecurity,
so that the server is performant and secure.

## Acceptance Criteria

1. [ ] Redis server is installed and running.
2. [ ] PHP Redis extension is installed and enabled for all active PHP versions.
3. [ ] PHP OPcache is configured with optimized settings (memory_consumption=128, interned_strings_buffer=8, max_accelerated_files=10000, revalidate_freq=60).
4. [ ] ModSecurity is enabled in HestiaCP.
5. [ ] Verification script confirms Redis connectivity and OPcache status.

## Tasks / Subtasks

- [ ] Install and Configure Redis (AC: 1, 2)
  - [ ] `ssh -i ~/.ssh/web-cmdev cmdev@217.216.40.207 "sudo apt-get update && sudo apt-get install redis-server php-redis -y"`
  - [ ] Verify Redis service status
- [ ] Configure PHP OPcache (AC: 3)
  - [ ] Update `php.ini` for active PHP versions (e.g., 8.1, 8.2, 8.3)
  - [ ] Restart PHP-FPM services
- [ ] Enable ModSecurity (AC: 4)
  - [ ] `ssh -i ~/.ssh/web-cmdev cmdev@217.216.40.207 "sudo /usr/local/hestia/bin/v-add-sys-modsecurity"` (Verify exact command)
- [ ] Verification (AC: 5)
  - [ ] Run `redis-cli ping`
  - [ ] Check `php -i | grep opcache`

## Dev Notes

- **Redis**: HestiaCP usually supports Redis out of the box but might need the PHP extension.
- **OPcache**: Settings should be applied to `/etc/php/{version}/fpm/php.ini`.
- **ModSecurity**: Hestia has a specific CLI command or web UI toggle.
- **SSH Key**: Use `~/.ssh/web-cmdev` for all remote commands.

### Project Structure Notes

- All scripts should be placed in `/opt/cfe-automation/scripts/` if they are to be reused.
- Logs should go to `/var/log/cfe-automation/`.

### References

- [Architecture: Caching](file:///home/cmdev/cmdev-antigravity/webserver-hestia/docs/architecture.md#L57)
- [PRD: FR3.2, FR3.3](file:///home/cmdev/cmdev-antigravity/webserver-hestia/docs/prd.md#L49-L50)

## Dev Agent Record

### Agent Model Used

Antigravity (Gemini 2.0 Flash)

### Debug Log References

### Completion Notes List

### File List
