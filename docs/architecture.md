# Architecture

## Executive Summary

CFE Web Host 26 (Webserver Hestia) is built on **HestiaCP control panel** as the foundational infrastructure layer, extended with custom automation scripts and Ansible-based configuration management. The architecture leverages HestiaCP's proven hosting stack (Nginx, PHP-FPM, MariaDB, Exim4/Dovecot email) while adding infrastructure-as-code patterns for repeatability, automated provisioning workflows, and multi-runtime capabilities.

## Project Initialization

The first implementation story establishes the base infrastructure:

### Initial Server Setup

```bash
# Step 1: Provision Contabo VPS
# - 4 CPU / 8GB RAM, US Central location
# - Ubuntu 24.04 LTS or Debian 11
# - Configure SSH key-based authentication

# Step 2: Install HestiaCP
wget https://raw.githubusercontent.com/hestiacp/hestiacp/release/install/hst-install.sh
bash hst-install.sh --nginx yes --apache no --phpfpm yes --mysql yes \
  --exim yes --dovecot yes --clamav yes --spamassassin yes \
  --iptables yes --fail2ban yes
```

### Decisions Provided by HestiaCP

This base installation automatically establishes:
- **Web Server:** Nginx (optimized for WordPress)
- **PHP Runtime:** PHP-FPM with multiple version support
- **Database:** MariaDB 10.6+
- **Email Stack:** Exim4 + Dovecot + SpamAssassin + ClamAV
- **DNS:** BIND9 DNS server
- **Security:** Fail2Ban + iptables firewall
- **SSL:** Let's Encrypt integration
- **Control Panel:** Web interface on port 8083

## Decision Summary

| Category | Decision | Version | Affects FR Categories | Rationale |
| -------- | -------- | ------- | --------------------- | --------- |
| Control Panel | HestiaCP | 1.9.4 | All infrastructure FRs (FR1-FR8, FR15-FR23) | Open-source, proven hosting stack, WordPress-optimized, includes web/email/DNS |
| Operating System | Ubuntu LTS | 24.04 LTS | All FRs | HestiaCP 1.9.4 supported, newer LTS (2024), 5-year support, stable |
| Web Server | Nginx | 1.28.0 (stable) | Website Hosting (FR15-FR23) | Primary web server, WordPress optimized, reverse proxy capable |
| PHP Runtime | PHP-FPM | 8.1+ (multi-version) | Website Hosting (FR18-FR22) | Process isolation, performance, WordPress compatibility |
| Database | MariaDB | 11.4 LTS | Website Hosting (FR21) | 3-year LTS support, MySQL-compatible, WordPress proven |
| Email Stack | Exim4 + Dovecot | HestiaCP managed | Email Services (FR29-FR38) | Complete MTA/IMAP stack with spam/virus filtering |
| DNS Strategy | BIND9 + Cloudflare (Hybrid) | HestiaCP managed BIND9 | DNS Management (FR39-FR42) | BIND9 for traditional nameservers, Cloudflare option for DDoS protection |
| SSL/TLS | Let's Encrypt | HestiaCP managed | SSL Certificate (FR24-FR28) | Free, auto-renewal, widely trusted |
| Backup Solution | restic + rclone | restic 0.18.1, rclone latest | Backup & DR (FR43-FR51) | Encrypted, incremental, deduplication, excellent B2 integration |
| Off-site Storage | Backblaze B2 | API v2 | Backup & DR (FR45-FR46) | Cost-effective ($0.005/GB/month), S3-compatible |
| Configuration Mgmt | Ansible | 11.1.0 | Automation (FR66-FR70) | Infrastructure-as-code, idempotent, version-controlled playbooks |
| Monitoring | Netdata | 2.2.0 | Monitoring & Alerting (FR58-FR65) | Real-time metrics, lightweight, auto-configured |
| Node.js Process Mgmt | PM2 | 6.0.14 | Multi-Runtime (FR71-FR72) | Auto-restart, cluster mode, production-ready |
| Reverse Proxy | Nginx Proxy | 1.28.0 | Multi-Runtime (FR75-FR76) | Already installed, proven for mixed PHP/Node.js apps |
| Security | Fail2Ban + iptables + Cloudflare | HestiaCP managed | Security (FR77-FR83, FR84-FR87) | Intrusion prevention, firewall, DDoS protection |
| Caching | Redis | HestiaCP managed | Performance optimization | WordPress object cache, session storage |
| Scripting Language | Bash | 5.1+ (Ubuntu default) | All automation scripts | Universal, HestiaCP standard, Ansible compatible, server-focused |

## Cross-Cutting Concerns

### Error Handling Strategy

**Script Execution:**
- All bash scripts use `set -euo pipefail` (exit on error, undefined vars, pipe failures)
- Explicit exit codes: 0=success, 1=general error, 2=usage error, 3=dependency missing
- Trap handlers for cleanup on script failure
- Critical operations create snapshots/backups before making changes

**Idempotency:**
- Scripts check current state before making changes (safe to re-run)
- Example: "Check if user exists before creating user"
- No side effects from multiple executions

**Rollback Capability:**
- Migration operations: Create HestiaCP backup before starting
- Configuration changes: Git commit before applying changes
- Database changes: mysqldump before schema modifications

**Notification:**
- Email alerts on critical failures (backup failed, service down, disk >90%)
- Log all errors to `/var/log/cfe-automation/errors.log`
- Netdata alerts for infrastructure issues

### Logging Strategy

**Centralized Logging:**
- System services: syslog (standard HestiaCP logging)
- Custom automation: `/var/log/cfe-automation/` with daily rotation
- Log retention: 30 days minimum (NFR-M2 requirement)

**Log Format:**
```bash
[YYYY-MM-DD HH:MM:SS UTC] [script-name] [LEVEL] message
# Example:
[2025-01-28 14:32:10 UTC] [provision-site.sh] [INFO] Creating HestiaCP user: client1
[2025-01-28 14:32:15 UTC] [provision-site.sh] [ERROR] Failed to create database: connection timeout
```

**Log Levels:**
- **ERROR:** Script failures, service outages, critical issues
- **WARN:** Non-critical issues, deprecated features, approaching limits
- **INFO:** Normal operations, successful completions, state changes
- **DEBUG:** Detailed execution flow (disabled by default)

**Log Rotation:**
- Daily rotation via logrotate
- Compress logs older than 7 days
- Delete logs older than 30 days

### Authentication & Access Control

**SSH Access:**
- Key-based authentication only (NFR-S2)
- No password authentication: `PasswordAuthentication no` in sshd_config
- Root login disabled: `PermitRootLogin no`
- Fail2Ban monitoring SSH brute force attempts

**HestiaCP Admin:**
- Strong password (16+ characters, mixed case, numbers, symbols)
- 2FA recommended (HestiaCP supports TOTP)
- Session timeout: 30 minutes (NFR-S6)
- Admin access logged

**Automation Service Account:**
- Separate Linux user: `cfe-automation` (not root)
- Sudo permissions limited to HestiaCP CLI commands
- SSH key for Ansible automation
- No shell login for service account

**API & CLI Access:**
- HestiaCP CLI via sudo for user/site provisioning
- API keys stored in Ansible Vault (encrypted)
- Backblaze B2 keys in environment variables, not scripts

### Date/Time Handling

**Server Timezone:**
- UTC for all system operations (NFR consistency)
- No timezone conversions in automation scripts

**Timestamp Format:**
- ISO 8601: `YYYY-MM-DD HH:MM:SS` for logs and human-readable output
- Unix epoch for programmatic operations
- Backup filenames: `backup-YYYY-MM-DD-HHMMSS-UTC.tar.gz`

**Backup Timestamps:**
- All backup files use UTC timestamps in filename
- restic snapshots automatically timestamped in UTC
- Consistency across off-site and local backups

### Configuration Management

**Version Control:**
- Git repository: `/opt/cfe-automation/` (all scripts and playbooks)
- Commit messages follow conventional commits format
- Branch strategy: main (production), develop (testing)

**Secrets Management:**
- Ansible Vault for sensitive data (passwords, API keys)
- Environment variables for runtime secrets (not hardcoded)
- `.env` files excluded from git (`.gitignore`)
- HestiaCP admin password stored in password manager (not in scripts)

**Environment Separation:**
- Production: Contabo VPS (live hosting)
- Development/Testing: Local VM or separate VPS (optional)
- Configuration files: `config.prod.yml`, `config.dev.yml`

**Change Management:**
- Test Ansible playbooks on local VM before production
- Document changes in git commit messages
- Rollback via `git revert` or `git checkout` previous version

### Testing Strategy

**Pre-Deployment Testing:**
- Ansible playbooks: Test on local VirtualBox/Vagrant VM
- Syntax check: `ansible-playbook --syntax-check playbook.yml`
- Dry-run mode: `ansible-playbook --check playbook.yml`

**Backup Verification:**
- Weekly automated restore test (sample WordPress site)
- Verify restic snapshots: `restic check --read-data-subset=5%`
- Test restoration from Backblaze B2 monthly

**Migration Validation Checklist:**
Per site migrated from cPanel:
- [ ] WordPress loads correctly (homepage, admin dashboard)
- [ ] All plugins active (Elementor, JetEngine, WP Geo Directory)
- [ ] SSL certificate valid and auto-renewing
- [ ] Email accounts working (send/receive test)
- [ ] DNS propagation complete (dig verification)
- [ ] Performance acceptable (<2s uncached page load)

**Monitoring Validation:**
- Test alert notifications monthly (trigger test alert)
- Verify backup job monitoring detects failures
- Validate disk space alerts trigger at 90%

## Project Structure

This infrastructure platform has two distinct directory trees: the **server infrastructure** (managed by HestiaCP) and the **automation repository** (version-controlled scripts and playbooks).

### Server Directory Structure (Contabo VPS)

```
/
├── etc/
│   ├── hestia/                       # HestiaCP configuration
│   │   ├── hestia.conf               # Main HestiaCP config
│   │   ├── nginx/                    # Nginx configs per domain
│   │   ├── php-fpm/                  # PHP-FPM pool configs
│   │   └── dns/                      # BIND9 zone files
│   ├── nginx/
│   │   ├── nginx.conf                # Global Nginx config
│   │   └── conf.d/                   # Additional configs
│   ├── mysql/
│   │   └── mariadb.conf.d/           # MariaDB configuration
│   └── redis/
│       └── redis.conf                # Redis configuration
│
├── home/
│   ├── admin/                        # HestiaCP admin user home
│   ├── client1/                      # Tenant 1 (multi-tenant isolation)
│   │   ├── web/                      # Website document roots
│   │   │   ├── domain1.com/
│   │   │   │   └── public_html/      # WordPress installation
│   │   │   └── domain2.com/
│   │   ├── mail/                     # Email storage
│   │   └── tmp/                      # Temp files
│   ├── client2/                      # Tenant 2
│   └── cfe-automation/               # Automation service account
│       └── .ssh/                     # SSH keys for Ansible
│
├── opt/
│   ├── cfe-automation/               # Custom automation repository
│   │   ├── ansible/
│   │   │   ├── playbooks/
│   │   │   │   ├── server-setup.yml
│   │   │   │   ├── backup-config.yml
│   │   │   │   ├── provision-site.yml
│   │   │   │   └── migration.yml
│   │   │   ├── roles/
│   │   │   │   ├── hestiacp/
│   │   │   │   ├── backup/
│   │   │   │   ├── monitoring/
│   │   │   │   └── wordpress/
│   │   │   ├── inventory/
│   │   │   │   ├── production.yml
│   │   │   │   └── development.yml
│   │   │   └── group_vars/
│   │   │       └── all.yml           # Ansible variables
│   │   ├── scripts/
│   │   │   ├── provision-site.sh     # Create WordPress site
│   │   │   ├── provision-email.sh    # Create email account
│   │   │   ├── backup-offsite.sh     # restic + rclone backup
│   │   │   ├── migrate-cpanel.sh     # cPanel migration helper
│   │   │   └── healthcheck.sh        # System health checks
│   │   ├── config/
│   │   │   ├── config.prod.yml       # Production configuration
│   │   │   ├── backup-config.yml     # Backup job configuration
│   │   │   └── .env.example          # Environment variable template
│   │   ├── docs/
│   │   │   ├── migration-runbook.md
│   │   │   ├── disaster-recovery.md
│   │   │   └── operations.md
│   │   └── README.md
│   └── pm2/                          # PM2 Node.js apps (Phase 2+)
│       └── apps/
│
├── var/
│   ├── backup/
│   │   ├── local/                    # 7-day local backups (HestiaCP)
│   │   └── restic/                   # restic repository (before B2 upload)
│   ├── log/
│   │   ├── hestia/                   # HestiaCP logs
│   │   ├── nginx/                    # Web server access/error logs
│   │   ├── mysql/                    # Database logs
│   │   ├── exim4/                    # Email server logs
│   │   └── cfe-automation/           # Custom automation logs
│   │       ├── provision.log
│   │       ├── backup.log
│   │       ├── errors.log
│   │       └── archive/              # Rotated logs
│   └── lib/
│       └── mysql/                    # MariaDB data directory
│
└── usr/
    └── local/
        └── hestia/                   # HestiaCP installation
            ├── bin/                  # HestiaCP CLI tools
            └── web/                  # HestiaCP web interface
```

### Automation Repository Structure (Git)

This repository lives at `/opt/cfe-automation/` on the server and is version-controlled:

```
cfe-automation/
├── .git/                             # Git version control
├── .gitignore                        # Exclude secrets, logs
├── README.md                         # Repository documentation
├── ansible/
│   ├── ansible.cfg                   # Ansible configuration
│   ├── playbooks/
│   │   ├── 00-server-init.yml        # Initial server setup
│   │   ├── 01-hestiacp-install.yml   # HestiaCP installation
│   │   ├── 02-backup-setup.yml       # Configure restic + B2
│   │   ├── 03-monitoring-setup.yml   # Install Netdata
│   │   ├── 04-security-hardening.yml # SSH, firewall, Fail2Ban
│   │   ├── provision-wordpress.yml   # New WordPress site
│   │   ├── provision-email.yml       # Email account creation
│   │   └── migrate-from-cpanel.yml   # cPanel migration
│   ├── roles/
│   │   ├── hestiacp/
│   │   │   ├── tasks/
│   │   │   ├── templates/
│   │   │   └── defaults/
│   │   ├── backup/
│   │   │   ├── tasks/
│   │   │   └── files/
│   │   ├── monitoring/
│   │   ├── wordpress-optimize/
│   │   └── nodejs-runtime/           # Phase 2: Node.js support
│   ├── inventory/
│   │   └── production.yml            # Server inventory
│   ├── group_vars/
│   │   └── all.yml                   # Global variables
│   └── vault/
│       └── secrets.yml               # Encrypted secrets (Ansible Vault)
├── scripts/
│   ├── provision-site.sh             # Wrapper: HestiaCP user + site + email + SSL
│   ├── provision-email.sh            # Create email account via HestiaCP CLI
│   ├── backup-offsite.sh             # restic backup + rclone sync to B2
│   ├── restore-site.sh               # Restore from backup
│   ├── migrate-cpanel-site.sh        # Migrate single site from cPanel
│   ├── healthcheck.sh                # System health validation
│   ├── dns-update-cloudflare.sh      # Update Cloudflare DNS via API
│   └── lib/
│       ├── common.sh                 # Shared functions (logging, error handling)
│       └── hestia-api.sh             # HestiaCP CLI wrapper functions
├── config/
│   ├── config.prod.yml               # Production configuration
│   ├── backup-config.yml             # Backup retention, schedules
│   ├── monitoring-alerts.yml         # Netdata alert thresholds
│   └── .env.example                  # Environment template (copy to .env)
├── docs/
│   ├── architecture.md               # This document (symlink from /docs)
│   ├── migration-runbook.md          # Step-by-step migration guide
│   ├── disaster-recovery.md          # DR procedures
│   ├── operations.md                 # Common operations
│   └── troubleshooting.md            # Common issues
└── tests/
    ├── test-provision.sh             # Test site provisioning
    ├── test-backup.sh                # Test backup/restore
    └── test-migration.sh             # Test cPanel migration

```

### FR Category to Architecture Mapping

Since epics haven't been created yet, here's how functional requirement categories map to architecture components:

| FR Category | Architecture Components | Primary Location |
|-------------|------------------------|------------------|
| Infrastructure & Server (FR1-FR8) | HestiaCP, Ubuntu, Nginx, MariaDB | `/etc/hestia/`, `/etc/nginx/`, `/etc/mysql/` |
| User & Tenant Management (FR9-FR14) | HestiaCP user accounts, PHP-FPM pools | `/home/{username}/`, `/etc/php/*/fpm/pool.d/` |
| Website Hosting (FR15-FR23) | Nginx vhosts, PHP-FPM, WordPress | `/home/{user}/web/{domain}/public_html/` |
| SSL Certificate (FR24-FR28) | Let's Encrypt via HestiaCP | `/usr/local/hestia/ssl/`, HestiaCP cron |
| Email Services (FR29-FR38) | Exim4, Dovecot, Roundcube | `/etc/exim4/`, `/etc/dovecot/`, `/home/{user}/mail/` |
| DNS Management (FR39-FR42) | BIND9, Cloudflare API | `/etc/hestia/dns/`, `/opt/cfe-automation/scripts/dns-*` |
| Backup & DR (FR43-FR51) | restic, rclone, HestiaCP backup | `/var/backup/`, `/opt/cfe-automation/scripts/backup-*` |
| Migration (FR52-FR57) | Custom migration scripts | `/opt/cfe-automation/scripts/migrate-*`, `/opt/cfe-automation/ansible/playbooks/migrate-*` |
| Monitoring & Alerting (FR58-FR65) | Netdata, custom healthchecks | Netdata web UI (port 19999), `/opt/cfe-automation/scripts/healthcheck.sh` |
| Automation & Provisioning (FR66-FR70) | Ansible playbooks, bash scripts | `/opt/cfe-automation/ansible/`, `/opt/cfe-automation/scripts/` |
| Multi-Runtime Support (FR71-FR76) | PM2, Nginx reverse proxy | `/opt/pm2/`, `/etc/nginx/conf.d/proxy-*.conf` |
| Security & Compliance (FR77-FR83) | Fail2Ban, iptables, SSH config | `/etc/fail2ban/`, `/etc/ssh/sshd_config`, `/etc/iptables/` |
| Cloudflare Integration (FR84-FR87) | Cloudflare API scripts | `/opt/cfe-automation/scripts/dns-update-cloudflare.sh` |

### Integration Points

**HestiaCP CLI Integration:**
- Automation scripts call HestiaCP CLI: `/usr/local/hestia/bin/v-*` commands
- Examples: `v-add-user`, `v-add-domain`, `v-add-mail-account`, `v-add-database`
- Wrapper functions in `/opt/cfe-automation/scripts/lib/hestia-api.sh`

**Backup Integration:**
- HestiaCP local backups: `/var/backup/local/` (7-day retention)
- restic repository: `/var/backup/restic/` (before off-site upload)
- rclone sync to Backblaze B2: Daily cron job runs `/opt/cfe-automation/scripts/backup-offsite.sh`

**Monitoring Integration:**
- Netdata auto-discovers HestiaCP services (Nginx, MariaDB, PHP-FPM, Exim, Dovecot)
- Custom healthcheck: `/opt/cfe-automation/scripts/healthcheck.sh` (cron every 15 min)
- Alerts via email (configured in Netdata)

**DNS Integration:**
- BIND9 managed by HestiaCP for traditional nameservers
- Cloudflare API for clients using Cloudflare DNS
- Script: `/opt/cfe-automation/scripts/dns-update-cloudflare.sh`

**Multi-Runtime Integration (Phase 2+):**
- PM2 manages Node.js apps: `/opt/pm2/apps/`
- Nginx reverse proxy routes requests: `/etc/nginx/conf.d/proxy-{app}.conf`
- WordPress on PHP-FPM, Next.js on PM2, same server

## Implementation Patterns

These patterns ensure AI agents write compatible, consistent code across all automation scripts and configurations.

### Naming Patterns

**Script Filenames:**
- Format: `{action}-{target}.sh` (lowercase, hyphen-separated)
- Examples: `provision-site.sh`, `backup-offsite.sh`, `migrate-cpanel-site.sh`
- Location: `/opt/cfe-automation/scripts/`

**Ansible Playbook Filenames:**
- Format: `{sequence}-{action}.yml` (numbered for order)
- Examples: `00-server-init.yml`, `01-hestiacp-install.yml`, `provision-wordpress.yml`
- Location: `/opt/cfe-automation/ansible/playbooks/`

**Configuration Filenames:**
- Format: `{purpose}-{environment}.yml` or `{purpose}-config.yml`
- Examples: `config.prod.yml`, `backup-config.yml`, `monitoring-alerts.yml`
- Location: `/opt/cfe-automation/config/`

**HestiaCP User Accounts:**
- Format: lowercase, no special characters except hyphen
- Examples: `client1`, `geodir-sites`, `personal-sites`
- Rationale: HestiaCP username restrictions

**Domain Naming:**
- Format: standard FQDN (lowercase)
- Examples: `example.com`, `site1.example.com`
- No www prefix in HestiaCP (www handled by DNS CNAME)

### Structure Patterns

**Script Organization:**
- Main scripts: `/opt/cfe-automation/scripts/{script-name}.sh`
- Shared libraries: `/opt/cfe-automation/scripts/lib/{library-name}.sh`
- All scripts source common libraries: `source "$(dirname "$0")/lib/common.sh"`
- Executable bit set: `chmod +x` for all `.sh` files

**Ansible Organization:**
- Playbooks by sequence: `00-`, `01-`, `02-` for initialization order
- Playbooks by function: `provision-`, `migrate-`, `backup-` for operations
- Roles by component: `hestiacp/`, `backup/`, `monitoring/`, `wordpress/`
- Tasks follow Ansible best practices (one task per action, idempotent)

**Log Organization:**
- System logs: `/var/log/{service}/` (standard Linux FHS)
- Custom logs: `/var/log/cfe-automation/{operation}.log`
- Archived logs: `/var/log/cfe-automation/archive/`
- Log naming: `{operation}-YYYY-MM-DD.log` after rotation

**Backup Organization:**
- Local HestiaCP backups: `/var/backup/local/{username}/`
- restic repository: `/var/backup/restic/`
- Backblaze B2 bucket structure: `{bucket-name}/{hostname}/{username}/`
- Backup filename format: `{username}-{date}-{time}.tar.gz` (HestiaCP standard)

### Format Patterns

**Script Output Format:**
```bash
[YYYY-MM-DD HH:MM:SS UTC] [script-name] [LEVEL] message
```
- Levels: ERROR, WARN, INFO, DEBUG
- Always include timestamp in UTC
- Script name without `.sh` extension

**HestiaCP CLI Command Format:**
```bash
sudo /usr/local/hestia/bin/v-{action}-{resource} {username} {resource-params}
```
- Examples: `v-add-user client1 password email`, `v-add-domain client1 example.com`
- Always use absolute path to CLI binary
- Check exit code: `if [ $? -eq 0 ]; then ...`

**Configuration File Format:**
- YAML for Ansible and structured config
- ENV for environment variables (`.env` file, not committed)
- Bash variables for script-local config (sourced from lib/common.sh)

**Date/Time Format:**
- Logs: ISO 8601 `YYYY-MM-DD HH:MM:SS` (UTC)
- Filenames: `YYYY-MM-DD-HHMMSS` (no spaces, for filesystem safety)
- Programmatic: Unix epoch (seconds since 1970-01-01)

### Communication Patterns

**Error Reporting:**
- Log to `/var/log/cfe-automation/errors.log`
- Email critical errors to admin (via Netdata or mail command)
- Exit with appropriate code (1=general error, 2=usage, 3=dependency)
- Include context: what failed, why, what action was being attempted

**Success Confirmation:**
- Log successful operations at INFO level
- Return exit code 0 on success
- Output summary of what was accomplished (for human verification)

**Script Invocation:**
- Ansible playbooks invoke bash scripts via `command` or `shell` module
- Bash scripts invoke HestiaCP CLI via `sudo` with specific permissions
- Manual invocation: always from `/opt/cfe-automation/scripts/` directory
- Cron jobs: absolute paths, redirect output to log files

### Lifecycle Patterns

**Idempotency Pattern:**
```bash
# Example: Check before create
if ! /usr/local/hestia/bin/v-list-user "$USERNAME" &>/dev/null; then
    /usr/local/hestia/bin/v-add-user "$USERNAME" "$PASSWORD" "$EMAIL"
else
    echo "User $USERNAME already exists, skipping creation"
fi
```

**Error Handling Pattern:**
```bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

trap 'echo "Error on line $LINENO"' ERR
trap 'cleanup_temp_files' EXIT
```

**Backup Before Modify Pattern:**
```bash
# Before critical operations
/usr/local/hestia/bin/v-backup-user "$USERNAME"
# Or for config files
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak.$(date +%Y%m%d-%H%M%S)
```

**Retry Pattern (for network operations):**
```bash
retry_count=0
max_retries=3
until rclone sync /var/backup/restic/ b2:bucket-name/ || [ $retry_count -eq $max_retries ]; do
    retry_count=$((retry_count + 1))
    echo "Retry $retry_count/$max_retries"
    sleep 10
done
```

### Location Patterns

**Automation Code Location:**
- All automation lives in: `/opt/cfe-automation/`
- Never in `/root/`, `/home/admin/`, or scattered locations
- Git repository initialized at `/opt/cfe-automation/`

**WordPress Installation Paths:**
- Format: `/home/{username}/web/{domain}/public_html/`
- Example: `/home/client1/web/example.com/public_html/`
- HestiaCP standard, do not deviate

**Email Storage Paths:**
- Format: `/home/{username}/mail/{domain}/`
- Example: `/home/client1/mail/example.com/user@example.com/`
- Dovecot maildir format

**SSL Certificate Paths:**
- Let's Encrypt certs: `/usr/local/hestia/ssl/{domain}/`
- Auto-renewed by HestiaCP, do not manage manually

**Node.js Application Paths (Phase 2+):**
- Format: `/opt/pm2/apps/{app-name}/`
- PM2 ecosystem file: `/opt/pm2/apps/{app-name}/ecosystem.config.js`
- Logs: `/opt/pm2/logs/{app-name}/`

### Consistency Patterns

**Bash Script Header:**
```bash
#!/bin/bash
# Script: {script-name}
# Purpose: {brief description}
# Usage: {script-name} [args]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Script logic follows
```

**Ansible Playbook Header:**
```yaml
---
# Playbook: {playbook-name}
# Purpose: {brief description}
# Usage: ansible-playbook {playbook-name}.yml

- name: {Human-readable playbook name}
  hosts: all
  become: yes

  tasks:
    # Tasks follow
```

**HestiaCP CLI Wrapper Pattern:**
```bash
# Always check success
hestia_add_user() {
    local username=$1
    local password=$2
    local email=$3

    if /usr/local/hestia/bin/v-add-user "$username" "$password" "$email"; then
        log_info "Created user: $username"
        return 0
    else
        log_error "Failed to create user: $username"
        return 1
    fi
}
```

**Logging Function Pattern:**
```bash
# Standard logging functions (in lib/common.sh)
log_info() {
    echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] [$(basename "$0" .sh)] [INFO] $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] [$(basename "$0" .sh)] [ERROR] $*" | tee -a "$LOG_FILE" >&2
}
```

**Environment Variable Loading:**
```bash
# Load environment variables from .env file (if exists)
if [ -f "$SCRIPT_DIR/../config/.env" ]; then
    source "$SCRIPT_DIR/../config/.env"
else
    log_warn ".env file not found, using defaults"
fi
```

### Agent Conflict Prevention Rules

**MANDATORY for all AI agents implementing automation:**

1. **Never hardcode credentials** - Always use environment variables or Ansible Vault
2. **Always use absolute paths** - No relative paths in cron jobs or systemd services
3. **Always check before create** - Implement idempotency checks
4. **Always log operations** - Use standard logging functions from lib/common.sh
5. **Always handle errors** - Use `set -euo pipefail` and trap handlers
6. **Always use HestiaCP CLI** - Never manually edit HestiaCP config files
7. **Always backup before modify** - Critical operations require snapshot first
8. **Always use UTC timestamps** - No local timezones in logs or filenames
9. **Always follow naming conventions** - Script names, user names, file names per patterns above
10. **Always version control** - Commit changes to `/opt/cfe-automation/` git repo

## Technology Stack Details

**Operating System:** Ubuntu 24.04 LTS
- 5-year support lifecycle (through April 2029)
- HestiaCP 1.9.4 officially supported
- Newer LTS version (released April 2024)
- LTS stability for production hosting

**Control Panel:** HestiaCP 1.9.4
- Open-source alternative to cPanel/Plesk
- Includes: Nginx, PHP-FPM, MariaDB, Exim4, Dovecot, BIND9
- Web interface on port 8083
- CLI tools for automation

**Web Server:** Nginx 1.28.0 (stable)
- Primary web server for all sites
- WordPress-optimized configuration (FastCGI cache)
- Reverse proxy capable (for Phase 2 Node.js apps)
- SSL/TLS termination

**PHP Runtime:** PHP-FPM 8.1+ (multi-version support)
- Process isolation via separate PHP-FPM pools per user
- Multiple PHP versions installable side-by-side
- OPcache enabled for bytecode caching
- WordPress compatibility tested

**Database:** MariaDB 11.4 LTS
- MySQL-compatible, WordPress proven
- 3-year LTS support cycle
- Query cache enabled
- Per-user database isolation

**Email Stack:**
- **MTA:** Exim4 (SMTP sending/receiving)
- **IMAP/POP3:** Dovecot (mailbox access)
- **Spam Filter:** SpamAssassin
- **Virus Scanner:** ClamAV
- **Webmail:** Roundcube (browser-based access)
- **Authentication:** DKIM, SPF, DMARC for deliverability

**DNS:** BIND9 + Cloudflare (Hybrid)
- BIND9 for traditional authoritative nameservers
- Cloudflare option for DDoS protection and global CDN
- HestiaCP manages BIND9 zone files automatically

**Backup & DR:**
- **Tool:** restic 0.18.1 (encrypted, incremental, deduplicated)
- **Transfer:** rclone (latest) for Backblaze B2 sync
- **Storage:** Backblaze B2 (S3-compatible, $0.005/GB/month)
- **Local:** HestiaCP built-in backup (7-day retention)
- **Off-site:** 30-day retention, encrypted at rest

**Configuration Management:** Ansible 11.1.0
- Infrastructure-as-code approach
- Idempotent playbooks for repeatable deployments
- Ansible Vault for secrets encryption
- Git version control

**Monitoring:** Netdata 2.2.0
- Real-time metrics dashboard
- Auto-discovers HestiaCP services
- Email alerting for critical events
- Low resource overhead

**Multi-Runtime Support (Phase 2+):**
- **Node.js Manager:** PM2 6.0.14 (process management, auto-restart, clustering)
- **Reverse Proxy:** Nginx 1.28.0 (same web server, proxy config)
- **Python/Ruby:** To be configured in Phase 2 based on requirements

**Security:**
- **Firewall:** iptables + UFW (HestiaCP managed)
- **Intrusion Prevention:** Fail2Ban (SSH, email, web brute force protection)
- **DDoS Protection:** Cloudflare proxy (free tier)
- **SSL/TLS:** Let's Encrypt (auto-renewal)

**Caching:** Redis (HestiaCP managed)
- WordPress object cache (persistent cache, reduces DB queries)
- Session storage
- Low memory footprint

## Security Architecture

**Network Security:**
- SSH: Key-based authentication only, root login disabled
- Firewall ports: 22 (SSH), 80 (HTTP), 443 (HTTPS), 25/587 (SMTP), 993/995 (IMAP/POP3), 8083 (HestiaCP)
- Cloudflare proxy hides origin IP from attackers
- Fail2Ban monitors and blocks brute force attempts

**Multi-Tenant Isolation:**
- File system: Separate home directories (`/home/{username}/`)
- Process isolation: Separate PHP-FPM pools per user
- Database isolation: Separate MySQL users, restricted permissions
- Email isolation: Separate mail directories per domain

**Data Protection:**
- Off-site backups encrypted at rest (restic encryption)
- Backblaze B2 credentials in environment variables (not scripts)
- Ansible Vault for sensitive playbook data
- HestiaCP admin password in password manager

**Email Security:**
- SPF/DKIM/DMARC configured per domain (prevent spoofing)
- TLS required for SMTP/IMAP connections
- SpamAssassin spam filtering
- ClamAV virus scanning on incoming mail

**Access Control:**
- HestiaCP admin: Strong password, 2FA recommended, 30-min session timeout
- Automation service account: `cfe-automation` user, limited sudo permissions
- No root SSH login
- Admin actions logged

## Performance Considerations

**WordPress Optimization:**
- Nginx FastCGI cache (page caching, bypass for logged-in users)
- PHP OPcache (bytecode caching)
- Redis object cache (WordPress plugin: Redis Object Cache)
- MariaDB query cache enabled
- Static asset serving optimized (gzip, browser caching headers)

**Target Performance (from NFRs):**
- Uncached WordPress page load: <2 seconds (95th percentile)
- Cached page load: <500ms (95th percentile)
- Database query performance: >80% cache hit rate
- Email delivery: <10 seconds

**Resource Utilization Targets:**
- CPU baseline: <30% average (headroom for spikes)
- RAM baseline: <60% (4.8GB of 8GB used)
- 4CPU/8GB Contabo VPS supports 20+ WordPress sites with optimization

**Backup Performance:**
- Daily backup window: <2 hours for all sites
- Incremental backup to B2: <30 minutes
- Restore time: <1 hour per site

**Scalability Path:**
- Current: 20 domains, capacity for 50+ on same hardware
- Vertical scaling: Resize Contabo VPS (add CPU/RAM) without migration
- Horizontal scaling: Add second VPS, database replication, load balancing (future)

## Deployment Architecture

**Infrastructure:**
- Provider: Contabo VPS
- Specifications: 4 CPU / 8GB RAM, US Central location
- OS: Ubuntu 24.04 LTS
- Networking: Static IP, IPv4/IPv6 support

**Deployment Strategy:**
- Initial: Manual HestiaCP installation via bash script
- Configuration: Ansible playbooks for reproducible setup
- Updates: Automated security patches, manual HestiaCP updates (after testing)

**DNS Configuration:**
- Option 1 (Traditional): BIND9 nameservers on VPS (`ns1/ns2.yourdomain.com`)
- Option 2 (Cloudflare): Cloudflare-managed DNS with Contabo VPS as origin
- Hybrid: Both available, client chooses preferred method

**SSL/TLS:**
- Let's Encrypt certificates auto-provisioned per domain
- Auto-renewal via HestiaCP cron job (every 90 days)
- Cloudflare Origin Certificates as alternative

**Backup Storage:**
- Local: On-server storage (`/var/backup/local/`) - 7-day retention
- Off-site: Backblaze B2 cloud storage - 30-day retention, encrypted
- 3-2-1 rule: 3 copies, 2 media types (local disk + B2 cloud), 1 off-site

**CDN/Caching:**
- Cloudflare free tier (DDoS protection, global CDN, caching)
- Nginx FastCGI cache (server-side page caching)
- Redis object cache (WordPress database query caching)

## Development Environment

**Prerequisites:**
- Local development: VirtualBox or Vagrant for Ansible testing
- Git for version control
- SSH client with key-based authentication
- Ansible installed locally (for playbook development)
- Password manager for credential storage

**Initial Server Setup:**
```bash
# Step 1: Provision Contabo VPS (manual via Contabo dashboard)
# - 4 CPU / 8GB RAM, US Central
# - Ubuntu 24.04 LTS
# - Note: IP address, root password

# Step 2: SSH key setup (from local machine)
ssh-copy-id -i ~/.ssh/id_rsa.pub root@<server-ip>

# Step 3: Initial security (disable password auth)
ssh root@<server-ip>
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# Step 4: Install HestiaCP
wget https://raw.githubusercontent.com/hestiacp/hestiacp/release/install/hst-install.sh
bash hst-install.sh --nginx yes --apache no --phpfpm yes --mysql yes \
  --exim yes --dovecot yes --clamav yes --spamassassin yes \
  --iptables yes --fail2ban yes

# Step 5: Setup automation repository
mkdir -p /opt/cfe-automation
cd /opt/cfe-automation
git init
# (Push initial automation scripts and playbooks)

# Step 6: Run Ansible setup playbooks
ansible-playbook -i inventory/production.yml playbooks/02-backup-setup.yml
ansible-playbook -i inventory/production.yml playbooks/03-monitoring-setup.yml
ansible-playbook -i inventory/production.yml playbooks/04-security-hardening.yml
```

**Ongoing Operations:**
- Site provisioning: `/opt/cfe-automation/scripts/provision-site.sh`
- Backup management: `/opt/cfe-automation/scripts/backup-offsite.sh` (cron daily)
- Monitoring: Netdata dashboard at `https://<server-ip>:19999`
- HestiaCP admin: `https://<server-ip>:8083`

## Architecture Decision Records (ADRs)

**ADR-001: Use HestiaCP as Foundation**
- **Decision:** Build on HestiaCP instead of custom stack or other panels
- **Rationale:** Open-source, proven WordPress hosting, includes all required services (web, email, DNS), active development, cPanel-compatible migration tools
- **Alternatives Considered:** cPanel (expensive), custom stack (too much work), Webmin/Virtualmin (less polished)
- **Trade-offs:** Locked into HestiaCP conventions, some limitations vs fully custom

**ADR-002: Hybrid DNS Strategy (BIND9 + Cloudflare)**
- **Decision:** Support both BIND9 nameservers and Cloudflare DNS options
- **Rationale:** Traditional hosting clients expect nameservers, modern clients prefer Cloudflare for DDoS protection and performance
- **Alternatives Considered:** BIND9 only (no DDoS protection), Cloudflare only (not traditional hosting model)
- **Trade-offs:** More complex to support both, but maximum flexibility

**ADR-003: restic + rclone for Backups**
- **Decision:** Use restic for backup creation, rclone for Backblaze B2 sync
- **Rationale:** restic provides encryption, deduplication, incremental backups; rclone has excellent B2 integration; combined solution meets 3-2-1 rule cost-effectively
- **Alternatives Considered:** duplicity (slower), borg (more complex), direct B2 API (less features)
- **Trade-offs:** Two tools instead of one, but best-in-class for each function

**ADR-004: Ansible for Configuration Management**
- **Decision:** Use Ansible for infrastructure-as-code automation
- **Rationale:** Agentless (no software on server), YAML-based (readable), large community, proven for server configuration
- **Alternatives Considered:** Terraform (better for cloud provisioning, not config management), Puppet/Chef (agent-based, more complex)
- **Trade-offs:** Learning curve for YAML/playbooks, but industry standard

**ADR-005: Bash for Operational Scripts**
- **Decision:** Use bash (not Python, zsh, etc.) for all automation scripts
- **Rationale:** Universal (pre-installed), HestiaCP uses bash, Ansible shell module expects bash, server-focused ecosystem
- **Alternatives Considered:** Python (better language but requires installation), zsh (better interactive but not standard)
- **Trade-offs:** Bash quirks and limitations, but maximum portability

**ADR-006: Netdata for Monitoring (MVP)**
- **Decision:** Use Netdata for MVP monitoring, defer Grafana/Prometheus
- **Rationale:** Lightweight, real-time, auto-discovers HestiaCP services, low overhead on 4CPU/8GB server
- **Alternatives Considered:** Grafana+Prometheus (more powerful but heavier), Zabbix (enterprise overkill), scripts only (insufficient visibility)
- **Trade-offs:** Less customization than Grafana, but appropriate for MVP scale

---

_Generated by BMAD Decision Architecture Workflow v1.0_
_Date: 2025-01-28_
_For: cfebrian_
