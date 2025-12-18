# Webserver Hestia - Epics & Stories

**Based on Simplified PRD (Version 2.0)**

---

## Epic 1: Infrastructure Setup (Steps 1-7) - **COMPLETED**
*This epic covers the initial provisioning and installation of HestiaCP on both servers.*

- **Story 1.1**: Provision Servers & Set Hostnames (Done)
- **Story 1.3**: SSH Hardening & Firewall (Done)
- **Story 1.4**: Install HestiaCP on Master (Done)
- **Story 1.5**: Install HestiaCP on Slave (Done)

---

## Epic 2: DNS Cluster & Domain Config (Steps 8-9)
*Establish the DNS redundancy and configure the primary hosting domain.*

### Story 2.1: Configure DNS Cluster
**Goal**: Connect Master and Slave servers via Hestia API for automated DNS zone syncing.
**Tasks**:
1.  Whitelist Master IP on Slave.
2.  Create API key on Slave (sync-dns-cluster role).
3.  Configure `hestia.conf` and `named.conf.options` on both servers.
4.  Run `v-add-remote-dns-host` on Master.
5.  Verify zone transfer by creating a test domain.

### Story 2.2: Configure cfehost.net
**Goal**: Set up the main hosting domain with SSL and DNS records.
**Tasks**:
1.  **Configure Registrar Glue Records** (ns1/ns2 IPs).
2.  Add `cfehost.net` to Admin user on Master.
3.  Add A records for `ns1`, `ns2`, `panel`, `mail`, `webmail`.
4.  Enable Let's Encrypt for `cfehost.net` and `panel.cfehost.net`.
5.  Verify login via `panel.cfehost.net`.

---

## Epic 3: Mail & Performance (Steps 10-11)
*Configure email services and optimize server performance.*

### Story 3.1: Configure Mail Services
**Goal**: Enable full email stack with webmail and filtering.
**Tasks**:
1.  Configure MX record for `mail.cfehost.net`.
2.  Enable SPF, DKIM, DMARC in Hestia.
3.  Install/Configure SnappyMail (if not default) or Roundcube.
4.  Enable ManageSieve in Dovecot.

### Story 3.2: Performance Optimization
**Goal**: Tune the server for WordPress performance.
**Tasks**:
1.  Install and configure Redis (`apt install redis-server`).
2.  Configure PHP OPcache settings in `php.ini`.
3.  Enable ModSecurity via Hestia templates.
4.  Restart services and verify.

---

## Epic 4: Security & Backups (Steps 12-13)
*Harden the server and ensure data safety.*

### Story 4.1: Security Enhancements
**Goal**: Implement additional security measures beyond basic firewall.
**Tasks**:
1.  Verify Fail2Ban jails for ssh, hestia, nginx-auth, exim/dovecot.
2.  Configure daily ClamAV scan script and cron job.
3.  Verify AppArmor status.

### Story 4.2: Backup Configuration
**Goal**: Set up automated off-site backups.
**Tasks**:
1.  Configure local Hestia backups (daily).
2.  Install and configure Rclone with Backblaze B2 remote.
3.  Create backup sync script.
4.  Set up cron job for daily off-site sync.

---

## Epic 5: Client Workflow (Step 14)
*Define the process for onboarding new clients/sites.*

### Story 5.1: Client Onboarding Process
**Goal**: Document and test the workflow for adding a new client.
**Tasks**:
1.  Create a test Hestia user.
2.  Add a domain.
3.  Install WordPress.
4.  Enable Redis caching.
5.  Verify DNS propagation and SSL.
