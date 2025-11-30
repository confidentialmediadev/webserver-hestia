#!/usr/bin/env bash
set -euo pipefail

# migrate-cpanel-account.sh
#
# Template script to migrate a cPanel full-account backup (cpmove-USER.tar.gz)
# into a HestiaCP-managed account. Designed to be safe, interactive, and
# work when the cPanel backup tarball is available locally or on a remote host
# accessible via scp.
#
# Limitations:
# - This script assumes you have a cPanel full backup (cpmove-<user>.tar.gz).
# - Creating that backup on a cPanel/WHM host typically requires root (pkgacct)
#   or the account owner creating a full backup via cPanel's backup UI.
# - If you don't have the tarball, use the instructions printed by this script
#   to generate one and re-run.
#
# Usage examples:
# 1) Local tarball already on Hestia server:
#    ./scripts/migrate-cpanel-account.sh --backup /tmp/cpmove-alice.tar.gz --hestia-user alice --domain example.com
#
# 2) Fetch tarball from remote cPanel host using scp (provide remote user/host):
#    ./scripts/migrate-cpanel-account.sh --remote root@old-cpanel.example.com:/home/cpmove-alice.tar.gz --hestia-user alice --domain example.com
#
# 3) Dry-run (no changes):
#    ./scripts/migrate-cpanel-account.sh --backup /tmp/cpmove-alice.tar.gz --hestia-user alice --domain example.com --dry-run

PROGNAME=$(basename "$0")

usage() {
  cat <<USAGE
Usage: $PROGNAME [options]

Options:
  --backup PATH              Local path to cPanel full backup tarball (cpmove-<user>.tar.gz)
  --remote user@host:/path   Remote tarball to fetch via scp
  --extracted-dir DIR        Local path to already-extracted cPanel backup directory
  --hestia-user USER         Hestia username to create (default: from tarball)
  --domain DOMAIN            Primary domain to restore (required)
  --password PASSWORD        Password for the Hestia user (auto-generated if omitted)
  --dry-run                  Do not perform changes; print actions only
  --yes                      Skip interactive confirmations
  -h, --help                 Show this help

Examples:
  $PROGNAME --backup /tmp/cpmove-alice.tar.gz --hestia-user alice --domain example.com
  $PROGNAME --remote root@oldhost:/home/cpmove-alice.tar.gz --domain example.com
  $PROGNAME --extracted-dir /path/to/extracted/backup --hestia-user alice --domain example.com

Notes:
 - The script requires `sudo` privileges to run Hestia CLI commands and copy files into /home.
 - If you cannot produce a cPanel full backup, follow the migration checklist in docs/sprint-artifacts/migration-checklist.md
  to perform a manual rsync + mysqldump migration.
USAGE
}

# Parse args
BACKUP=""
REMOTE=""
EXTRACTED_DIR=""
HESTIA_USER=""
DOMAIN=""
PASSWORD=""
DRY_RUN=1
ASSUME_YES=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --backup) BACKUP="$2"; shift 2 ;;
    --remote) REMOTE="$2"; shift 2 ;;
    --extracted-dir) EXTRACTED_DIR="$2"; shift 2 ;;
    --hestia-user) HESTIA_USER="$2"; shift 2 ;;
    --domain) DOMAIN="$2"; shift 2 ;;
    --password) PASSWORD="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --apply) DRY_RUN=0; shift ;;
    --yes) ASSUME_YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

if [ -z "$BACKUP" ] && [ -z "$REMOTE" ] && [ -z "$EXTRACTED_DIR" ]; then
  echo "Error: either --backup, --remote, or --extracted-dir must be provided." >&2
  usage
  exit 2
fi

if [ -z "$DOMAIN" ]; then
  echo "Error: --domain is required (primary domain for the Hestia account)." >&2
  usage
  exit 2
fi

if [ -n "$EXTRACTED_DIR" ] && [ ! -d "$EXTRACTED_DIR" ]; then
  echo "Error: --extracted-dir $EXTRACTED_DIR is not a directory." >&2
  exit 2
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo "Running in DRY-RUN mode (no changes will be made). Use --apply --yes to run for real."
else
  echo "Running in APPLY mode (will make changes). Use --yes to skip prompts."
fi

confirm() {
  if [ "$ASSUME_YES" -eq 1 ]; then
    return 0
  fi
  read -r -p "$1 [y/N]: " ans
  case "$ans" in
    [Yy]*) return 0 ;;
    *) return 1 ;;
  esac
}

log() { echo "[migrate] $*"; }

WORKDIR="/tmp/migrate-$(date +%s)"
mkdir -p "$WORKDIR"

if [ -n "$REMOTE" ]; then
  echo "Fetching remote backup: $REMOTE"
  # allow scp with user@host:/path
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN: would run: scp $REMOTE $WORKDIR/"
  else
    scp -o StrictHostKeyChecking=no "$REMOTE" "$WORKDIR/" || { echo "scp failed"; exit 3; }
  fi
  # set BACKUP to local path
  LOCAL_TAR=$(basename "$REMOTE")
  BACKUP="$WORKDIR/$LOCAL_TAR"
fi

if [ -n "$BACKUP" ] && [ ! -f "$BACKUP" ]; then
  echo "Backup file not found: $BACKUP" >&2
  echo "If you cannot produce a cPanel full backup, see docs/sprint-artifacts/migration-checklist.md for manual steps." >&2
  exit 4
fi

if [ -n "$BACKUP" ]; then
  echo "Using backup: $BACKUP"
elif [ -n "$EXTRACTED_DIR" ]; then
  echo "Using extracted backup: $EXTRACTED_DIR"
fi

# Inspect tarball to infer username (cpmove-USERNAME.tar.gz)
TARBASENAME=$(basename "$BACKUP")
if [[ "$TARBASENAME" =~ ^cpmove-(.+)\.tar\.gz$ ]] || [[ "$TARBASENAME" =~ ^cpmove-(.+)\.tar$ ]]; then
  CPUSER=${BASH_REMATCH[1]}
  log "Inferred cPanel username: $CPUSER"
else
  CPUSER=""
fi

if [ -z "$HESTIA_USER" ]; then
  if [ -n "$CPUSER" ]; then
    HESTIA_USER="$CPUSER"
  else
    echo "Choose a Hestia username to create (lowercase, alphanumeric):"
    read -r HESTIA_USER
  fi
fi

if [ -z "$PASSWORD" ]; then
  # generate a random password (place hyphen at end to avoid tr range errors)
  PASSWORD=$(tr -dc 'A-Za-z0-9!@#$%_-' < /dev/urandom | head -c 24 || true)
fi

echo "Planned actions summary"
echo "  Hestia user: $HESTIA_USER"
echo "  Domain: $DOMAIN"
if [ -n "$BACKUP" ]; then
  echo "  Backup: $BACKUP"
elif [ -n "$EXTRACTED_DIR" ]; then
  echo "  Extracted dir: $EXTRACTED_DIR"
fi
echo "  Work dir: $WORKDIR"
echo "  Dry run: $DRY_RUN"

if ! confirm "Proceed with the above plan?"; then
  echo "Aborted by user."; exit 0
fi

# Extract the backup
if [ -n "$EXTRACTED_DIR" ]; then
  echo "Using pre-extracted backup at $EXTRACTED_DIR"
  EXTRACTED_PATH="$EXTRACTED_DIR"
else
  echo "Extracting backup into $WORKDIR"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN: would extract: tar -xzf $BACKUP -C $WORKDIR"
    EXTRACTED_PATH="$WORKDIR/extracted"
  else
    mkdir -p "$WORKDIR/extracted"
    tar -xzf "$BACKUP" -C "$WORKDIR/extracted" || { echo "Failed to extract backup"; exit 5; }
    EXTRACTED_PATH="$WORKDIR/extracted"
  fi
fi

# Create Hestia user
create_hestia_user() {
  if sudo /usr/local/hestia/bin/v-list-users | grep -q "^$HESTIA_USER "; then
    echo "Hestia user $HESTIA_USER already exists, skipping creation."
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN: would create Hestia user: v-add-user $HESTIA_USER <password> <email>"
    return 0
  fi
  # Use a sane email placeholder
  EMAIL="$HESTIA_USER@${DOMAIN}"
  sudo /usr/local/hestia/bin/v-add-user "$HESTIA_USER" "$PASSWORD" "$EMAIL" || { echo "Failed to create Hestia user"; exit 6; }
}

# Add domain to Hestia user
add_domain() {
  if sudo /usr/local/hestia/bin/v-list-web-domains "$HESTIA_USER" | grep -q -w "$DOMAIN"; then
    echo "Domain $DOMAIN already exists for user $HESTIA_USER, skipping addition."
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN: would add domain: v-add-domain $HESTIA_USER $DOMAIN"
    return 0
  fi
  sudo /usr/local/hestia/bin/v-add-domain "$HESTIA_USER" "$DOMAIN" || { echo "Failed to add domain"; exit 7; }
}

# Restore website files
restore_web_files() {
  SRC="$EXTRACTED_PATH/public_html"
  if [ ! -d "$SRC" ]; then
    SRC="$EXTRACTED_PATH/homedir/public_html"
  fi
  DEST="/home/$HESTIA_USER/web/$DOMAIN/public_html"
  if [ ! -d "$SRC" ]; then
    echo "Warning: public_html not found in backup; skipping web files.";
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN: would rsync -a $SRC/ $DEST/ && chown -R $HESTIA_USER:$HESTIA_USER $DEST"
    return 0
  fi
  sudo mkdir -p "$DEST"
  sudo rsync -a "$SRC/" "$DEST/"
  sudo chown -R "$HESTIA_USER:$HESTIA_USER" "$DEST"
}

# Restore databases
restore_databases() {
  SQLDIR="$EXTRACTED_PATH/mysql"
  if [ ! -d "$SQLDIR" ]; then
    echo "No mysql dumps found in backup; skipping DB restore.";
    return 0
  fi
  for sql in "$SQLDIR"/*.sql; do
    [ -e "$sql" ] || continue
    DBNAME=$(basename "$sql" .sql)
    # Check if DB exists
    if sudo /usr/local/hestia/bin/v-list-databases "$HESTIA_USER" | grep -q "^$DBNAME "; then
      echo "DB $DBNAME already exists for user $HESTIA_USER, skipping creation."
      continue
    fi
    # Create a DB and user in Hestia; generate a password
    DBUSER="db_${DBNAME}"
    DBPASS=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16 || true)
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "DRY-RUN: would create DB $DBNAME and user $DBUSER, import $sql"
      continue
    fi
    sudo /usr/local/hestia/bin/v-add-database "$HESTIA_USER" "$DBNAME" "$DBUSER" "$DBPASS" || { echo "Failed to create DB $DBNAME"; continue; }
    sudo mysql -u root "$DBNAME" < "$sql" || { echo "Import failed for $sql"; continue; }
    echo "Created DB $DBNAME with user $DBUSER (password hidden)"
    # Store for wp-config update
    LAST_DB_NAME="$DBNAME"
    LAST_DB_USER="$DBUSER"
    LAST_DB_PASS="$DBPASS"
    # Optionally update application config files (wp-config.php) — left manual
  done
}

# Restore mailboxes
restore_mail() {
  MAILSRC="$EXTRACTED_PATH/mail"
  if [ ! -d "$MAILSRC" ]; then
    MAILSRC="$EXTRACTED_PATH/homedir/mail"
  fi
  if [ ! -d "$MAILSRC" ]; then
    echo "No mail directory in backup; skipping mail restore.";
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN: would rsync maildirs from $MAILSRC into /home/$HESTIA_USER/mail/"
    return 0
  fi
  sudo rsync -a "$MAILSRC/" "/home/$HESTIA_USER/mail/"
  sudo chown -R "$HESTIA_USER:mail" "/home/$HESTIA_USER/mail/"
}

# Restore email forwarders
restore_forwarders() {
  VALIASES="$EXTRACTED_PATH/etc/valiases/$DOMAIN"
  if [ ! -f "$VALIASES" ]; then
    VALIASES="$EXTRACTED_PATH/va/$DOMAIN"
  fi
  if [ ! -f "$VALIASES" ]; then
    echo "No valiases file found; skipping forwarder restore.";
    return 0
  fi
  echo "Parsing forwarders from $VALIASES"
  while IFS=: read -r localpart dests; do
    [ -z "$localpart" ] && continue
    # dests can be comma-separated
    IFS=',' read -ra DEST_ARRAY <<< "$dests"
    for dest in "${DEST_ARRAY[@]}"; do
      dest=$(echo "$dest" | xargs)  # trim whitespace
      if [[ "$dest" != *@$DOMAIN && "$dest" != "|"* ]]; then
        echo "Forwarder found: $localpart@$DOMAIN -> $dest"
        if [ "$DRY_RUN" -eq 1 ]; then
          echo "DRY-RUN: would add forwarder for $localpart@$DOMAIN to $dest (manual in Hestia UI)"
        else
          echo "Manual: Add forwarder in Hestia web UI for $localpart@$DOMAIN to $dest"
        fi
      fi
    done
  done < "$VALIASES"
}

# Update WordPress config with new DB credentials
update_wp_config() {
  WP_CONFIG="/home/$HESTIA_USER/web/$DOMAIN/public_html/wp-config.php"
  if [ ! -f "$WP_CONFIG" ]; then
    echo "No wp-config.php found; skipping config update.";
    return 0
  fi
  if [ -z "$LAST_DB_NAME" ]; then
    echo "No DB created; skipping wp-config update.";
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN: would update wp-config.php with DB_NAME=$LAST_DB_NAME, DB_USER=$LAST_DB_USER, DB_PASSWORD=****"
    return 0
  fi
  sed -i "s/define('DB_NAME', '[^']*'/define('DB_NAME', '$LAST_DB_NAME'/" "$WP_CONFIG"
  sed -i "s/define('DB_USER', '[^']*'/define('DB_USER', '$LAST_DB_USER'/" "$WP_CONFIG"
  sed -i "s/define('DB_PASSWORD', '[^']*'/define('DB_PASSWORD', '$LAST_DB_PASS'/" "$WP_CONFIG"
  sed -i "s/define('DB_HOST', '[^']*'/define('DB_HOST', 'localhost'/" "$WP_CONFIG"
  echo "Updated wp-config.php with new DB credentials."
}

# Update WordPress database URLs
update_wp_db() {
  if [ -z "$LAST_DB_NAME" ]; then
    echo "No DB created; skipping DB URL update.";
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN: would update WordPress URLs in DB $LAST_DB_NAME to https://$DOMAIN"
    return 0
  fi
  # Update siteurl and home
  sudo mysql -u root "$LAST_DB_NAME" -e "UPDATE wp_options SET option_value = 'https://$DOMAIN' WHERE option_name IN ('siteurl', 'home');" || echo "Failed to update siteurl/home"
  # Update any serialized paths if possible (basic replace)
  sudo mysql -u root "$LAST_DB_NAME" -e "UPDATE wp_options SET option_value = REPLACE(option_value, 'http://$DOMAIN', 'https://$DOMAIN');" || echo "Failed to update http to https"
  sudo mysql -u root "$LAST_DB_NAME" -e "UPDATE wp_posts SET post_content = REPLACE(post_content, 'http://$DOMAIN', 'https://$DOMAIN');" || echo "Failed to update post content"
  echo "Updated WordPress URLs in DB to https://$DOMAIN."
}

# Parse and restore addon domains and subdomains
parse_and_restore_domains() {
  USERDATA_DIR="$EXTRACTED_PATH/userdata"
  if [ ! -d "$USERDATA_DIR" ]; then
    echo "No userdata dir found; skipping addon/subdomain restore.";
    return 0
  fi
  # Assume main domain is already added
  # Parse main userdata for addon_domains
  MAIN_USERDATA="$USERDATA_DIR/$DOMAIN"
  if [ -f "$MAIN_USERDATA" ]; then
    # Parse YAML-like for addon_domains
    ADDON_DOMAINS=$(grep -A 10 "addon_domains:" "$MAIN_USERDATA" | grep -E "^  - " | sed 's/  - //' || true)
    for addon in $ADDON_DOMAINS; do
      echo "Found addon domain: $addon"
      if sudo /usr/local/hestia/bin/v-list-web-domains "$HESTIA_USER" | grep -q -w "$addon"; then
        echo "Addon domain $addon already exists, skipping."
        continue
      fi
      if [ "$DRY_RUN" -eq 1 ]; then
        echo "DRY-RUN: would add domain $addon and restore files from homedir/public_html/$addon"
      else
        sudo /usr/local/hestia/bin/v-add-domain "$HESTIA_USER" "$addon" || { echo "Failed to add addon domain $addon"; continue; }
        # Restore files
        SRC="$EXTRACTED_PATH/homedir/public_html/$addon"
        DEST="/home/$HESTIA_USER/web/$addon/public_html"
        if [ -d "$SRC" ]; then
          sudo mkdir -p "$DEST"
          sudo rsync -a "$SRC/" "$DEST/"
          sudo chown -R "$HESTIA_USER:$HESTIA_USER" "$DEST"
          echo "Restored addon domain $addon files."
        fi
      fi
    done
  fi
  # For subdomains, check if there's a subdomains file or parse userdata
  # Assuming subdomains are listed in main userdata under sub_domains or similar
  SUB_DOMAINS=$(grep -A 10 "sub_domains:" "$MAIN_USERDATA" | grep -E "^  - " | sed 's/  - //')
  for sub in $SUB_DOMAINS; do
    echo "Found subdomain: $sub"
    if sudo /usr/local/hestia/bin/v-list-web-domains "$HESTIA_USER" | grep -q -w "$sub"; then
      echo "Subdomain $sub already exists, skipping."
      continue
    fi
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "DRY-RUN: would add domain $sub and restore files from homedir/public_html/$sub"
    else
      sudo /usr/local/hestia/bin/v-add-domain "$HESTIA_USER" "$sub" || { echo "Failed to add subdomain $sub"; continue; }
      SRC="$EXTRACTED_PATH/homedir/public_html/$sub"
      DEST="/home/$HESTIA_USER/web/$sub/public_html"
      if [ -d "$SRC" ]; then
        sudo mkdir -p "$DEST"
        sudo rsync -a "$SRC/" "$DEST/"
        sudo chown -R "$HESTIA_USER:$HESTIA_USER" "$DEST"
        echo "Restored subdomain $sub files."
      fi
    fi
  done
}

# Run steps
create_hestia_user
add_domain
parse_and_restore_domains
restore_web_files
restore_databases
update_wp_config
update_wp_db
restore_mail
restore_forwarders

echo "Migration actions completed (dry-run=$DRY_RUN)."
echo "Workdir: $WORKDIR"
echo "If you ran without --dry-run, verify the site and mail, then update DNS records to point to the new server."

cat <<EOF
Manual follow-ups (recommended):
- Verify PHP version and modules for the site in Hestia (automated config update done).
- Test IMAP/SMTP access for restored mailboxes.
- Add any forwarders identified above in the Hestia web UI (Mail > Accounts > Edit > Forward to).
- Once validated, reduce DNS TTL beforehand and switch A/MX records.
EOF

exit 0
