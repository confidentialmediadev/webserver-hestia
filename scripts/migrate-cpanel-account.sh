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
  --hestia-user USER         Hestia username to create (default: from tarball)
  --domain DOMAIN            Primary domain to restore (required)
  --password PASSWORD        Password for the Hestia user (auto-generated if omitted)
  --dry-run                  Do not perform changes; print actions only
  --yes                      Skip interactive confirmations
  -h, --help                 Show this help

Examples:
  $PROGNAME --backup /tmp/cpmove-alice.tar.gz --hestia-user alice --domain example.com
  $PROGNAME --remote root@oldhost:/home/cpmove-alice.tar.gz --domain example.com

Notes:
 - The script requires `sudo` privileges to run Hestia CLI commands and copy files into /home.
 - If you cannot produce a cPanel full backup, follow the migration checklist in docs/sprint-artifacts/migration-checklist.md
  to perform a manual rsync + mysqldump migration.
USAGE
}

# Parse args
BACKUP=""
REMOTE=""
HESTIA_USER=""
DOMAIN=""
PASSWORD=""
DRY_RUN=1
ASSUME_YES=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --backup) BACKUP="$2"; shift 2 ;;
    --remote) REMOTE="$2"; shift 2 ;;
    --hestia-user) HESTIA_USER="$2"; shift 2 ;;
    --domain) DOMAIN="$2"; shift 2 ;;
    --password) PASSWORD="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --yes) ASSUME_YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

if [ -z "$BACKUP" ] && [ -z "$REMOTE" ]; then
  echo "Error: either --backup or --remote must be provided." >&2
  usage
  exit 2
fi

if [ -z "$DOMAIN" ]; then
  echo "Error: --domain is required (primary domain for the Hestia account)." >&2
  usage
  exit 2
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo "Running in DRY-RUN mode (no changes will be made). Use --yes to skip prompts and omit --dry-run to apply)."
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

if [ ! -f "$BACKUP" ]; then
  echo "Backup file not found: $BACKUP" >&2
  echo "If you cannot produce a cPanel full backup, see docs/sprint-artifacts/migration-checklist.md for manual steps." >&2
  exit 4
fi

echo "Using backup: $BACKUP"

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
  # generate a random password
  PASSWORD=$(tr -dc 'A-Za-z0-9!@#$%_- ' < /dev/urandom | head -c 24)
fi

echo "Planned actions summary"
echo "  Hestia user: $HESTIA_USER"
echo "  Domain: $DOMAIN"
echo "  Backup: $BACKUP"
echo "  Work dir: $WORKDIR"
echo "  Dry run: $DRY_RUN"

if ! confirm "Proceed with the above plan?"; then
  echo "Aborted by user."; exit 0
fi

# Extract the backup
echo "Extracting backup into $WORKDIR"
if [ "$DRY_RUN" -eq 1 ]; then
  echo "DRY-RUN: would extract: tar -xzf $BACKUP -C $WORKDIR"
else
  mkdir -p "$WORKDIR/extracted"
  tar -xzf "$BACKUP" -C "$WORKDIR/extracted" || { echo "Failed to extract backup"; exit 5; }
fi

# Create Hestia user
create_hestia_user() {
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
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN: would add domain: v-add-domain $HESTIA_USER $DOMAIN"
    return 0
  fi
  sudo /usr/local/hestia/bin/v-add-domain "$HESTIA_USER" "$DOMAIN" || { echo "Failed to add domain"; exit 7; }
}

# Restore website files
restore_web_files() {
  SRC="$WORKDIR/extracted/public_html"
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
  SQLDIR="$WORKDIR/extracted/mysql"
  if [ ! -d "$SQLDIR" ]; then
    echo "No mysql dumps found in backup; skipping DB restore.";
    return 0
  fi
  for sql in "$SQLDIR"/*.sql; do
    [ -e "$sql" ] || continue
    DBNAME=$(basename "$sql" .sql)
    # Create a DB and user in Hestia; generate a password
    DBUSER="db_${DBNAME}"
    DBPASS=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "DRY-RUN: would create DB $DBNAME and user $DBUSER, import $sql"
      continue
    fi
    sudo /usr/local/hestia/bin/v-add-database "$HESTIA_USER" "$DBNAME" "$DBUSER" "$DBPASS" || { echo "Failed to create DB $DBNAME"; continue; }
    sudo mysql -u root "$DBNAME" < "$sql" || { echo "Import failed for $sql"; }
    echo "Created DB $DBNAME with user $DBUSER (password hidden)"
    # Optionally update application config files (wp-config.php) — left manual
  done
}

# Restore mailboxes
restore_mail() {
  MAILSRC="$WORKDIR/extracted/mail"
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

# Run steps
create_hestia_user
add_domain
restore_web_files
restore_databases
restore_mail

echo "Migration actions completed (dry-run=$DRY_RUN)."
echo "Workdir: $WORKDIR"
echo "If you ran without --dry-run, verify the site and mail, then update DNS records to point to the new server."

cat <<EOF
Manual follow-ups (recommended):
- Update application config files (wp-config.php) with new DB credentials created above.
- Verify PHP version and modules for the site in Hestia.
- Test IMAP/SMTP access for restored mailboxes.
- Once validated, reduce DNS TTL beforehand and switch A/MX records.
EOF

exit 0
