# Client Onboarding - Quick Reference Card

**Quick access guide for common HestiaCP client onboarding commands**

---

## Quick Onboarding (Automated)

```bash
# Interactive onboarding script
sudo ./scripts/quick-onboard.sh
```

This script will:
- Create HestiaCP user
- Add domain with SSL
- Create WordPress database
- Configure email domain
- Create default email account
- Generate and save all credentials

---

## Manual Commands Reference

### User Management

```bash
# Create new user
sudo /usr/local/hestia/bin/v-add-user USERNAME PASSWORD EMAIL

# List all users
sudo /usr/local/hestia/bin/v-list-users

# Delete user (and all domains/data)
sudo /usr/local/hestia/bin/v-delete-user USERNAME

# Change user password
sudo /usr/local/hestia/bin/v-change-user-password USERNAME NEW_PASSWORD

# Suspend user
sudo /usr/local/hestia/bin/v-suspend-user USERNAME

# Unsuspend user
sudo /usr/local/hestia/bin/v-unsuspend-user USERNAME
```

### Domain Management

```bash
# Add domain
sudo /usr/local/hestia/bin/v-add-domain USERNAME DOMAIN

# Add domain with specific IP
sudo /usr/local/hestia/bin/v-add-domain USERNAME DOMAIN IP

# List domains for user
sudo /usr/local/hestia/bin/v-list-web-domains USERNAME

# Delete domain
sudo /usr/local/hestia/bin/v-delete-domain USERNAME DOMAIN

# Add domain alias (points to same content)
sudo /usr/local/hestia/bin/v-add-domain-alias USERNAME DOMAIN ALIAS_DOMAIN

# Add subdomain (separate site)
sudo /usr/local/hestia/bin/v-add-domain USERNAME subdomain.domain.com
```

### SSL Certificates

```bash
# Add Let's Encrypt SSL
sudo /usr/local/hestia/bin/v-add-letsencrypt-domain USERNAME DOMAIN

# Add Let's Encrypt SSL with www alias
sudo /usr/local/hestia/bin/v-add-letsencrypt-domain USERNAME DOMAIN www

# Force SSL renewal
sudo /usr/local/hestia/bin/v-update-letsencrypt-domain USERNAME DOMAIN

# List SSL certificates
sudo /usr/local/hestia/bin/v-list-web-domain-ssl USERNAME DOMAIN

# Delete SSL certificate
sudo /usr/local/hestia/bin/v-delete-letsencrypt-domain USERNAME DOMAIN
```

### Database Management

```bash
# Create database
sudo /usr/local/hestia/bin/v-add-database USERNAME DB_NAME DB_USER DB_PASSWORD

# List databases for user
sudo /usr/local/hestia/bin/v-list-databases USERNAME

# Delete database
sudo /usr/local/hestia/bin/v-delete-database USERNAME DB_NAME

# Change database password
sudo /usr/local/hestia/bin/v-change-database-password USERNAME DB_NAME DB_USER NEW_PASSWORD

# Add database user to existing database
sudo /usr/local/hestia/bin/v-add-database-user USERNAME DB_NAME DB_USER DB_PASSWORD
```

### Email Management

```bash
# Add mail domain
sudo /usr/local/hestia/bin/v-add-mail-domain USERNAME DOMAIN

# Add email account
sudo /usr/local/hestia/bin/v-add-mail-account USERNAME DOMAIN ACCOUNT PASSWORD

# Add email account with quota (MB)
sudo /usr/local/hestia/bin/v-add-mail-account USERNAME DOMAIN ACCOUNT PASSWORD 1024

# List email accounts
sudo /usr/local/hestia/bin/v-list-mail-accounts USERNAME DOMAIN

# Delete email account
sudo /usr/local/hestia/bin/v-delete-mail-account USERNAME DOMAIN ACCOUNT

# Change email password
sudo /usr/local/hestia/bin/v-change-mail-account-password USERNAME DOMAIN ACCOUNT NEW_PASSWORD

# Add email forwarder
sudo /usr/local/hestia/bin/v-add-mail-account-forward USERNAME DOMAIN ACCOUNT FORWARD_TO

# Delete email forwarder
sudo /usr/local/hestia/bin/v-delete-mail-account-forward USERNAME DOMAIN ACCOUNT FORWARD_TO
```

### DNS Management

```bash
# Add DNS domain
sudo /usr/local/hestia/bin/v-add-dns-domain USERNAME DOMAIN IP

# List DNS records
sudo /usr/local/hestia/bin/v-list-dns-records USERNAME DOMAIN

# Add DNS record
sudo /usr/local/hestia/bin/v-add-dns-record USERNAME DOMAIN RECORD TYPE VALUE

# Examples:
# Add A record
sudo /usr/local/hestia/bin/v-add-dns-record USERNAME DOMAIN @ A 217.216.40.207

# Add CNAME record
sudo /usr/local/hestia/bin/v-add-dns-record USERNAME DOMAIN www CNAME DOMAIN

# Add MX record
sudo /usr/local/hestia/bin/v-add-dns-record USERNAME DOMAIN @ MX "10 mail.DOMAIN"

# Add TXT record
sudo /usr/local/hestia/bin/v-add-dns-record USERNAME DOMAIN @ TXT "v=spf1 a mx ~all"

# Delete DNS record
sudo /usr/local/hestia/bin/v-delete-dns-record USERNAME DOMAIN RECORD_ID
```

### PHP Configuration

```bash
# Change PHP version for domain
sudo /usr/local/hestia/bin/v-change-web-domain-backend-tpl USERNAME DOMAIN PHP-8_1

# Available templates:
# PHP-7_4, PHP-8_0, PHP-8_1, PHP-8_2, PHP-8_3

# List available PHP templates
sudo /usr/local/hestia/bin/v-list-web-templates-backend
```

### Backup Management

```bash
# Create backup for user
sudo /usr/local/hestia/bin/v-backup-user USERNAME

# List backups for user
sudo /usr/local/hestia/bin/v-list-user-backups USERNAME

# Restore user from backup
sudo /usr/local/hestia/bin/v-restore-user USERNAME BACKUP_FILE

# Schedule backup
sudo /usr/local/hestia/bin/v-schedule-user-backup USERNAME
```

---

## WordPress Installation (WP-CLI)

```bash
# Navigate to document root
cd /home/USERNAME/web/DOMAIN/public_html

# Download WordPress
sudo -u USERNAME wp core download

# Create wp-config.php
sudo -u USERNAME wp config create \
  --dbname=DB_NAME \
  --dbuser=DB_USER \
  --dbpass=DB_PASSWORD \
  --dbhost=localhost

# Install WordPress
sudo -u USERNAME wp core install \
  --url=https://DOMAIN \
  --title="Site Title" \
  --admin_user=admin \
  --admin_password=ADMIN_PASSWORD \
  --admin_email=ADMIN_EMAIL

# Install common plugins
sudo -u USERNAME wp plugin install redis-cache --activate
sudo -u USERNAME wp plugin install wordfence --activate
sudo -u USERNAME wp plugin install wp-super-cache --activate

# Enable Redis cache
sudo -u USERNAME wp redis enable
```

---

## Migration from cPanel

```bash
# Dry run (test without making changes)
./scripts/migrate-cpanel-account.sh \
  --backup /tmp/cpmove-USERNAME.tar.gz \
  --hestia-user NEWUSERNAME \
  --domain DOMAIN \
  --dry-run

# Execute migration
./scripts/migrate-cpanel-account.sh \
  --backup /tmp/cpmove-USERNAME.tar.gz \
  --hestia-user NEWUSERNAME \
  --domain DOMAIN \
  --apply \
  --yes

# Fetch from remote cPanel server
./scripts/migrate-cpanel-account.sh \
  --remote root@old-cpanel.com:/home/cpmove-USERNAME.tar.gz \
  --hestia-user NEWUSERNAME \
  --domain DOMAIN \
  --apply \
  --yes
```

---

## Verification Commands

```bash
# Check if domain is accessible
curl -I https://DOMAIN

# Test DNS resolution
dig DOMAIN
nslookup DOMAIN

# Test email (SMTP)
telnet mail.DOMAIN 587

# Check SSL certificate
openssl s_client -connect DOMAIN:443 -servername DOMAIN

# Check PHP version
sudo -u USERNAME php -v

# Check disk usage for user
sudo du -sh /home/USERNAME

# Check web server logs
sudo tail -f /var/log/nginx/domains/DOMAIN.log
sudo tail -f /var/log/nginx/domains/DOMAIN.error.log

# Check email logs
sudo tail -f /var/log/exim4/mainlog
sudo tail -f /var/log/dovecot.log

# Check HestiaCP logs
sudo tail -f /var/log/hestia/system.log
```

---

## Troubleshooting

```bash
# Restart web server
sudo systemctl restart nginx

# Restart PHP-FPM
sudo systemctl restart php8.1-fpm

# Restart email services
sudo systemctl restart exim4
sudo systemctl restart dovecot

# Rebuild user configuration
sudo /usr/local/hestia/bin/v-rebuild-user USERNAME

# Rebuild web domain
sudo /usr/local/hestia/bin/v-rebuild-web-domain USERNAME DOMAIN

# Rebuild mail domain
sudo /usr/local/hestia/bin/v-rebuild-mail-domain USERNAME DOMAIN

# Rebuild DNS zone
sudo /usr/local/hestia/bin/v-rebuild-dns-domain USERNAME DOMAIN

# Check HestiaCP service status
sudo /usr/local/hestia/bin/v-list-sys-services

# Restart HestiaCP
sudo systemctl restart hestia
```

---

## Useful File Paths

```bash
# Web files
/home/USERNAME/web/DOMAIN/public_html/

# Web logs
/var/log/nginx/domains/DOMAIN.log
/var/log/nginx/domains/DOMAIN.error.log

# Email storage
/home/USERNAME/mail/DOMAIN/

# Email logs
/var/log/exim4/mainlog
/var/log/dovecot.log

# HestiaCP configuration
/usr/local/hestia/data/users/USERNAME/

# Nginx configuration
/etc/nginx/conf.d/domains/DOMAIN.conf

# PHP-FPM pool
/etc/php/8.1/fpm/pool.d/USERNAME.conf

# DNS zone files
/etc/bind/zones/DOMAIN.db

# Backups
/var/backup/USERNAME/
```

---

## Password Generation

```bash
# Generate strong password (20 characters)
tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 20

# Generate alphanumeric password (16 characters)
tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16

# Generate password with specific length
tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 24
```

---

## Common Workflows

### New WordPress Site (Complete)

```bash
# 1. Create user
sudo /usr/local/hestia/bin/v-add-user client1 'SecurePass123!' client@example.com

# 2. Add domain
sudo /usr/local/hestia/bin/v-add-domain client1 example.com

# 3. Enable SSL
sudo /usr/local/hestia/bin/v-add-letsencrypt-domain client1 example.com

# 4. Create database
sudo /usr/local/hestia/bin/v-add-database client1 wp_example wp_user 'DbPass123!'

# 5. Install WordPress
cd /home/client1/web/example.com/public_html
sudo -u client1 wp core download
sudo -u client1 wp config create --dbname=wp_example --dbuser=wp_user --dbpass='DbPass123!'
sudo -u client1 wp core install --url=https://example.com --title="Example Site" \
  --admin_user=admin --admin_password='AdminPass123!' --admin_email=admin@example.com

# 6. Configure email
sudo /usr/local/hestia/bin/v-add-mail-domain client1 example.com
sudo /usr/local/hestia/bin/v-add-mail-account client1 example.com info 'MailPass123!'
```

### Add Addon Domain to Existing User

```bash
# 1. Add domain
sudo /usr/local/hestia/bin/v-add-domain client1 addon.com

# 2. Enable SSL
sudo /usr/local/hestia/bin/v-add-letsencrypt-domain client1 addon.com

# 3. Create database (if needed)
sudo /usr/local/hestia/bin/v-add-database client1 wp_addon wp_addon_user 'DbPass123!'

# 4. Install WordPress (if needed)
cd /home/client1/web/addon.com/public_html
sudo -u client1 wp core download
# ... continue with wp config and install
```

---

## Documentation

- **Full Guide:** `docs/client-onboarding-workflow.md`
- **Migration Checklist:** `docs/sprint-artifacts/migration-checklist.md`
- **Architecture:** `docs/architecture.md`
- **HestiaCP Docs:** https://docs.hestiacp.com/

---

**Last Updated:** 2025-12-25  
**Version:** 1.0
