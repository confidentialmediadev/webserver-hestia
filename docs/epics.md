# Webserver Hestia - Epic Breakdown

**Author:** cfebrian
**Date:** 2025-11-28
**Project Level:** Medium Complexity
**Target Scale:** 20 domains initially, 50+ capacity

---

## Overview

This document provides the complete epic and story breakdown for Webserver Hestia, decomposing the requirements from the [PRD](./prd.md) into implementable stories.

**Living Document Notice:** This epic breakdown incorporates both PRD requirements and Architecture technical decisions. Ready for Phase 4 implementation.

## Functional Requirements Inventory

**Infrastructure & Server Management (FR1-FR8):**
- FR1: Platform owner can provision Contabo VPS with specified resources (4 CPU / 8GB RAM, US Central location)
- FR2: Platform owner can install HestiaCP control panel on Ubuntu/Debian server
- FR3: Platform owner can access HestiaCP web interface for server administration
- FR4: Platform owner can configure web server stack (Nginx + PHP-FPM + MariaDB + Redis)
- FR5: Platform owner can apply WordPress-optimized performance configurations (FastCGI cache, OPcache, Redis object cache)
- FR6: Platform owner can monitor server resource usage (CPU, RAM, disk, network)
- FR7: Platform owner can apply system updates and security patches
- FR8: Platform owner can manage server firewall rules and security settings

**User & Tenant Management (FR9-FR14):**
- FR9: Platform owner can create HestiaCP user accounts for multi-tenant isolation
- FR10: Platform owner can assign resource limits per user (disk quota, bandwidth, connection limits)
- FR11: Platform owner can configure separate IP addresses for specific tenants (optional high-isolation)
- FR12: Platform owner can manage user permissions and access levels
- FR13: Tenant users can access their own HestiaCP account with isolated file system and resources
- FR14: Platform owner can suspend or delete user accounts

**Website Hosting & Management (FR15-FR23):**
- FR15: Platform owner can create new website hosting accounts via HestiaCP
- FR16: Platform owner can configure domain names for hosted websites
- FR17: Platform owner can manage DNS records for hosted domains (A, CNAME, MX, TXT, etc.)
- FR18: WordPress sites can run with full plugin support (Elementor, JetEngine, WP Geo Directory validated)
- FR19: Platform owner can install and manage multiple PHP versions per site
- FR20: Platform owner can configure PHP-FPM pools for process isolation per user/site
- FR21: Platform owner can manage database instances (create, delete, backup databases)
- FR22: Platform owner can configure Redis caching for WordPress sites
- FR23: Hosted websites can serve static and dynamic content via Nginx

**SSL Certificate Management (FR24-FR28):**
- FR24: Platform can automatically provision Let's Encrypt SSL certificates for new domains
- FR25: Platform can auto-renew SSL certificates before expiration
- FR26: Platform owner can install custom SSL certificates (including Cloudflare Origin Certificates)
- FR27: Platform supports SNI (Server Name Indication) for multiple SSL sites on shared IP
- FR28: Platform owner can manage wildcard SSL certificates if needed

**Email Services (FR29-FR38):**
- FR29: Platform owner can create email accounts for any hosted domain
- FR30: Platform owner can configure email forwarders (most common use case)
- FR31: Platform owner can set up catch-all email addresses per domain
- FR32: Platform owner can configure autoresponders for email accounts
- FR33: Email users can access email via IMAP/POP3 protocols
- FR34: Email users can access webmail interface (Roundcube) via browser
- FR35: Email system automatically filters spam (SpamAssassin)
- FR36: Email system automatically scans for viruses (ClamAV)
- FR37: Platform owner can configure DKIM/SPF/DMARC for email deliverability
- FR38: Platform owner can set email quotas and limits per account

**DNS Management (FR39-FR42):**
- FR39: Platform can run self-hosted DNS server (BIND9) for full DNS independence
- FR40: Platform owner can manage DNS zones via HestiaCP interface
- FR41: Platform owner can use Cloudflare-managed DNS as alternative to BIND9
- FR42: Platform can programmatically manage DNS records for automation

**Backup & Disaster Recovery (FR43-FR51):**
- FR43: Platform automatically executes daily backups of all sites and data
- FR44: Platform stores local backups with 7-day retention on server
- FR45: Platform automatically uploads encrypted backups to Backblaze B2 off-site storage
- FR46: Platform retains off-site backups for 30 days
- FR47: Platform performs incremental backups to minimize storage costs and duration
- FR48: Platform owner can restore sites/data to specific point in time
- FR49: Platform owner can verify backup integrity via automated checks
- FR50: Platform implements 3-2-1 backup rule (3 copies, 2 media types, 1 off-site)
- FR51: Platform owner can export backups for archival or migration purposes

**Migration Capabilities (FR52-FR57):**
- FR52: Platform owner can import cPanel backup files into HestiaCP
- FR53: Platform owner can migrate WordPress sites from cPanel (files, database, configuration)
- FR54: Platform owner can migrate email accounts from cPanel to Dovecot
- FR55: Platform owner can execute DNS cutover (update A records, change nameservers)
- FR56: Platform owner can validate migrated sites (functionality, plugins, email, SSL all working)
- FR57: Platform owner can perform migration with <4 hours downtime per site

**Monitoring & Alerting (FR58-FR65):**
- FR58: Platform monitors uptime for web services, email services, and database
- FR59: Platform monitors server resource utilization (CPU, RAM, disk thresholds)
- FR60: Platform monitors backup job completion and success/failure status
- FR61: Platform monitors SSL certificate expiration dates
- FR62: Platform sends alert notifications for critical events (service down, disk full, backup failed)
- FR63: Platform owner can view logs for troubleshooting (web server, email, database, system)
- FR64: Platform monitors security events (failed logins, suspicious activity)
- FR65: Platform tracks website response times and performance metrics

**Automation & Provisioning (FR66-FR70):**
- FR66: Platform owner can execute automated site creation (WordPress + HestiaCP account + email + SSL) via script
- FR67: Platform owner can provision GeoDirectory WordPress sites from template
- FR68: Platform owner can bulk-create multiple sites from configuration file
- FR69: Platform owner can automate email account provisioning per domain
- FR70: Platform owner can version-control infrastructure configuration (git-based)

**Multi-Runtime Support (FR71-FR76):**
- FR71: Platform can run Node.js applications alongside PHP sites
- FR72: Platform can manage Node.js processes via PM2
- FR73: Platform can run Python WSGI applications
- FR74: Platform can run Ruby applications
- FR75: Platform can route requests to appropriate runtime via reverse proxy (Traefik or Nginx)
- FR76: Platform owner can run mixed application types on same server (WordPress + Next.js apps)

**Security & Compliance (FR77-FR83):**
- FR77: Platform implements file system isolation between tenants
- FR78: Platform implements process isolation (separate PHP-FPM pools)
- FR79: Platform implements database access isolation (separate DB users/permissions)
- FR80: Platform owner can configure firewall rules for network security
- FR81: Platform performs automated security scanning (Lynis or similar)
- FR82: Platform owner can apply security patches via system updates
- FR83: Platform protects against common attacks via Cloudflare (DDoS, brute force)

**Cloudflare Integration (FR84-FR87):**
- FR84: Platform owner can configure Cloudflare as CDN/proxy in front of hosted sites
- FR85: Platform supports Cloudflare-managed DNS as alternative to BIND9
- FR86: Platform can use Cloudflare Origin Certificates for SSL
- FR87: Platform leverages Cloudflare for DDoS protection and caching

**Total: 87 Functional Requirements**

---

## Epic Summary

This project is organized into **11 epics** that deliver incremental value, from foundational infrastructure to advanced automation and multi-runtime support.

**Epic 1: Foundation & Core Infrastructure**
- **Goal:** Establish operational HestiaCP platform on Contabo VPS with core services running
- **User Value:** Platform owner has working infrastructure ready for hosting workloads
- **Scope:** Server provisioning, HestiaCP installation, core stack configuration, WordPress optimization
- **FR Coverage:** FR1, FR2, FR3, FR4, FR5, FR6, FR7, FR8

**Epic 2: Backup & Disaster Recovery**
- **Goal:** Implement comprehensive backup system with local and off-site storage before migrating production sites
- **User Value:** Data protection safety net in place before moving production workloads
- **Scope:** Local backups (7-day), off-site backups (Backblaze B2, 30-day), backup automation, restore capability
- **FR Coverage:** FR43, FR44, FR45, FR46, FR47, FR48, FR49, FR50, FR51

**Epic 3: WordPress Hosting & Migration**
- **Goal:** Enable WordPress hosting and migrate ~20 sites from GreenGeeks cPanel
- **User Value:** Platform owner can host WordPress sites and migrate production sites successfully
- **Scope:** WordPress hosting setup, cPanel migration process, site validation, plugin compatibility
- **FR Coverage:** FR15, FR16, FR17, FR18, FR19, FR20, FR21, FR22, FR23, FR52, FR53, FR56, FR57

**Epic 4: Email Services**
- **Goal:** Operational email stack for all hosted domains
- **User Value:** Platform owner can provision email accounts, users can send/receive email reliably
- **Scope:** Email account management, forwarders, webmail, spam filtering, DKIM/SPF/DMARC, email migration
- **FR Coverage:** FR29, FR30, FR31, FR32, FR33, FR34, FR35, FR36, FR37, FR38, FR54

**Epic 5: DNS Management**
- **Goal:** Self-hosted DNS (BIND9) and Cloudflare integration for domain management
- **User Value:** Platform owner controls DNS for all domains with choice of self-hosted or managed
- **Scope:** BIND9 configuration, Cloudflare integration, DNS zone management, programmatic DNS updates
- **FR Coverage:** FR39, FR40, FR41, FR42, FR55

**Epic 6: SSL Certificate Automation**
- **Goal:** Automatic SSL provisioning and renewal for all domains
- **User Value:** All sites secured with HTTPS automatically, zero manual certificate management
- **Scope:** Let's Encrypt integration, auto-renewal, SNI support, wildcard certificates, Cloudflare certificates
- **FR Coverage:** FR24, FR25, FR26, FR27, FR28

**Epic 7: Multi-Tenant Management**
- **Goal:** Isolated hosting accounts for multiple clients with resource controls
- **User Value:** Platform owner can safely host multiple clients with complete isolation
- **Scope:** User account management, resource limits, permissions, isolation validation
- **FR Coverage:** FR9, FR10, FR11, FR12, FR13, FR14

**Epic 8: Monitoring & Observability**
- **Goal:** Comprehensive monitoring and alerting for system health
- **User Value:** Platform owner knows system status in real-time and receives alerts for critical issues
- **Scope:** Netdata installation, uptime monitoring, resource monitoring, log aggregation, alerting
- **FR Coverage:** FR58, FR59, FR60, FR61, FR62, FR63, FR64, FR65

**Epic 9: Provisioning Automation**
- **Goal:** Automated scripts for rapid site provisioning and bulk operations
- **User Value:** Platform owner can launch new WordPress/GeoDirectory sites in minutes instead of hours
- **Scope:** Automated site creation, GeoDirectory templates, bulk operations, email automation, IaC
- **FR Coverage:** FR66, FR67, FR68, FR69, FR70

**Epic 10: Multi-Runtime Support**
- **Goal:** Support for Node.js, Python, Ruby applications alongside PHP
- **User Value:** Platform owner can host Next.js apps and other non-PHP applications on same infrastructure
- **Scope:** Node.js/PM2 setup, Python WSGI, Ruby environment, reverse proxy routing, mixed app support
- **FR Coverage:** FR71, FR72, FR73, FR74, FR75, FR76

**Epic 11: Security & Cloudflare Integration**
- **Goal:** Hardened security posture and DDoS protection via Cloudflare
- **User Value:** Platform protected against attacks with tenant isolation and Cloudflare defenses
- **Scope:** Multi-tenant isolation, security scanning, firewall rules, Cloudflare CDN/proxy integration
- **FR Coverage:** FR77, FR78, FR79, FR80, FR81, FR82, FR83, FR84, FR85, FR86, FR87

---

## FR Coverage Map

| Epic | Epic Title | FR Coverage | FR Count |
|------|-----------|-------------|----------|
| Epic 1 | Foundation & Core Infrastructure | FR1-FR8 | 8 FRs |
| Epic 2 | Backup & Disaster Recovery | FR43-FR51 | 9 FRs |
| Epic 3 | WordPress Hosting & Migration | FR15-FR23, FR52, FR53, FR56, FR57 | 13 FRs |
| Epic 4 | Email Services | FR29-FR38, FR54 | 11 FRs |
| Epic 5 | DNS Management | FR39-FR42, FR55 | 5 FRs |
| Epic 6 | SSL Certificate Automation | FR24-FR28 | 5 FRs |
| Epic 7 | Multi-Tenant Management | FR9-FR14 | 6 FRs |
| Epic 8 | Monitoring & Observability | FR58-FR65 | 8 FRs |
| Epic 9 | Provisioning Automation | FR66-FR70 | 5 FRs |
| Epic 10 | Multi-Runtime Support | FR71-FR76 | 6 FRs |
| Epic 11 | Security & Cloudflare Integration | FR77-FR87 | 11 FRs |
| **TOTAL** | | **All FRs** | **87 FRs** |

**FR Coverage Validation:** ✅ All 87 functional requirements mapped to epics

---

## Epic 1: Foundation & Core Infrastructure

**Goal:** Establish operational HestiaCP platform on Contabo VPS (4 CPU / 8GB RAM, Ubuntu 24.04 LTS) with core services running (Nginx, PHP-FPM, MariaDB, Redis), WordPress-optimized configuration, and automation repository initialized.

**User Value:** Platform owner has a working infrastructure foundation ready for hosting workloads, with version-controlled automation scripts and reproducible configuration.

**FR Coverage:** FR1, FR2, FR3, FR4, FR5, FR6, FR7, FR8

---

### Story 1.1: Provision Contabo VPS and Initialize Automation Repository

As a platform owner,
I want to provision a Contabo VPS with specific resources and initialize the automation repository structure,
So that I have the server infrastructure and version-controlled foundation for all automation scripts.

**Acceptance Criteria:**

**Given** Contabo account credentials and repository requirements from Architecture document
**When** provisioning the VPS and setting up automation foundation
**Then** the following must be complete:

**VPS Provisioning:**
- Contabo VPS provisioned with 4 CPU / 8GB RAM, US Central location
- Ubuntu 24.04 LTS installed (latest point release)
- Static IPv4 address assigned and documented
- Root password securely stored in password manager
- Server accessible via IP address

**SSH Hardening:**
- SSH public key added to root authorized_keys (from local machine)
- SSH key-based authentication verified working
- Password authentication disabled (`PasswordAuthentication no` in /etc/ssh/sshd_config)
- Root login via password disabled
- SSH service restarted and verified

**Automation Repository Initialization:**
- Git repository initialized at `/opt/cfe-automation/`
- Directory structure created per Architecture (ansible/, scripts/, config/, docs/, tests/)
- .gitignore created (excludes .env, secrets.yml, *.log, .vault_pass)
- README.md created with repository purpose and structure overview
- Initial commit: "Initialize CFE Web Host 26 automation repository"

**And** all connections tested from local machine (SSH key-based auth only)

**Prerequisites:** None (first story)

**Technical Notes:**
- Architecture reference: [architecture.md](./architecture.md) lines 849-873 (Initial Server Setup)
- Repository structure: architecture.md lines 296-359 (Automation Repository Structure)
- Follow Architecture naming patterns: architecture.md lines 413-438
- Use absolute paths per Architecture Agent Conflict Prevention Rules (rule #2)
- Contabo dashboard: Manual VPS ordering (cannot be automated)
- Store server IP, root password, SSH key path in secure location
- Do NOT install any software yet (HestiaCP comes in next story)

---

### Story 1.2: Install HestiaCP Control Panel with All Services

As a platform owner,
I want to install HestiaCP 1.9.4 with Nginx, PHP-FPM, MariaDB, Exim4, Dovecot, and security services,
So that I have the complete hosting control panel foundation with web, database, and email capabilities.

**Acceptance Criteria:**

**Given** Ubuntu 24.04 LTS server with SSH access and HestiaCP installation script
**When** executing the HestiaCP installation
**Then** the following must be complete:

**HestiaCP Installation:**
- HestiaCP 1.9.4 installed using official installation script
- Installation command executed with exact flags per Architecture:
  ```bash
  wget https://raw.githubusercontent.com/hestiacp/hestiacp/release/install/hst-install.sh
  bash hst-install.sh --nginx yes --apache no --phpfpm yes --mysql yes \
    --exim yes --dovecot yes --clamav yes --spamassassin yes \
    --iptables yes --fail2ban yes
  ```
- Installation completes without errors
- All services start successfully

**Services Verification:**
- Nginx 1.28.0 (stable) running on ports 80, 443
- PHP-FPM 8.1+ installed and running
- MariaDB 11.4 LTS installed and running
- Exim4 (MTA) running on ports 25, 587
- Dovecot (IMAP/POP3) running on ports 993, 995
- SpamAssassin installed and integrated
- ClamAV installed and running
- BIND9 DNS server installed (not configured yet)
- Fail2Ban active and monitoring SSH, email, web
- iptables/UFW firewall configured with HestiaCP rules
- Redis installed (HestiaCP managed)

**HestiaCP Admin Access:**
- Web interface accessible at `https://<server-ip>:8083`
- Admin credentials generated and stored securely
- Admin panel login successful
- Dashboard shows all services as "running"
- Let's Encrypt integration available (not configured yet)

**And** HestiaCP installation log saved to `/opt/cfe-automation/docs/hestiacp-install.log`
**And** all HestiaCP CLI tools available at `/usr/local/hestia/bin/v-*`

**Prerequisites:** Story 1.1 (VPS provisioned)

**Technical Notes:**
- Architecture reference: architecture.md lines 19-24, 673-677 (HestiaCP details)
- Installation is idempotent-safe (checks if already installed)
- Installation duration: ~15-30 minutes depending on server speed
- Post-install: HestiaCP admin password in email OR shown in terminal (save immediately)
- Service validation: `systemctl status nginx php*-fpm mysql exim4 dovecot redis-server`
- HestiaCP documentation: Official docs for v1.9.4
- Note server IP for HestiaCP access (before DNS configured)
- Firewall ports automatically configured: 22, 25, 80, 443, 587, 993, 995, 8083
- Do NOT configure websites yet (that's Epic 3)

---

### Story 1.3: Configure WordPress Performance Optimizations

As a platform owner,
I want to configure Nginx FastCGI cache, PHP OPcache, and Redis object cache for WordPress,
So that WordPress sites achieve target performance (<2s uncached, <500ms cached page loads).

**Acceptance Criteria:**

**Given** HestiaCP installed with Nginx, PHP-FPM, and Redis running
**When** applying WordPress-specific optimizations
**Then** the following must be configured:

**Nginx FastCGI Cache:**
- FastCGI cache zone defined in `/etc/nginx/nginx.conf`:
  - `fastcgi_cache_path /var/cache/nginx levels=1:2 keys_zone=WORDPRESS:100m inactive=60m;`
  - Cache size: 100MB (adjustable)
  - Inactive timeout: 60 minutes
- Cache bypasses configured for:
  - Logged-in users (WordPress cookies: `wordpress_logged_in_*`, `comment_author_*`)
  - POST requests
  - Query strings with specific params (`?s=`, `?p=`, etc.)
  - WordPress admin (`/wp-admin/`, `/wp-login.php`)
  - WooCommerce cart/checkout (if detected)
- Cache headers added (`X-FastCGI-Cache: HIT|MISS|BYPASS`)
- Purge capability enabled (manual via script or plugin)

**PHP OPcache Configuration:**
- OPcache enabled in PHP 8.1+ FPM configuration (`/etc/php/8.1/fpm/conf.d/10-opcache.ini`):
  - `opcache.enable=1`
  - `opcache.memory_consumption=128` (MB)
  - `opcache.interned_strings_buffer=8` (MB)
  - `opcache.max_accelerated_files=10000`
  - `opcache.revalidate_freq=2` (seconds)
  - `opcache.validate_timestamps=1` (dev mode, change to 0 for production)
- PHP-FPM restarted to apply changes
- OPcache status verified via `php -i | grep opcache`

**Redis Object Cache:**
- Redis server running and accessible on localhost:6379
- Redis maxmemory policy set to `allkeys-lru` (evict least recently used)
- Redis maxmemory set to 256MB (adjustable based on usage)
- Redis persistence disabled (cache-only, not durable data)
- Redis configuration in `/etc/redis/redis.conf`

**MariaDB Query Cache (if applicable to 11.4 LTS):**
- Query cache enabled in `/etc/mysql/mariadb.conf.d/50-server.cnf` (if supported in 11.4):
  - `query_cache_type=1`
  - `query_cache_size=64M`
  - `query_cache_limit=2M`
- Note: MariaDB 10.6+ may have deprecated query cache; verify compatibility
- MariaDB restarted if changes applied

**And** performance baseline documented:
- Nginx restart time: <5 seconds
- PHP-FPM restart time: <3 seconds
- Redis restart time: <2 seconds
- Services stable after restart

**And** configuration files backed up before modification (`.bak` suffix with timestamp)

**Prerequisites:** Story 1.2 (HestiaCP installed)

**Technical Notes:**
- Architecture reference: architecture.md lines 777-784 (Performance Considerations)
- NFR-P1: Uncached page <2s, cached <500ms (architecture.md line 524-526)
- Test with WordPress after Epic 3 (no WordPress sites yet)
- FastCGI cache bypass logic critical: DO NOT cache logged-in users
- OPcache validate_timestamps: Set to 0 in production (performance), 1 in dev (auto-reload)
- Redis WordPress integration: Requires Redis Object Cache plugin (installed in Epic 3)
- MariaDB 11.4 LTS may not support query cache (deprecated in newer versions) - verify
- Configuration templates: Create in `/opt/cfe-automation/config/` for repeatability
- Script creation: `scripts/configure-wordpress-performance.sh` (idempotent)
- Logging: All config changes logged to `/var/log/cfe-automation/performance-config.log`

---

### Story 1.4: Setup Ansible Configuration Management Foundation

As a platform owner,
I want to set up Ansible 11.1.0 with playbooks and roles structure for infrastructure-as-code,
So that server configuration is version-controlled, repeatable, and auditable.

**Acceptance Criteria:**

**Given** automation repository initialized and server accessible via SSH
**When** setting up Ansible configuration management
**Then** the following must be complete:

**Ansible Installation (Local Machine):**
- Ansible 11.1.0 installed on local development machine (not server)
- Installation verified: `ansible --version` shows 11.1.0
- Python 3.8+ available (Ansible requirement)

**Ansible Directory Structure:**
- Directory structure created in `/opt/cfe-automation/ansible/`:
  ```
  ansible/
  ├── ansible.cfg
  ├── playbooks/
  │   ├── 00-server-init.yml (placeholder)
  │   ├── 01-hestiacp-install.yml (placeholder)
  │   ├── 02-backup-setup.yml (for Epic 2)
  │   ├── 03-monitoring-setup.yml (for Epic 8)
  │   └── 04-security-hardening.yml (for Epic 11)
  ├── roles/
  │   ├── hestiacp/
  │   ├── backup/
  │   ├── monitoring/
  │   └── wordpress-optimize/
  ├── inventory/
  │   └── production.yml
  ├── group_vars/
  │   └── all.yml
  └── vault/
      └── secrets.yml.example
  ```

**Ansible Configuration (`ansible.cfg`):**
- Inventory file set to `inventory/production.yml`
- Host key checking disabled (or configured for known_hosts)
- SSH user: `root` (or `cfe-automation` service account if created)
- Privilege escalation configured (become: yes)
- Vault password file location noted (not in repo)
- Retry files disabled
- Log path: `/opt/cfe-automation/ansible/ansible.log`

**Inventory File (`inventory/production.yml`):**
- Server IP address configured
- Host variables: ansible_user=root, ansible_port=22
- Host groups defined: `[webservers]`, `[hestia_servers]`

**Group Variables (`group_vars/all.yml`):**
- Project name: "Webserver Hestia"
- Server timezone: UTC
- Backup retention: 7 days local, 30 days B2
- Placeholder variables for future configuration

**Ansible Vault Setup:**
- Vault password file created locally (NOT in repo): `~/.ansible/vault_pass.txt`
- Example secrets file: `vault/secrets.yml.example` with placeholder structure
- Actual secrets file: `vault/secrets.yml` encrypted with Ansible Vault
- Secrets file contains: Backblaze B2 keys (placeholder), HestiaCP admin password, etc.

**Test Playbook:**
- Simple test playbook created: `playbooks/00-server-init.yml`
- Playbook tests SSH connectivity and gathers facts
- Playbook execution successful from local machine: `ansible-playbook -i inventory/production.yml playbooks/00-server-init.yml`

**And** Ansible can successfully connect to server and run commands
**And** all Ansible files committed to git (except vault_pass.txt and actual secrets.yml)

**Prerequisites:** Story 1.1 (automation repository initialized), Story 1.2 (server ready)

**Technical Notes:**
- Architecture reference: architecture.md lines 719-721 (Ansible 11.1.0)
- Ansible installation: `pip install ansible==11.1.0` or package manager
- Ansible configuration: architecture.md lines 296-359 (repository structure)
- DO NOT store vault password in repo (architecture.md line 160-164: Secrets Management)
- Create `.ansible-vault-password` in gitignore
- Idempotency: All playbooks must be safe to run multiple times
- Future playbooks will configure HestiaCP, backups, monitoring
- Service account `cfe-automation` created in Epic 7 (Multi-Tenant Management)
- For now, use root SSH access (will transition to service account later)
- Test connectivity before committing configuration
- Ansible Control Node: Local machine (not server)

---

### Story 1.5: Create System Monitoring and Logging Scripts

As a platform owner,
I want basic health check scripts and centralized logging configured,
So that I can monitor system health and troubleshoot issues via standardized logs.

**Acceptance Criteria:**

**Given** HestiaCP installed and automation repository ready
**When** creating monitoring scripts and logging infrastructure
**Then** the following must be complete:

**Logging Directory Structure:**
- Custom log directory created: `/var/log/cfe-automation/`
- Subdirectories:
  - `/var/log/cfe-automation/provision.log` (site provisioning logs)
  - `/var/log/cfe-automation/backup.log` (backup operation logs)
  - `/var/log/cfe-automation/errors.log` (all error-level events)
  - `/var/log/cfe-automation/archive/` (rotated logs)
- Permissions: Owned by root, writable by automation scripts
- Log retention: 30 days minimum (NFR-M2 requirement)

**Logrotate Configuration:**
- Logrotate config created: `/etc/logrotate.d/cfe-automation`
- Rotation schedule: Daily
- Compression: Enabled for logs older than 7 days (gzip)
- Retention: 30 days, then delete
- Post-rotation: Reload services if needed

**Common Logging Functions Library:**
- Library script created: `/opt/cfe-automation/scripts/lib/common.sh`
- Functions implemented:
  - `log_info()` - Info-level logging with timestamp (UTC), script name, message
  - `log_error()` - Error-level logging (same format, output to stderr + errors.log)
  - `log_warn()` - Warning-level logging
  - `log_debug()` - Debug-level logging (disabled by default, enable with DEBUG=1 env var)
- Log format: `[YYYY-MM-DD HH:MM:SS UTC] [script-name] [LEVEL] message`
- Example: `[2025-11-28 14:32:10 UTC] [provision-site] [INFO] Creating HestiaCP user: client1`
- Functions log to both console (stdout/stderr) and file (`/var/log/cfe-automation/<appropriate>.log`)

**Health Check Script:**
- Script created: `/opt/cfe-automation/scripts/healthcheck.sh`
- Checks performed:
  - Nginx status (running, responding on port 80/443)
  - PHP-FPM status (running, pool status)
  - MariaDB status (running, can connect)
  - Exim4 status (running, mail queue size)
  - Dovecot status (running)
  - Redis status (running, memory usage)
  - Disk usage (warn if >80%, critical if >90%)
  - Memory usage (warn if >70%)
  - CPU load (5min average)
- Output: Summary of all checks (OK/WARNING/CRITICAL)
- Exit code: 0 if all OK, 1 if warnings, 2 if critical
- Logging: All checks logged to `/var/log/cfe-automation/healthcheck.log`

**Cron Job for Health Checks:**
- Cron job added to run health check every 15 minutes
- Crontab entry: `*/15 * * * * /opt/cfe-automation/scripts/healthcheck.sh >> /var/log/cfe-automation/healthcheck.log 2>&1`
- Critical failures: Email notification to admin (if email configured)

**And** health check script executed successfully with all services reporting OK
**And** log files created with correct permissions and format
**And** common.sh library sourced successfully in test script

**Prerequisites:** Story 1.2 (HestiaCP installed), Story 1.1 (automation repository)

**Technical Notes:**
- Architecture reference: architecture.md lines 85-110 (Logging Strategy)
- Log format: architecture.md lines 92-98 (exact format specification)
- NFR-M2: Log retention 30 days minimum (architecture.md line 638-641)
- Bash header template: architecture.md lines 580-593 (includes set -euo pipefail)
- All scripts must use UTC timestamps (Agent Conflict Prevention Rule #8)
- Health check interval: 15 minutes (balance between awareness and overhead)
- Email notifications: Defer to Epic 4 (Email Services) for email configuration
- Common.sh library: Shared by ALL future scripts (critical foundation)
- Script permissions: `chmod +x` for all `.sh` files
- Logging functions: Use `tee` to write to both console and file simultaneously
- Disk space monitoring: Use `df -h` and parse output
- Service status: Use `systemctl status <service>` and check exit code

---

### Story 1.6: Document Initial Infrastructure Configuration

As a platform owner,
I want comprehensive documentation of the server setup, configuration, and operations,
So that I can reference procedures, troubleshoot issues, and onboard future administrators.

**Acceptance Criteria:**

**Given** completed infrastructure setup (Stories 1.1-1.5)
**When** creating documentation
**Then** the following documents must exist:

**Server Information Document:**
- File: `/opt/cfe-automation/docs/server-info.md`
- Contains:
  - Server specifications (4 CPU / 8GB RAM, Contabo VPS)
  - Operating system version (Ubuntu 24.04 LTS)
  - Server IP address(es)
  - SSH access details (port, key location)
  - HestiaCP admin access URL and credentials location
  - Network configuration (static IP, nameservers)
  - Installed software versions (HestiaCP, Nginx, PHP, MariaDB, etc.)

**Operations Runbook:**
- File: `/opt/cfe-automation/docs/operations.md`
- Sections:
  - **Common Operations:**
    - How to SSH into server
    - How to access HestiaCP admin panel
    - How to run health check script
    - How to view logs
    - How to restart services (Nginx, PHP-FPM, MariaDB, etc.)
  - **Troubleshooting:**
    - Service won't start (check logs, common issues)
    - Disk space full (cleanup procedures)
    - High CPU/memory usage (investigation steps)
  - **Maintenance:**
    - System update procedure
    - HestiaCP update procedure
    - Log rotation verification
    - Health check monitoring

**Configuration Guide:**
- File: `/opt/cfe-automation/docs/configuration-guide.md`
- Documents all custom configurations:
  - Nginx FastCGI cache setup (Story 1.3)
  - PHP OPcache settings
  - Redis configuration
  - MariaDB optimization
  - Ansible structure and usage
  - Logging configuration

**Disaster Recovery Procedures (Placeholder):**
- File: `/opt/cfe-automation/docs/disaster-recovery.md`
- Placeholder sections (to be completed in Epic 2):
  - Backup verification
  - Restoration procedures
  - Server rebuild from scratch
  - Recovery time objectives (RTO)

**README.md Update:**
- Repository README updated with:
  - Project overview
  - Directory structure explanation
  - Quick start guide (how to connect, run scripts)
  - Link to detailed documentation
  - Prerequisites for running Ansible playbooks

**Architecture Document Link:**
- Symlink or reference to `docs/architecture.md` from automation repo
- Note: Architecture document lives in project root docs/, linked for convenience

**And** all documentation uses markdown format with clear headings and code blocks
**And** all sensitive information references "see password manager" (not stored in plain text)
**And** documentation committed to git

**Prerequisites:** Stories 1.1-1.5 (all infrastructure setup complete)

**Technical Notes:**
- Architecture reference: architecture.md lines 649-652 (NFR-M4: Documentation)
- Documentation style: Clear, concise, code examples in markdown code blocks
- Password references: "Stored in 1Password vault: Webserver Hestia Admin"
- No plain-text credentials in docs (security best practice)
- Update documentation as configuration changes
- Operations runbook: Assumes minimal Linux knowledge (document all steps)
- Configuration guide: Technical reference for HOW things are configured
- Disaster recovery: Placeholder now, full procedures in Epic 2 (Backup & DR)
- Link to architecture: Use relative path or copy to automation repo docs/
- Future updates: Documentation is living; update as system evolves

---

