# ConfidentialHost - HestiaCP Hosting Platform

**Self-managed hosting platform built on HestiaCP and Contabo VPS infrastructure**

---

## Overview

ConfidentialHost is a simplified, self-managed hosting platform designed to replace traditional cPanel reseller accounts with a cost-effective, isolated environment for hosting WordPress sites. Built on HestiaCP 1.9.4 and Ubuntu 24.04 LTS.

**Primary Server:** `host1.confidentialhost.com` (IP: 217.216.40.207)

---

## Quick Start

### For New Clients

Use the automated onboarding script:

```bash
sudo ./scripts/quick-onboard.sh
```

Or see the full guide: [Client Onboarding Workflow](docs/client-onboarding-workflow.md)

### For cPanel Migrations

Use the migration script:

```bash
./scripts/migrate-cpanel-account.sh \
  --backup /tmp/cpmove-username.tar.gz \
  --hestia-user newusername \
  --domain example.com \
  --dry-run
```

See: [Migration Checklist](docs/sprint-artifacts/migration-checklist.md)

---

## Documentation

### Getting Started
- **[Client Onboarding Workflow](docs/client-onboarding-workflow.md)** - Complete guide for adding new clients
- **[Quick Reference Card](docs/quick-reference-onboarding.md)** - Common commands and workflows
- **[Migration Checklist](docs/sprint-artifacts/migration-checklist.md)** - cPanel to HestiaCP migration steps

### Planning & Architecture
- **[PRD](docs/prd.md)** - Product requirements and scope
- **[Architecture](docs/architecture.md)** - Technical architecture and patterns
- **[Epics & Stories](docs/epics.md)** - Project breakdown

### Scripts
- **[quick-onboard.sh](scripts/quick-onboard.sh)** - Interactive client onboarding
- **[migrate-cpanel-account.sh](scripts/migrate-cpanel-account.sh)** - Automated cPanel migration
- **[provision-vps.sh](scripts/provision-vps.sh)** - Initial server provisioning
- **[hestia-ssh-harden.sh](scripts/hestia-ssh-harden.sh)** - SSH security hardening

---

## Technology Stack

- **OS:** Ubuntu 24.04 LTS
- **Control Panel:** HestiaCP 1.9.4
- **Web Server:** Nginx 1.28.0 + Apache
- **PHP:** PHP-FPM 8.1+ (multi-version support)
- **Database:** MariaDB 11.4 LTS
- **Email:** Exim4 + Dovecot + SnappyMail
- **DNS:** BIND9 (+ Cloudflare option)
- **Backups:** Rclone + Backblaze B2
- **Security:** Fail2Ban, ClamAV, ModSecurity
- **Caching:** Redis + PHP OPcache

---

## Features

### Hosting
- ✅ WordPress-optimized environment
- ✅ Multi-PHP version support
- ✅ Let's Encrypt SSL (automatic)
- ✅ Redis object caching
- ✅ FastCGI page caching
- ✅ ModSecurity WAF

### Email
- ✅ Full email hosting (SMTP, IMAP, POP3)
- ✅ Webmail (SnappyMail)
- ✅ Spam filtering (SpamAssassin)
- ✅ Virus scanning (ClamAV)
- ✅ DKIM, SPF, DMARC

### DNS
- ✅ Authoritative nameservers (ns1/ns2.confidentialhost.com)
- ✅ Cloudflare integration option
- ✅ Automatic DNS record management

### Backups
- ✅ Daily local backups (7-day retention)
- ✅ Off-site backups to Backblaze B2 (30-day retention)
- ✅ Encrypted, incremental, deduplicated

### Security
- ✅ SSH key-based authentication only
- ✅ Fail2Ban intrusion prevention
- ✅ Daily ClamAV scans
- ✅ Firewall (iptables/UFW)
- ✅ AppArmor profiles

---

## Common Tasks

### Create New Client

```bash
# Interactive
sudo ./scripts/quick-onboard.sh

# Manual
sudo /usr/local/hestia/bin/v-add-user username password email@domain.com
sudo /usr/local/hestia/bin/v-add-domain username domain.com
sudo /usr/local/hestia/bin/v-add-letsencrypt-domain username domain.com
```

### Add Domain to Existing Client

```bash
sudo /usr/local/hestia/bin/v-add-domain username newdomain.com
sudo /usr/local/hestia/bin/v-add-letsencrypt-domain username newdomain.com
```

### Create Email Account

```bash
sudo /usr/local/hestia/bin/v-add-mail-domain username domain.com
sudo /usr/local/hestia/bin/v-add-mail-account username domain.com info password
```

### Migrate from cPanel

```bash
./scripts/migrate-cpanel-account.sh \
  --backup /tmp/cpmove-user.tar.gz \
  --hestia-user newuser \
  --domain example.com \
  --apply --yes
```

See [Quick Reference](docs/quick-reference-onboarding.md) for more commands.

---

## Access Points

### HestiaCP Panel
- **URL:** https://panel.confidentialhost.com:8083
- **Admin User:** cfeadmin
- **Features:** User management, domain configuration, email, DNS, backups

### Webmail
- **URL:** https://webmail.confidentialhost.com
- **Client:** SnappyMail
- **Protocols:** IMAP (993), SMTP (587)

### SSH Access
- **Host:** 217.216.40.207
- **Port:** 22
- **Auth:** SSH keys only (password auth disabled)
- **Users:** root disabled, use sudo user

---

## Project Structure

```
webserver-hestia/
├── docs/                          # Documentation
│   ├── client-onboarding-workflow.md
│   ├── quick-reference-onboarding.md
│   ├── architecture.md
│   ├── prd.md
│   ├── epics.md
│   └── sprint-artifacts/
│       └── migration-checklist.md
├── scripts/                       # Automation scripts
│   ├── quick-onboard.sh          # Interactive client onboarding
│   ├── migrate-cpanel-account.sh # cPanel migration
│   ├── provision-vps.sh          # Server provisioning
│   ├── hestia-ssh-harden.sh      # SSH hardening
│   └── ...
├── ansible/                       # Ansible playbooks (future)
└── README.md                      # This file
```

---

## Server Information

### Primary Server
- **Hostname:** host1.confidentialhost.com
- **IP Address:** 217.216.40.207
- **Location:** US Central (Contabo)
- **Specs:** 4 CPU / 8GB RAM
- **OS:** Ubuntu 24.04 LTS
- **Panel:** HestiaCP 1.9.4

### Nameservers
- **Primary:** ns1.confidentialhost.com (217.216.40.207)
- **Secondary:** ns2.confidentialhost.com (217.216.40.207)

### Backup Storage
- **Local:** /var/backup (7-day retention)
- **Off-site:** Backblaze B2 (30-day retention)
- **Encryption:** Yes (restic)

---

## Support

### Documentation
- Full documentation in `docs/` directory
- Quick reference: `docs/quick-reference-onboarding.md`
- HestiaCP docs: https://docs.hestiacp.com/

### Troubleshooting
- Check logs: `/var/log/hestia/`, `/var/log/nginx/`, `/var/log/exim4/`
- Service status: `sudo systemctl status hestia nginx php8.1-fpm mariadb exim4 dovecot`
- Rebuild configs: `sudo /usr/local/hestia/bin/v-rebuild-user username`

### Emergency
- Contact system administrator
- Check monitoring: Netdata dashboard (if configured)
- Review backup status: `sudo /usr/local/hestia/bin/v-list-user-backups username`

---

## Development

### Contributing
1. Create feature branch
2. Test changes on development server
3. Update documentation
4. Submit for review

### Testing
- Always use `--dry-run` flag when available
- Test on non-production domains first
- Verify backups before major changes

---

## License

Internal use only - ConfidentialHost platform

---

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | 2025-12-24 | Initial server setup and HestiaCP installation |
| 1.1 | 2025-12-25 | Added client onboarding documentation and scripts |

---

**Last Updated:** 2025-12-25  
**Maintained By:** cfeaiagent
