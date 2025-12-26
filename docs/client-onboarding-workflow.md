# Client Onboarding Workflow

**Version:** 1.0  
**Last Updated:** 2025-12-25  
**Purpose:** Standard operating procedure for adding new clients and websites to the ConfidentialHost HestiaCP platform.

---

## Overview

This document defines the complete workflow for onboarding new clients to the ConfidentialHost platform. There are two primary scenarios:

1. **New Client (Fresh Site)** - Creating a brand new WordPress site or hosting account
2. **Migrating Client (From cPanel)** - Migrating an existing site from a cPanel/WHM environment

---

## Prerequisites

Before onboarding any client, ensure:

- [ ] HestiaCP is installed and operational
- [ ] Server has sufficient resources (check disk space, RAM, CPU usage)
- [ ] Backups are configured and running
- [ ] DNS is properly configured (ns1/ns2.confidentialhost.com)
- [ ] SSL certificates are auto-renewing via Let's Encrypt
- [ ] You have admin access to HestiaCP panel (port 8083)

---

## Scenario 1: New Client (Fresh WordPress Site)

### Step 1: Gather Client Information

Collect the following information from the client:

- **Domain name** (e.g., `example.com`)
- **Desired username** (lowercase, alphanumeric, no special chars except hyphen)
- **Contact email** (for HestiaCP notifications)
- **Email accounts needed** (list of email addresses to create)
- **PHP version preference** (default: PHP 8.1+)
- **Special requirements** (Node.js apps, specific PHP modules, etc.)

### Step 2: Create HestiaCP User Account

**Via HestiaCP Web UI:**

1. Log in to HestiaCP at `https://panel.confidentialhost.com:8083`
2. Navigate to **Users** → **Add User**
3. Fill in the form:
   - Username: `clientname` (lowercase, no spaces)
   - Password: Generate strong password (16+ characters)
   - Email: Client's contact email
   - Package: Select appropriate package (or use default)
4. Click **Save**

**Via CLI (Alternative):**

```bash
sudo /usr/local/hestia/bin/v-add-user clientname 'SecurePassword123!' client@example.com
```

**Important:** Save the generated credentials securely (password manager recommended).

### Step 3: Add Domain to User Account

**Via HestiaCP Web UI:**

1. Navigate to **Web** → **Add Web Domain**
2. Select the user created in Step 2
3. Enter the domain name: `example.com`
4. Configure options:
   - Enable SSL: **Yes** (Let's Encrypt)
   - Enable DNS: **Yes** (if using HestiaCP nameservers)
   - PHP Version: Select appropriate version (8.1+ recommended)
5. Click **Save**

**Via CLI (Alternative):**

```bash
# Add domain
sudo /usr/local/hestia/bin/v-add-domain clientname example.com

# Enable SSL (Let's Encrypt)
sudo /usr/local/hestia/bin/v-add-letsencrypt-domain clientname example.com
```

### Step 4: Create Database for WordPress

**Via HestiaCP Web UI:**

1. Navigate to **DB** → **Add Database**
2. Select the user
3. Fill in:
   - Database name: `wp_example` (or similar)
   - Database user: `wp_user_example`
   - Password: Generate strong password
4. Click **Save**

**Via CLI (Alternative):**

```bash
# Generate a secure password
DB_PASS=$(tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 20)

# Create database
sudo /usr/local/hestia/bin/v-add-database clientname wp_example wp_user_example "$DB_PASS"

# Save credentials securely
echo "Database: wp_example, User: wp_user_example, Password: $DB_PASS"
```

### Step 5: Install WordPress

**Option A: Manual Installation**

1. Download WordPress:
```bash
cd /home/clientname/web/example.com/public_html
sudo -u clientname wget https://wordpress.org/latest.tar.gz
sudo -u clientname tar -xzf latest.tar.gz --strip-components=1
sudo -u clientname rm latest.tar.gz
```

2. Create `wp-config.php`:
```bash
sudo -u clientname cp wp-config-sample.php wp-config.php
```

3. Edit `wp-config.php` with database credentials from Step 4

4. Complete installation via browser: `https://example.com/wp-admin/install.php`

**Option B: WP-CLI Installation (Recommended)**

```bash
# Navigate to document root
cd /home/clientname/web/example.com/public_html

# Download WordPress
sudo -u clientname wp core download

# Create wp-config.php
sudo -u clientname wp config create \
  --dbname=wp_example \
  --dbuser=wp_user_example \
  --dbpass="$DB_PASS" \
  --dbhost=localhost

# Install WordPress
sudo -u clientname wp core install \
  --url=https://example.com \
  --title="Client Site" \
  --admin_user=admin \
  --admin_password="SecureAdminPass123!" \
  --admin_email=client@example.com
```

### Step 6: Configure Email Accounts

**Via HestiaCP Web UI:**

1. Navigate to **Mail** → **Add Mail Domain**
2. Select user and enter domain: `example.com`
3. Click **Save**
4. Navigate to **Mail** → **Add Mail Account**
5. For each email account:
   - Account: `info` (for info@example.com)
   - Password: Generate strong password
   - Quota: Set appropriate limit (default: 1GB)
6. Click **Save**

**Via CLI (Alternative):**

```bash
# Add mail domain
sudo /usr/local/hestia/bin/v-add-mail-domain clientname example.com

# Add mail account
sudo /usr/local/hestia/bin/v-add-mail-account clientname example.com info 'SecureMailPass123!'
```

### Step 7: Configure DNS Records

**If using HestiaCP nameservers (ns1/ns2.confidentialhost.com):**

1. DNS records are automatically created by HestiaCP
2. Provide client with nameserver information:
   - Primary NS: `ns1.confidentialhost.com`
   - Secondary NS: `ns2.confidentialhost.com`
3. Client updates nameservers at their domain registrar

**If using Cloudflare or external DNS:**

1. Provide client with the following DNS records to add:
   - **A Record**: `@` → `217.216.40.207` (server IP)
   - **A Record**: `www` → `217.216.40.207`
   - **MX Record**: `@` → `mail.example.com` (Priority: 10)
   - **A Record**: `mail` → `217.216.40.207`
   - **TXT Record**: SPF record (see HestiaCP DNS zone for exact value)
   - **TXT Record**: DKIM record (see HestiaCP DNS zone for exact value)

### Step 8: Verify Installation

**Website Verification:**
- [ ] Visit `https://example.com` - site loads correctly
- [ ] SSL certificate is valid (green padlock)
- [ ] WordPress admin accessible at `https://example.com/wp-admin`
- [ ] No PHP errors in logs

**Email Verification:**
- [ ] Send test email from webmail: `https://webmail.confidentialhost.com`
- [ ] Receive test email from external account
- [ ] Check spam score (mail-tester.com)
- [ ] Verify DKIM/SPF/DMARC records

**Performance Verification:**
- [ ] Page load time < 2 seconds (uncached)
- [ ] Redis object cache enabled (if applicable)
- [ ] PHP OPcache enabled

### Step 9: Client Handoff

Provide the client with:

1. **HestiaCP Access:**
   - URL: `https://panel.confidentialhost.com:8083`
   - Username: `clientname`
   - Password: (from Step 2)

2. **WordPress Access:**
   - URL: `https://example.com/wp-admin`
   - Username: `admin` (or custom)
   - Password: (from Step 5)

3. **Email Access:**
   - Webmail: `https://webmail.confidentialhost.com`
   - IMAP Server: `mail.example.com` (Port: 993, SSL)
   - SMTP Server: `mail.example.com` (Port: 587, STARTTLS)
   - Username: `info@example.com`
   - Password: (from Step 6)

4. **DNS Information:**
   - Nameservers: `ns1.confidentialhost.com`, `ns2.confidentialhost.com`
   - Or specific DNS records if using external DNS

5. **Support Information:**
   - Support email: `support@confidentialhost.com`
   - Documentation: Link to knowledge base (if available)

---

## Scenario 2: Migrating Client (From cPanel)

### Overview

Use the automated migration script for cPanel to HestiaCP migrations. This script handles:
- User account creation
- Domain configuration
- Website files transfer
- Database migration
- Email account migration
- WordPress configuration updates

### Prerequisites

- [ ] Full cPanel backup available (`cpmove-username.tar.gz`)
- [ ] SSH access to old cPanel server (if fetching remotely)
- [ ] Client domain information
- [ ] Downtime window scheduled with client

### Migration Process

#### Step 1: Obtain cPanel Backup

**Option A: Generate on cPanel Server (requires root/WHM access)**

```bash
# SSH to cPanel server as root
ssh root@old-cpanel-server.com

# Generate full backup for user
/scripts/pkgacct username

# Backup will be created in /home/cpmove-username.tar.gz
```

**Option B: Client-Generated Backup**

1. Client logs into cPanel
2. Navigate to **Files** → **Backup**
3. Click **Download a Full Account Backup**
4. Wait for backup to complete
5. Download `backup-*.tar.gz` file
6. Rename to `cpmove-username.tar.gz` format

#### Step 2: Transfer Backup to HestiaCP Server

**If backup is local:**
```bash
# Upload to HestiaCP server
scp cpmove-username.tar.gz root@217.216.40.207:/tmp/
```

**If backup is on remote cPanel server:**
```bash
# Script will fetch it automatically (see Step 3)
```

#### Step 3: Run Migration Script

**Dry-Run First (Recommended):**

```bash
cd /home/cmdev/cmdev-antigravity/webserver-hestia

# Local backup
./scripts/migrate-cpanel-account.sh \
  --backup /tmp/cpmove-username.tar.gz \
  --hestia-user newusername \
  --domain example.com \
  --dry-run

# Remote backup
./scripts/migrate-cpanel-account.sh \
  --remote root@old-cpanel.example.com:/home/cpmove-username.tar.gz \
  --hestia-user newusername \
  --domain example.com \
  --dry-run
```

**Review the dry-run output carefully!**

**Execute Migration:**

```bash
# Remove --dry-run and add --apply --yes
./scripts/migrate-cpanel-account.sh \
  --backup /tmp/cpmove-username.tar.gz \
  --hestia-user newusername \
  --domain example.com \
  --apply \
  --yes
```

#### Step 4: Post-Migration Verification

**Website Verification:**
- [ ] Test site using hosts file override (before DNS change)
  ```bash
  # On your local machine, edit /etc/hosts (Linux/Mac) or C:\Windows\System32\drivers\etc\hosts (Windows)
  217.216.40.207 example.com www.example.com
  ```
- [ ] Visit `https://example.com` - site loads correctly
- [ ] WordPress admin accessible
- [ ] All pages/posts display correctly
- [ ] Images and media load properly
- [ ] Plugins are active and functional
- [ ] Theme displays correctly

**Database Verification:**
- [ ] Database imported successfully
- [ ] WordPress URLs updated to new domain (if changed)
- [ ] No database connection errors
- [ ] All custom tables present

**Email Verification:**
- [ ] All email accounts created
- [ ] Mailboxes contain existing emails
- [ ] Test send/receive from each account
- [ ] Email forwarders configured (manual step)

**SSL Verification:**
- [ ] Let's Encrypt certificate issued
- [ ] HTTPS redirects working
- [ ] No mixed content warnings

#### Step 5: DNS Cutover

**Preparation (24-48 hours before):**
1. Reduce DNS TTL to 300 seconds (5 minutes) for:
   - A records
   - MX records
   - CNAME records
2. Wait for TTL to expire globally

**Cutover:**
1. Update DNS records to point to new server:
   - **A Record**: `@` → `217.216.40.207`
   - **A Record**: `www` → `217.216.40.207`
   - **MX Record**: `@` → `mail.example.com` (Priority: 10)
   - **A Record**: `mail` → `217.216.40.207`

2. Monitor DNS propagation:
```bash
# Check from multiple locations
dig example.com @8.8.8.8
dig example.com @1.1.1.1

# Use online tools
# https://www.whatsmydns.net/#A/example.com
```

3. Keep old cPanel server running in read-only mode for 24-72 hours

#### Step 6: Post-Cutover Monitoring

**First 24 Hours:**
- [ ] Monitor web server logs for errors
- [ ] Check email delivery (no bounces)
- [ ] Monitor server resources (CPU, RAM, disk)
- [ ] Verify backups are running on new server

**First Week:**
- [ ] Monitor site performance
- [ ] Check for any broken functionality
- [ ] Verify all cron jobs are running
- [ ] Ensure SSL auto-renewal is configured

#### Step 7: Decommission Old Server

**After 7 days of stable operation:**
- [ ] Verify all data migrated successfully
- [ ] Confirm backups are working on new server
- [ ] Archive final backup from old server
- [ ] Cancel/terminate old cPanel hosting account

### Migration Checklist Reference

For detailed migration steps, see: [`docs/sprint-artifacts/migration-checklist.md`](sprint-artifacts/migration-checklist.md)

---

## Common Tasks

### Adding Additional Domains to Existing User

**Addon Domain (separate site):**
```bash
sudo /usr/local/hestia/bin/v-add-domain username addondomain.com
sudo /usr/local/hestia/bin/v-add-letsencrypt-domain username addondomain.com
```

**Subdomain:**
```bash
sudo /usr/local/hestia/bin/v-add-domain username sub.maindomain.com
```

**Domain Alias (same content as main domain):**
```bash
sudo /usr/local/hestia/bin/v-add-domain-alias username maindomain.com alias.com
```

### Creating Email Forwarders

**Via CLI:**
```bash
# Forward info@example.com to external@gmail.com
sudo /usr/local/hestia/bin/v-add-mail-account-forward username example.com info external@gmail.com
```

**Via Web UI:**
1. Navigate to **Mail** → Select domain
2. Click on email account
3. Add forward address in **Forward to** field

### Changing PHP Version for Domain

**Via CLI:**
```bash
sudo /usr/local/hestia/bin/v-change-web-domain-backend-tpl username example.com PHP-8_1
```

**Via Web UI:**
1. Navigate to **Web** → Select domain
2. Click **Edit**
3. Change **Backend Template** to desired PHP version
4. Click **Save**

### Installing SSL Certificate

**Let's Encrypt (Automatic):**
```bash
sudo /usr/local/hestia/bin/v-add-letsencrypt-domain username example.com
```

**Custom SSL Certificate:**
```bash
sudo /usr/local/hestia/bin/v-add-web-domain-ssl username example.com /path/to/cert.crt /path/to/private.key
```

---

## Troubleshooting

### Website Not Loading

**Check DNS:**
```bash
dig example.com
nslookup example.com
```

**Check Nginx:**
```bash
sudo systemctl status nginx
sudo nginx -t  # Test configuration
sudo tail -f /var/log/nginx/error.log
```

**Check PHP-FPM:**
```bash
sudo systemctl status php8.1-fpm
sudo tail -f /var/log/php8.1-fpm.log
```

### Email Not Sending/Receiving

**Check Exim (SMTP):**
```bash
sudo systemctl status exim4
sudo tail -f /var/log/exim4/mainlog
```

**Check Dovecot (IMAP/POP3):**
```bash
sudo systemctl status dovecot
sudo tail -f /var/log/dovecot.log
```

**Test SMTP:**
```bash
telnet mail.example.com 587
# Or use swaks
swaks --to test@example.com --from sender@example.com --server mail.example.com
```

### SSL Certificate Issues

**Check certificate status:**
```bash
sudo /usr/local/hestia/bin/v-list-web-domain-ssl username example.com
```

**Force renewal:**
```bash
sudo /usr/local/hestia/bin/v-update-letsencrypt-domain username example.com
```

**Check Let's Encrypt logs:**
```bash
sudo tail -f /var/log/hestia/letsencrypt.log
```

### Database Connection Errors

**Check MariaDB:**
```bash
sudo systemctl status mariadb
sudo mysql -u root -p
```

**Verify database exists:**
```bash
sudo /usr/local/hestia/bin/v-list-databases username
```

**Check wp-config.php:**
```bash
cat /home/username/web/example.com/public_html/wp-config.php | grep DB_
```

---

## Best Practices

### Security

1. **Use strong passwords** for all accounts (16+ characters, mixed case, numbers, symbols)
2. **Enable 2FA** for HestiaCP admin account
3. **Limit user permissions** - only grant necessary access
4. **Regular updates** - keep WordPress core, themes, and plugins updated
5. **Monitor logs** - check for suspicious activity regularly

### Performance

1. **Enable caching:**
   - Redis object cache for WordPress
   - Nginx FastCGI cache (if applicable)
   - Browser caching headers

2. **Optimize images:**
   - Use WebP format when possible
   - Implement lazy loading
   - Use CDN for static assets (Cloudflare)

3. **Database optimization:**
   - Regular cleanup of transients
   - Optimize database tables monthly
   - Monitor slow queries

### Backups

1. **Verify backups are running:**
```bash
sudo /usr/local/hestia/bin/v-list-user-backups username
```

2. **Test restore process** quarterly for each client

3. **Monitor backup storage:**
```bash
df -h /var/backup
```

### Documentation

1. **Maintain client records:**
   - Username and contact info
   - Domains hosted
   - Special configurations
   - Support tickets/issues

2. **Document custom configurations:**
   - Non-standard PHP modules
   - Custom Nginx rules
   - Cron jobs
   - Third-party integrations

---

## Automation Opportunities

### Future Enhancements

1. **Automated WordPress Installation Script**
   - One-command WordPress setup with best practices
   - Automatic plugin installation (security, caching, SEO)
   - Pre-configured settings

2. **Client Onboarding Dashboard**
   - Web form for gathering client information
   - Automated account creation
   - Email notifications to client with credentials

3. **Migration Queue System**
   - Schedule multiple migrations
   - Progress tracking
   - Automated verification tests

4. **Monitoring Integration**
   - Automatic Netdata alerts per client
   - Uptime monitoring
   - Performance tracking

---

## Related Documentation

- [Architecture Document](architecture.md) - Technical architecture and patterns
- [Migration Checklist](sprint-artifacts/migration-checklist.md) - Detailed migration steps
- [PRD](prd.md) - Product requirements and scope
- [Epics & Stories](epics.md) - Project breakdown

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-12-25 | cfeaiagent | Initial documentation for Story 5.2 |

---

## Support

For issues or questions about client onboarding:
- **Email:** support@confidentialhost.com
- **Documentation:** This file
- **Emergency:** Contact system administrator

---

**End of Client Onboarding Workflow**
