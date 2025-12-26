#!/bin/bash
# Quick Client Onboarding Script
# Usage: ./quick-onboard.sh
#
# This interactive script guides you through onboarding a new client
# to the ConfidentialHost HestiaCP platform.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run with sudo privileges"
    exit 1
fi

# Banner
echo "================================================"
echo "  ConfidentialHost - Client Onboarding Script  "
echo "================================================"
echo ""

# Gather information
log_info "Please provide the following information:"
echo ""

read -p "Client username (lowercase, alphanumeric): " USERNAME
read -p "Primary domain (e.g., example.com): " DOMAIN
read -p "Client email address: " EMAIL
read -s -p "User password (leave empty to auto-generate): " PASSWORD
echo ""

# Generate password if not provided
if [ -z "$PASSWORD" ]; then
    PASSWORD=$(tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 20)
    log_info "Auto-generated password: $PASSWORD"
fi

# Confirm details
echo ""
log_info "Review the information:"
echo "  Username: $USERNAME"
echo "  Domain: $DOMAIN"
echo "  Email: $EMAIL"
echo "  Password: [hidden]"
echo ""

read -p "Proceed with onboarding? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    log_warn "Onboarding cancelled by user"
    exit 0
fi

echo ""
log_info "Starting onboarding process..."
echo ""

# Step 1: Create HestiaCP user
log_info "Step 1/6: Creating HestiaCP user..."
if /usr/local/hestia/bin/v-list-users | grep -q "^$USERNAME "; then
    log_warn "User $USERNAME already exists, skipping creation"
else
    /usr/local/hestia/bin/v-add-user "$USERNAME" "$PASSWORD" "$EMAIL"
    log_success "User $USERNAME created"
fi

# Step 2: Add domain
log_info "Step 2/6: Adding domain $DOMAIN..."
if /usr/local/hestia/bin/v-list-web-domains "$USERNAME" 2>/dev/null | grep -q -w "$DOMAIN"; then
    log_warn "Domain $DOMAIN already exists for user $USERNAME"
else
    /usr/local/hestia/bin/v-add-domain "$USERNAME" "$DOMAIN"
    log_success "Domain $DOMAIN added"
fi

# Step 3: Enable SSL
log_info "Step 3/6: Enabling SSL (Let's Encrypt)..."
sleep 5  # Wait for DNS propagation (may need longer in production)
if /usr/local/hestia/bin/v-add-letsencrypt-domain "$USERNAME" "$DOMAIN" 2>/dev/null; then
    log_success "SSL certificate issued for $DOMAIN"
else
    log_warn "SSL certificate issuance failed - may need manual retry after DNS propagation"
fi

# Step 4: Create database
log_info "Step 4/6: Creating WordPress database..."
DB_NAME="wp_${USERNAME}"
DB_USER="wp_${USERNAME}"
DB_PASS=$(tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 20)

if /usr/local/hestia/bin/v-list-databases "$USERNAME" 2>/dev/null | grep -q "^$DB_NAME "; then
    log_warn "Database $DB_NAME already exists"
else
    /usr/local/hestia/bin/v-add-database "$USERNAME" "$DB_NAME" "$DB_USER" "$DB_PASS"
    log_success "Database created: $DB_NAME"
fi

# Step 5: Add mail domain
log_info "Step 5/6: Configuring email for $DOMAIN..."
if /usr/local/hestia/bin/v-list-mail-domains "$USERNAME" 2>/dev/null | grep -q -w "$DOMAIN"; then
    log_warn "Mail domain $DOMAIN already exists"
else
    /usr/local/hestia/bin/v-add-mail-domain "$USERNAME" "$DOMAIN"
    log_success "Mail domain $DOMAIN configured"
fi

# Step 6: Create default email account
log_info "Step 6/6: Creating default email account (info@$DOMAIN)..."
MAIL_PASS=$(tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 20)
if /usr/local/hestia/bin/v-list-mail-accounts "$USERNAME" "$DOMAIN" 2>/dev/null | grep -q "^info "; then
    log_warn "Email account info@$DOMAIN already exists"
else
    /usr/local/hestia/bin/v-add-mail-account "$USERNAME" "$DOMAIN" "info" "$MAIL_PASS"
    log_success "Email account created: info@$DOMAIN"
fi

# Summary
echo ""
echo "================================================"
log_success "Onboarding completed successfully!"
echo "================================================"
echo ""
echo "Client Credentials:"
echo "-------------------"
echo "HestiaCP Panel:"
echo "  URL: https://panel.confidentialhost.com:8083"
echo "  Username: $USERNAME"
echo "  Password: $PASSWORD"
echo ""
echo "Domain: https://$DOMAIN"
echo ""
echo "Database:"
echo "  Name: $DB_NAME"
echo "  User: $DB_USER"
echo "  Password: $DB_PASS"
echo "  Host: localhost"
echo ""
echo "Email Account:"
echo "  Address: info@$DOMAIN"
echo "  Password: $MAIL_PASS"
echo "  Webmail: https://webmail.confidentialhost.com"
echo "  IMAP: mail.$DOMAIN:993 (SSL)"
echo "  SMTP: mail.$DOMAIN:587 (STARTTLS)"
echo ""
echo "Next Steps:"
echo "-----------"
echo "1. Install WordPress (manually or via WP-CLI)"
echo "2. Configure DNS records at registrar:"
echo "   - Nameservers: ns1.confidentialhost.com, ns2.confidentialhost.com"
echo "   - OR add A records pointing to: 217.216.40.207"
echo "3. Verify SSL certificate after DNS propagation"
echo "4. Test email send/receive"
echo "5. Provide credentials to client securely"
echo ""
echo "Documentation: docs/client-onboarding-workflow.md"
echo "================================================"

# Save credentials to file
CREDS_FILE="/root/onboarding-${USERNAME}-$(date +%Y%m%d-%H%M%S).txt"
cat > "$CREDS_FILE" <<EOF
ConfidentialHost - Client Onboarding Summary
Generated: $(date)

Client: $USERNAME
Domain: $DOMAIN
Email: $EMAIL

HestiaCP Access:
  URL: https://panel.confidentialhost.com:8083
  Username: $USERNAME
  Password: $PASSWORD

Database:
  Name: $DB_NAME
  User: $DB_USER
  Password: $DB_PASS
  Host: localhost

Email Account:
  Address: info@$DOMAIN
  Password: $MAIL_PASS
  Webmail: https://webmail.confidentialhost.com
  IMAP: mail.$DOMAIN:993 (SSL)
  SMTP: mail.$DOMAIN:587 (STARTTLS)

DNS Configuration:
  Option 1 - Use ConfidentialHost Nameservers:
    ns1.confidentialhost.com
    ns2.confidentialhost.com
  
  Option 2 - Use External DNS (Cloudflare, etc.):
    A Record: @ -> 217.216.40.207
    A Record: www -> 217.216.40.207
    A Record: mail -> 217.216.40.207
    MX Record: @ -> mail.$DOMAIN (Priority: 10)
    TXT Record: (See HestiaCP for SPF/DKIM records)

Next Steps:
  1. Install WordPress
  2. Configure DNS
  3. Verify SSL
  4. Test email
  5. Deliver credentials to client

Documentation: docs/client-onboarding-workflow.md
EOF

log_success "Credentials saved to: $CREDS_FILE"
log_warn "IMPORTANT: Securely delete this file after delivering credentials to client!"

exit 0
