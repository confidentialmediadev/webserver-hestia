# Webserver Hestia - Product Requirements Document

**Author:** cfebrian
**Date:** 2025-11-28
**Version:** 1.0

---

## Executive Summary

**CFE Web Host 26** is a self-managed hosting platform built on HestiaCP and Contabo VPS infrastructure, designed to replace expensive cPanel reseller hosting ($80/month) with a cost-effective, automated solution (~$7/month). The platform serves as the foundation for hosting current WordPress properties and future GeoDirectory sites, with full automation for provisioning new domains, email accounts, and multi-runtime application support.

**Primary Value Proposition:** Transform from paying for hosting services to owning a scalable hosting platform with complete control over features, security, automation, and capabilities.

**Initial Implementation:** Migrate ~20 existing WordPress sites from GreenGeeks cPanel to self-hosted infrastructure.

**Long-term Vision:** Automated hosting platform for launching GeoDirectory WordPress sites and Next.js/Node applications with email, SSL, and provisioning automation.

### What Makes This Special

This is not just a "cPanel replacement" - it's building **CFE Web Host 26 as an internal product** where you own the platform, define the features, and control the automation. Unlike managed hosting where you're limited by vendor capabilities, this platform evolves with your needs: automated site provisioning for GeoDirectory properties, multi-runtime support (WordPress + Node.js), infrastructure-as-code patterns, and purpose-built automation for your specific use cases. You're building hosting-as-a-product, not just migrating websites.

---

## Project Classification

**Technical Type:** Web Application / Infrastructure Platform
**Domain:** General (Hosting Infrastructure)
**Complexity:** Medium

**Classification Rationale:**

This project combines **web application** characteristics (control panel, admin dashboard, automation interfaces) with **infrastructure platform** concerns (multi-tenancy, resource isolation, security, backups). The domain is general hosting/infrastructure management without regulated industry constraints.

**Complexity is Medium because:**
- Multi-site isolation and tenant management required
- Email server stack with spam/antivirus (complex subsystem)
- SSL automation across multiple domains
- Backup/restore with off-site replication
- Multi-runtime support (PHP, Node.js, Python, Ruby)
- Security and update automation
- Migration from existing cPanel infrastructure

**NOT High Complexity because:**
- No regulatory compliance requirements
- No complex domain-specific rules (healthcare, fintech, etc.)
- Using proven open-source components (HestiaCP, Nginx, etc.)
- Internal product (not customer-facing SaaS)

{{#if domain_context_summary}}

### Domain Context

{{domain_context_summary}}
{{/if}}

---

## Success Criteria

**CFE Web Host 26 succeeds when:**

1. **Cost Target Achieved:** Operating costs reduced from $80/month to ~$7/month (91% cost reduction = ~$876/year savings)

2. **Migration Completeness:** All ~20 WordPress sites successfully migrated from GreenGeeks cPanel with:
   - Zero data loss
   - All Elementor + JetEngine + WP Geo Directory functionality intact
   - Email accounts migrated (<50 accounts, mostly forwarders)
   - SSL certificates working on all domains

3. **Operational Independence:** Full control over hosting infrastructure:
   - Self-hosted DNS (BIND9) or managed via Cloudflare
   - Complete email independence (Exim4 + Dovecot stack)
   - No reliance on third-party control panels

4. **Reliability & Recovery:** Production-grade backup/restore capability:
   - Daily automated backups with 30-day retention
   - Off-site backup storage (Backblaze B2)
   - Tested point-in-time restoration

5. **Automation Foundation:** Basic provisioning automation working:
   - Ability to create new HestiaCP user accounts
   - Automated email account provisioning per domain
   - SSL certificate automation (Let's Encrypt)

6. **Platform Performance:** WordPress sites perform as well or better than current cPanel setup on 4CPU/8GB infrastructure

7. **Future-Ready:** Infrastructure supports future capabilities:
   - Multi-runtime ready (Node.js, Python, Ruby alongside PHP)
   - Reverse proxy capability (Traefik or Nginx) for Next.js apps
   - Version-controlled configuration for repeatable deployments

**What "Winning" Looks Like:**
You confidently launch new GeoDirectory WordPress sites with a few commands/scripts, email just works, backups run automatically, and you've saved nearly $900/year while gaining complete platform control.

### Business Metrics

**Financial:**
- Monthly hosting cost: ≤$10/month (Contabo VPS + Backblaze B2)
- Annual savings: ~$850+/year
- ROI breakeven: Immediate (first month of operation)

**Operational:**
- Migration downtime: <4 hours per site
- Backup success rate: 100% daily
- Email uptime: >99.5%
- WordPress site response time: <2 seconds (uncached)

**Platform Growth:**
- New site provisioning time: <30 minutes (manual) → <5 minutes (automated goal)
- Supported domains: 20 (current) → 50+ (capacity target)

---

## Product Scope

### MVP - Minimum Viable Product

**Goal:** Successfully migrate from GreenGeeks cPanel to self-hosted HestiaCP with operational parity and basic automation.

**Core Infrastructure:**
- Contabo VPS (4 CPU / 8GB RAM, US Central location)
- HestiaCP control panel installed and configured
- Nginx + PHP-FPM 8.1+ + MariaDB 10.6+ + Redis stack
- WordPress-optimized performance configuration (FastCGI cache, OPcache, Redis object cache)

**Migration Capabilities:**
- Migrate all ~20 WordPress sites from cPanel backups
- Migrate <50 email accounts (mostly forwarders) with zero loss
- DNS cutover strategy (A-record updates + nameserver changes)
- SSL certificates provisioned via Let's Encrypt for all domains
- Elementor + JetEngine + WP Geo Directory validation on migrated sites

**Essential Services:**
- Full email stack operational (Exim4 + Dovecot + SpamAssassin + ClamAV)
- DNS management (BIND9 or Cloudflare-managed)
- Automated daily backups (local 7-day retention)
- Off-site backups to Backblaze B2 (30-day retention, encrypted)
- Multi-tenant isolation (separate HestiaCP user accounts per client)

**Basic Automation:**
- SSL certificate auto-renewal (Let's Encrypt)
- Daily backup job automation
- System update automation (security patches)

**Monitoring (Basic):**
- Server uptime monitoring
- Backup job completion verification
- Critical service health checks (web, email, database)

**MVP Success Gate:** All 20 sites migrated, email working, backups running, SSL auto-renewing. You can manage everything through HestiaCP without touching cPanel.

### Growth Features (Post-MVP)

**Phase 2: Provisioning Automation**
- Automated new site creation scripts (WordPress + HestiaCP account + email + SSL in one command)
- GeoDirectory site template automation (preconfigured WP + GeoDirectory + standard plugins)
- Bulk operations support (create 5 sites from config file)
- Email account provisioning automation per domain

**Phase 3: Multi-Runtime Support**
- Node.js runtime environment (PM2 process management)
- Traefik reverse proxy for Next.js/Node applications
- Python WSGI application support
- Ruby environment (rbenv/rvm) if needed
- Routing/proxy configuration for mixed PHP + Node apps on same server

**Phase 4: Advanced Monitoring & Operations**
- Comprehensive monitoring dashboard (Netdata, Grafana, or similar)
- Automated security scanning (Lynis, ClamAV scheduled scans)
- Performance monitoring (response times, resource usage)
- Alert notifications (email/Slack for critical issues)
- System health reporting

**Phase 5: Infrastructure as Code**
- Version-controlled server configuration (Ansible, Terraform, or similar)
- Reproducible deployment scripts
- Disaster recovery automation (rebuild server from config)
- Configuration drift detection

### Vision (Future)

**Long-term Platform Capabilities:**

**Self-Service Portal:**
- Custom client portal (beyond HestiaCP) for managed clients
- Usage analytics and reporting per site
- Client-facing backup/restore interface

**Advanced Automation:**
- Auto-scaling capabilities (vertical: resize VPS, horizontal: multi-server)
- Intelligent resource allocation (detect high-traffic sites, allocate resources)
- Automated WordPress optimization (image compression, plugin updates, cache warming)

**Business Intelligence:**
- Cost tracking per site/client
- Performance benchmarking across properties
- Capacity planning predictions

**Multi-Server Architecture:**
- Load balancing across multiple Contabo VPS instances
- Database replication and failover
- Geographic distribution (US Central + EU presence)

**Platform-as-a-Service Features:**
- One-click GeoDirectory site launches (from template to live in <5 minutes)
- Integrated CI/CD for Next.js applications
- Staging/production environment automation per site
- Blue/green deployment capabilities

---

---

## Web Application / Infrastructure Platform Requirements

**HestiaCP Control Panel Integration:**
- Use HestiaCP as the foundational control panel (not building from scratch)
- Leverage HestiaCP's built-in capabilities: user management, DNS (BIND9), email stack, web server config, SSL automation, backups
- Extend HestiaCP with custom scripts and automation where needed
- Work within HestiaCP's architecture and conventions

**Multi-Tenant Architecture:**
- Tenant isolation via HestiaCP user accounts (separate accounts per client/site grouping)
- File system isolation (separate home directories, web roots)
- Process isolation (PHP-FPM pools per user)
- Database isolation (separate MySQL users/permissions per tenant)
- Optional: Separate IP addresses for high-isolation requirements
- Resource limits per tenant (disk quotas, connection limits)

**WordPress-Specific Optimizations:**
- Nginx configuration tuned for WordPress (FastCGI cache rules, static asset handling)
- Redis object caching for WordPress (persistent object cache, reduces DB queries)
- PHP OPcache configured for WordPress bytecode caching
- MariaDB query cache tuning for WordPress workloads
- Support for Elementor + JetEngine + WP Geo Directory plugins (validation required)
- WordPress CLI (WP-CLI) available for automation

**Email Stack Requirements:**
- Full mail server stack: Exim4 (MTA) + Dovecot (IMAP/POP3) + SpamAssassin + ClamAV
- Support for email accounts, forwarders, catch-all addresses, autoresponders
- DKIM/SPF/DMARC configuration for email deliverability
- Webmail client (Roundcube or similar) for browser-based email access
- Email quotas and limits configurable per account
- Spam filtering and virus scanning operational by default

**DNS Management:**
- BIND9 DNS server for self-hosted DNS capability
- Support for Cloudflare-managed DNS as alternative
- DNS zone management via HestiaCP interface
- DNSSEC support (optional, for future)
- Ability to manage DNS records programmatically (for automation)

**SSL/TLS Certificate Management:**
- Let's Encrypt integration for automatic SSL provisioning
- Auto-renewal of certificates (90-day expiry cycle)
- Support for wildcard certificates (if needed)
- Cloudflare Origin Certificates as alternative/supplement
- SNI (Server Name Indication) support for multiple SSL sites on shared IP

**Backup & Disaster Recovery:**
- Local backup system (HestiaCP built-in): daily backups, 7-day retention, stored on server
- Remote backup system: restic + rclone to Backblaze B2 cloud storage
- Incremental backups (minimize storage costs and backup duration)
- Encryption of off-site backups (data security)
- Point-in-time restoration capability (restore to specific date)
- Backup verification (automated integrity checks)
- 3-2-1 backup rule compliance: 3 copies, 2 different media types, 1 off-site

**Migration Tooling:**
- cPanel backup import capability (HestiaCP supports cPanel migration)
- WordPress site migration process (database export/import, file transfer, URL rewrites)
- Email migration (mailbox export from cPanel, import to Dovecot)
- DNS cutover coordination (A-record updates, nameserver changes, TTL management)
- Validation checklist per migrated site (functionality, plugins, email, SSL)

**Multi-Runtime Support (Post-MVP):**
- **Node.js:** PM2 process manager for Node.js applications, systemd integration, environment management
- **Python:** WSGI support (uWSGI or Gunicorn), virtual environment management
- **Ruby:** rbenv or rvm for version management, Passenger or Puma for app serving
- **Reverse Proxy:** Traefik or Nginx proxy configuration for routing requests to non-PHP apps
- **Mixed Applications:** Ability to run PHP (WordPress) + Node.js (Next.js) on same server with proper routing

**Automation & Scripting Requirements:**
- Bash scripting for common operations (site provisioning, email setup, backups)
- HestiaCP CLI/API integration for programmatic control
- Cron job management for scheduled tasks
- Infrastructure-as-code approach (Ansible, Terraform, or bash + git for version control)
- Idempotent scripts (safe to run multiple times without side effects)

**Monitoring & Observability:**
- Uptime monitoring (server availability, service health)
- Resource monitoring (CPU, RAM, disk usage, network)
- Application monitoring (web server response times, PHP-FPM status, database performance)
- Log aggregation (centralized logging for troubleshooting)
- Alert notifications (email/Slack for critical events: disk full, service down, backup failure)
- Security event monitoring (failed login attempts, file integrity)
- Backup job completion tracking

**Platform Infrastructure:**
- **Server:** Contabo VPS, 4 CPU / 8GB RAM, US Central location
- **Operating System:** Ubuntu 22.04 LTS or Debian 11 (HestiaCP supported)
- **Web Server:** Nginx (primary), Apache (optional fallback)
- **PHP:** PHP-FPM 8.1+ (multiple versions supported via HestiaCP)
- **Database:** MariaDB 10.6+
- **Caching:** Redis (object cache, session storage)
- **Email:** Exim4 + Dovecot + SpamAssassin + ClamAV
- **DNS:** BIND9 (self-hosted) or Cloudflare (managed)
- **CDN/Proxy:** Cloudflare (free tier) for DDoS protection and CDN
- **Backup Storage:** Backblaze B2 (S3-compatible, ~$0.005/GB/month)

---

## Functional Requirements

This section defines ALL capabilities the platform must have. These requirements drive UX design (if needed), architecture, and epic breakdown.

### Infrastructure & Server Management

**FR1:** Platform owner can provision Contabo VPS with specified resources (4 CPU / 8GB RAM, US Central location)

**FR2:** Platform owner can install HestiaCP control panel on Ubuntu/Debian server

**FR3:** Platform owner can access HestiaCP web interface for server administration

**FR4:** Platform owner can configure web server stack (Nginx + PHP-FPM + MariaDB + Redis)

**FR5:** Platform owner can apply WordPress-optimized performance configurations (FastCGI cache, OPcache, Redis object cache)

**FR6:** Platform owner can monitor server resource usage (CPU, RAM, disk, network)

**FR7:** Platform owner can apply system updates and security patches

**FR8:** Platform owner can manage server firewall rules and security settings

### User & Tenant Management

**FR9:** Platform owner can create HestiaCP user accounts for multi-tenant isolation

**FR10:** Platform owner can assign resource limits per user (disk quota, bandwidth, connection limits)

**FR11:** Platform owner can configure separate IP addresses for specific tenants (optional high-isolation)

**FR12:** Platform owner can manage user permissions and access levels

**FR13:** Tenant users can access their own HestiaCP account with isolated file system and resources

**FR14:** Platform owner can suspend or delete user accounts

### Website Hosting & Management

**FR15:** Platform owner can create new website hosting accounts via HestiaCP

**FR16:** Platform owner can configure domain names for hosted websites

**FR17:** Platform owner can manage DNS records for hosted domains (A, CNAME, MX, TXT, etc.)

**FR18:** WordPress sites can run with full plugin support (Elementor, JetEngine, WP Geo Directory validated)

**FR19:** Platform owner can install and manage multiple PHP versions per site

**FR20:** Platform owner can configure PHP-FPM pools for process isolation per user/site

**FR21:** Platform owner can manage database instances (create, delete, backup databases)

**FR22:** Platform owner can configure Redis caching for WordPress sites

**FR23:** Hosted websites can serve static and dynamic content via Nginx

### SSL Certificate Management

**FR24:** Platform can automatically provision Let's Encrypt SSL certificates for new domains

**FR25:** Platform can auto-renew SSL certificates before expiration

**FR26:** Platform owner can install custom SSL certificates (including Cloudflare Origin Certificates)

**FR27:** Platform supports SNI (Server Name Indication) for multiple SSL sites on shared IP

**FR28:** Platform owner can manage wildcard SSL certificates if needed

### Email Services

**FR29:** Platform owner can create email accounts for any hosted domain

**FR30:** Platform owner can configure email forwarders (most common use case)

**FR31:** Platform owner can set up catch-all email addresses per domain

**FR32:** Platform owner can configure autoresponders for email accounts

**FR33:** Email users can access email via IMAP/POP3 protocols

**FR34:** Email users can access webmail interface (Roundcube) via browser

**FR35:** Email system automatically filters spam (SpamAssassin)

**FR36:** Email system automatically scans for viruses (ClamAV)

**FR37:** Platform owner can configure DKIM/SPF/DMARC for email deliverability

**FR38:** Platform owner can set email quotas and limits per account

### DNS Management

**FR39:** Platform can run self-hosted DNS server (BIND9) for full DNS independence

**FR40:** Platform owner can manage DNS zones via HestiaCP interface

**FR41:** Platform owner can use Cloudflare-managed DNS as alternative to BIND9

**FR42:** Platform can programmatically manage DNS records for automation

### Backup & Disaster Recovery

**FR43:** Platform automatically executes daily backups of all sites and data

**FR44:** Platform stores local backups with 7-day retention on server

**FR45:** Platform automatically uploads encrypted backups to Backblaze B2 off-site storage

**FR46:** Platform retains off-site backups for 30 days

**FR47:** Platform performs incremental backups to minimize storage costs and duration

**FR48:** Platform owner can restore sites/data to specific point in time

**FR49:** Platform owner can verify backup integrity via automated checks

**FR50:** Platform implements 3-2-1 backup rule (3 copies, 2 media types, 1 off-site)

**FR51:** Platform owner can export backups for archival or migration purposes

### Migration Capabilities

**FR52:** Platform owner can import cPanel backup files into HestiaCP

**FR53:** Platform owner can migrate WordPress sites from cPanel (files, database, configuration)

**FR54:** Platform owner can migrate email accounts from cPanel to Dovecot

**FR55:** Platform owner can execute DNS cutover (update A records, change nameservers)

**FR56:** Platform owner can validate migrated sites (functionality, plugins, email, SSL all working)

**FR57:** Platform owner can perform migration with <4 hours downtime per site

### Monitoring & Alerting

**FR58:** Platform monitors uptime for web services, email services, and database

**FR59:** Platform monitors server resource utilization (CPU, RAM, disk thresholds)

**FR60:** Platform monitors backup job completion and success/failure status

**FR61:** Platform monitors SSL certificate expiration dates

**FR62:** Platform sends alert notifications for critical events (service down, disk full, backup failed)

**FR63:** Platform owner can view logs for troubleshooting (web server, email, database, system)

**FR64:** Platform monitors security events (failed logins, suspicious activity)

**FR65:** Platform tracks website response times and performance metrics

### Automation & Provisioning (Post-MVP Growth)

**FR66:** Platform owner can execute automated site creation (WordPress + HestiaCP account + email + SSL) via script

**FR67:** Platform owner can provision GeoDirectory WordPress sites from template

**FR68:** Platform owner can bulk-create multiple sites from configuration file

**FR69:** Platform owner can automate email account provisioning per domain

**FR70:** Platform owner can version-control infrastructure configuration (git-based)

### Multi-Runtime Support (Post-MVP Growth)

**FR71:** Platform can run Node.js applications alongside PHP sites

**FR72:** Platform can manage Node.js processes via PM2

**FR73:** Platform can run Python WSGI applications

**FR74:** Platform can run Ruby applications

**FR75:** Platform can route requests to appropriate runtime via reverse proxy (Traefik or Nginx)

**FR76:** Platform owner can run mixed application types on same server (WordPress + Next.js apps)

### Security & Compliance

**FR77:** Platform implements file system isolation between tenants

**FR78:** Platform implements process isolation (separate PHP-FPM pools)

**FR79:** Platform implements database access isolation (separate DB users/permissions)

**FR80:** Platform owner can configure firewall rules for network security

**FR81:** Platform performs automated security scanning (Lynis or similar)

**FR82:** Platform owner can apply security patches via system updates

**FR83:** Platform protects against common attacks via Cloudflare (DDoS, brute force)

### Cloudflare Integration

**FR84:** Platform owner can configure Cloudflare as CDN/proxy in front of hosted sites

**FR85:** Platform supports Cloudflare-managed DNS as alternative to BIND9

**FR86:** Platform can use Cloudflare Origin Certificates for SSL

**FR87:** Platform leverages Cloudflare for DDoS protection and caching

---

## Non-Functional Requirements

### Performance

**NFR-P1: WordPress Response Time**
- Uncached page load: <2 seconds (95th percentile)
- Cached page load: <500ms (95th percentile)
- Rationale: Current cPanel performance baseline; user expectation for low-traffic sites

**NFR-P2: Database Query Performance**
- WordPress admin dashboard load: <3 seconds
- MariaDB query cache hit rate: >80%
- Rationale: Efficient WordPress operation, especially with Elementor/JetEngine

**NFR-P3: Email Delivery Performance**
- Email send/receive latency: <10 seconds under normal load
- Webmail interface response: <2 seconds
- Rationale: Acceptable for low-volume email (<50 accounts)

**NFR-P4: Resource Utilization Targets**
- CPU usage baseline: <30% average (headroom for traffic spikes)
- RAM usage baseline: <60% (4.8GB of 8GB, leaves buffer)
- Disk I/O: Support for 20+ WordPress sites with simultaneous writes
- Rationale: 4 CPU / 8GB RAM must support ~20 WordPress sites + email + backups

**NFR-P5: Backup Performance**
- Daily backup completion: <2 hours for all sites
- Incremental backup to B2: <30 minutes
- Restore operation: <1 hour per site
- Rationale: Minimize backup window, acceptable restore time for low-traffic sites

### Security

**NFR-S1: Data Protection**
- All off-site backups encrypted at rest (AES-256 or equivalent)
- Database credentials stored securely (not in plain text config files)
- Rationale: Client data protection, industry best practice

**NFR-S2: Network Security**
- SSH access limited to key-based authentication (no password auth)
- Firewall (UFW/iptables) configured with minimal open ports (80, 443, 22, 25, 587, 993, 995)
- Cloudflare proxy hides origin IP from public (DDoS protection)
- Rationale: Prevent unauthorized access, reduce attack surface

**NFR-S3: Tenant Isolation**
- File system permissions prevent cross-tenant file access
- PHP-FPM pools run under separate user contexts
- Database users limited to own databases only
- Rationale: One compromised site cannot affect others

**NFR-S4: Email Security**
- SPF/DKIM/DMARC configured for all domains (email authentication)
- TLS required for SMTP/IMAP connections
- Spam filtering active (SpamAssassin) with reasonable false-positive rate (<5%)
- Virus scanning active (ClamAV) on all incoming email
- Rationale: Email deliverability, prevent malware spread

**NFR-S5: Update Cadence**
- Security patches applied within 7 days of release
- HestiaCP updates applied within 14 days (after stability verification)
- WordPress core/plugin updates: as needed, tested on staging first
- Rationale: Balance security with stability

**NFR-S6: Authentication & Access**
- HestiaCP admin access protected by strong password (16+ characters)
- Failed login attempt monitoring and alerting
- Session timeout after 30 minutes of inactivity
- Rationale: Prevent brute force attacks, limit exposure of idle sessions

### Reliability & Availability

**NFR-R1: Uptime Target**
- Platform uptime: 99.5% monthly (allows ~3.6 hours downtime/month)
- Rationale: Internal platform, non-critical traffic, acceptable for cost savings vs managed hosting

**NFR-R2: Backup Reliability**
- Backup success rate: 100% (zero missed daily backups)
- Backup integrity verification: weekly automated checks
- Tested restoration: quarterly restore drills
- Rationale: Data loss prevention is critical, more important than uptime for this use case

**NFR-R3: Service Recovery**
- Automatic service restart on failure (systemd watchdog for critical services)
- Email notification within 5 minutes of service failure
- Manual intervention acceptable for recovery (no 24/7 on-call requirement)
- Rationale: Balance automation with cost (internal platform, not customer-facing)

**NFR-R4: Data Durability**
- Local backups: 7-day retention (protects against accidental deletion)
- Off-site backups: 30-day retention (protects against server failure)
- 3-2-1 backup rule compliance (3 copies, 2 media, 1 off-site)
- Rationale: Comprehensive data protection strategy

### Scalability

**NFR-SC1: Horizontal Capacity**
- Platform supports 20 domains initially (current requirement)
- Infrastructure capable of 50+ domains on same hardware (future growth)
- Rationale: 4CPU/8GB can handle 50+ low-traffic WordPress sites with proper optimization

**NFR-SC2: Resource Scalability**
- Ability to resize VPS vertically (add CPU/RAM) without data migration
- Architecture supports adding second VPS if needed (database replication, load balancing)
- Rationale: Growth path exists if single-server limit reached

**NFR-SC3: Automated Provisioning Scalability**
- Post-MVP automation should support provisioning 5+ sites in <30 minutes (bulk operations)
- Rationale: Future efficiency for GeoDirectory site launches

### Maintainability & Operations

**NFR-M1: Configuration Management**
- Server configuration version-controlled (git repository for scripts, configs)
- Changes documented with commit messages
- Rollback capability for configuration changes
- Rationale: Repeatability, disaster recovery, change tracking

**NFR-M2: Observability**
- Centralized logging for troubleshooting (all services log to syslog or equivalent)
- Log retention: 30 days minimum
- Metrics dashboard accessible via web interface
- Rationale: Efficient troubleshooting, capacity planning

**NFR-M3: Automation Idempotency**
- All automation scripts safe to run multiple times (idempotent)
- No manual cleanup required after script execution
- Rationale: Reliability, reduce operational errors

**NFR-M4: Documentation**
- Migration runbook documented (step-by-step)
- Disaster recovery procedures documented and tested
- Common operations documented (add site, add email, restore backup)
- Rationale: Knowledge preservation, reduce cognitive load

### Cost Efficiency

**NFR-C1: Operating Cost Target**
- Total monthly cost: ≤$10/month (Contabo VPS ~$7 + Backblaze B2 ~$0.50-$2)
- Rationale: 91% cost reduction vs current $80/month cPanel reseller

**NFR-C2: Storage Cost Optimization**
- Incremental backups minimize B2 storage costs
- Backup compression enabled
- Old backups automatically pruned (30-day retention)
- Rationale: Keep B2 costs under $2/month for ~20 sites

### Compatibility & Integration

**NFR-I1: WordPress Plugin Compatibility**
- Full compatibility with Elementor Pro, JetEngine, WP Geo Directory
- Support for common WordPress plugins (WooCommerce, Yoast, Contact Form 7, etc.)
- Rationale: These are mandatory for current sites; failure = migration failure

**NFR-I2: Browser Compatibility (HestiaCP/Webmail)**
- HestiaCP admin interface works on modern browsers (Chrome, Firefox, Safari, Edge - latest 2 versions)
- Webmail (Roundcube) accessible on desktop and mobile browsers
- Rationale: Cross-device administration capability

**NFR-I3: Email Client Compatibility**
- IMAP/SMTP compatible with standard email clients (Outlook, Thunderbird, Apple Mail, mobile clients)
- Auto-discovery support for easy email client configuration
- Rationale: Seamless email migration experience for users

**NFR-I4: Cloudflare Integration**
- Compatible with Cloudflare proxy (origin IP hidden)
- Supports Cloudflare SSL modes (Flexible, Full, Full Strict)
- Works with Cloudflare free tier features
- Rationale: Leverage Cloudflare for DDoS protection and CDN at no cost

---

## PRD Summary

**CFE Web Host 26** is a self-managed hosting platform that transforms hosting costs from $80/month to ~$7/month while gaining complete platform control. This PRD captures:

- **87 Functional Requirements** across infrastructure, hosting, email, DNS, backups, migration, monitoring, automation, multi-runtime support, security, and Cloudflare integration
- **Comprehensive Non-Functional Requirements** covering performance, security, reliability, scalability, maintainability, cost efficiency, and compatibility
- **Phased Implementation Strategy** from MVP migration (20 sites) to automated provisioning to multi-runtime support to infrastructure-as-code

**Product Value:** Own the platform, define the features, control the automation. Build hosting-as-a-product with complete flexibility for future GeoDirectory site launches, Next.js applications, and custom infrastructure automation.

**Next Steps After This PRD:**
1. **UX Design** (optional - minimal UI needed beyond HestiaCP)
2. **Architecture** (required - technical design for stack, backups, automation, monitoring)
3. **Epic Breakdown** (required - break down into implementable stories)
4. **Implementation** (execute migration + automation development)

---

_This PRD captures the essence of CFE Web Host 26 - a cost-effective, self-managed hosting platform with complete control over infrastructure, automation, and future capabilities._

_Created through collaborative discovery between cfebrian and AI Product Manager._
