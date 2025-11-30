#!/usr/bin/env bash
set -euo pipefail

### enable-pam-lockout.sh
### Safe helper to add PAM-based account lockout for failed SSH logins on Ubuntu 24.04.
### It will back up PAM configs, detect available modules (pam_faillock or pam_tally2),
### prepare modified files and apply them only after an explicit confirmation.

BACKUP_DIR="/root/hestia-pam-backups-$(date +%Y%m%d%H%M%S)"
echo "Backup directory: ${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"

PAM_DIR="/etc/pam.d"
FILES_TO_BACKUP=("${PAM_DIR}/common-auth" "${PAM_DIR}/common-account" "${PAM_DIR}/sshd")
for f in "${FILES_TO_BACKUP[@]}"; do
  if [ -f "$f" ]; then
    cp -a "$f" "${BACKUP_DIR}/$(basename $f)" || true
  fi
done

echo "Detecting available PAM modules..."
## Include common multiarch library paths so the script finds pam modules on Ubuntu
FAILLOCK_PATH=$(grep -R pam_faillock.so /lib /lib.usr-is-merged /lib64 /lib/x86_64-linux-gnu /usr/lib /usr/lib64 /usr/lib/x86_64-linux-gnu /usr/libexec 2>/dev/null || true)
TALLY_PATH=$(grep -R pam_tally2.so /lib /lib.usr-is-merged /lib64 /lib/x86_64-linux-gnu /usr/lib /usr/lib64 /usr/lib/x86_64-linux-gnu /usr/libexec 2>/dev/null || true)

if [ -n "$FAILLOCK_PATH" ]; then
  MODULE="faillock"
  echo "Found pam_faillock at: ${FAILLOCK_PATH%%$'\n'*}"
elif [ -n "$TALLY_PATH" ]; then
  MODULE="tally2"
  echo "Found pam_tally2 at: ${TALLY_PATH%%$'\n'*}"
else
  echo "No pam_faillock or pam_tally2 module found on system. Please install one of them (Ubuntu: 'apt install libpam-modules' may provide them) and re-run." >&2
  exit 2
fi

DENY=5
UNLOCK_TIME=900   # seconds (15 minutes)

echo "Preparing patched PAM files (module=${MODULE}, deny=${DENY}, unlock_time=${UNLOCK_TIME})"

patch_common_auth() {
  src="${PAM_DIR}/common-auth"
  dst="${PAM_DIR}/common-auth.new"
  cp -a "$src" "$dst"

  if grep -q "pam_faillock.so" "$dst" || grep -q "pam_tally2.so" "$dst"; then
    echo "common-auth already contains faillock/tally rules — skipping modification"
    return 0
  fi

  if [ "$MODULE" = "faillock" ]; then
    cat >> "$dst" <<EOF
auth    required pam_faillock.so preauth silent deny=${DENY} unlock_time=${UNLOCK_TIME}
auth    [default=die] pam_faillock.so authfail deny=${DENY} unlock_time=${UNLOCK_TIME}
EOF
  else
    # pam_tally2 approach: require tally on auth and reset on success via pam_unix
    cat >> "$dst" <<'EOF'
auth    required pam_tally2.so onerr=fail deny=5 unlock_time=900
EOF
  fi

  echo "Wrote modified common-auth -> ${dst}"
}

patch_common_account() {
  src="${PAM_DIR}/common-account"
  dst="${PAM_DIR}/common-account.new"
  cp -a "$src" "$dst"

  if grep -q "pam_faillock.so" "$dst" || grep -q "pam_tally2.so" "$dst"; then
    echo "common-account already contains faillock/tally rules — skipping modification"
    return 0
  fi

  if [ "$MODULE" = "faillock" ]; then
    cat >> "$dst" <<EOF
account required pam_faillock.so
EOF
  else
    cat >> "$dst" <<'EOF'
account required pam_tally2.so
EOF
  fi

  echo "Wrote modified common-account -> ${dst}"
}

patch_sshd() {
  src="${PAM_DIR}/sshd"
  dst="${PAM_DIR}/sshd.new"
  cp -a "$src" "$dst"

  # For sshd, prefer to ensure pam_unix line still exists and do not duplicate rules.
  if grep -q "pam_faillock.so" "$dst" || grep -q "pam_tally2.so" "$dst"; then
    echo "sshd already contains faillock/tally rules — skipping modification"
    return 0
  fi

  if [ "$MODULE" = "faillock" ]; then
    # Insert pam_faillock preauth lines near the top (before pam_unix)
    awk -v deny="$DENY" -v ut="$UNLOCK_TIME" '
  BEGIN { inserted=0 }
  /pam_unix.so/ && !inserted { print "auth    required pam_faillock.so preauth silent deny="deny" unlock_time="ut; print "auth    [default=die] pam_faillock.so authfail deny="deny" unlock_time="ut; inserted=1 }
  { print }
  END { if(!inserted) print "auth    required pam_faillock.so preauth silent deny="deny" unlock_time="ut"; print "auth    [default=die] pam_faillock.so authfail deny="deny" unlock_time="ut" }
' "$dst" > "$dst.tmp" && mv "$dst.tmp" "$dst"
    # ensure account line exists
    if ! grep -q "pam_faillock.so" "$dst"; then
      echo "account required pam_faillock.so" >> "$dst"
    fi
  else
    # pam_tally2: add auth/account lines if pam_unix exists
    awk -v deny="$DENY" -v ut="$UNLOCK_TIME" '
  BEGIN { inserted=0 }
  /pam_unix.so/ && !inserted { print "auth    required pam_tally2.so onerr=fail deny="deny" unlock_time="ut"; inserted=1 }
  { print }
  END { if(!inserted) print "auth    required pam_tally2.so onerr=fail deny="deny" unlock_time="ut" }
' "$dst" > "$dst.tmp" && mv "$dst.tmp" "$dst"
    if ! grep -q "pam_tally2.so" "$dst"; then
      echo "account required pam_tally2.so" >> "$dst"
    fi
  fi

  echo "Wrote modified sshd -> ${dst}"
}

patch_common_auth
patch_common_account
patch_sshd

echo "Prepared .new versions in ${PAM_DIR}. Inspect them before applying."
echo
for f in common-auth.new common-account.new sshd.new; do
  echo "---- /etc/pam.d/$f ----"
  sed -n '1,200p' "${PAM_DIR}/$f" || true
  echo
done

read -rp "Apply these PAM changes now? Type 'yes' to proceed: " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Aborting without applying changes. Backups are in ${BACKUP_DIR}."
  exit 0
fi

# Apply the changes (move .new into place)
for f in common-auth common-account sshd; do
  if [ -f "${PAM_DIR}/${f}.new" ]; then
    mv "${PAM_DIR}/${f}.new" "${PAM_DIR}/${f}"
    echo "Applied ${PAM_DIR}/${f}"
  fi
done

echo "PAM files updated. Important: keep an existing root/admin SSH session open while you test new auth behavior."

echo "To reset counters for a user (faillock):"
echo "  pam_faillock --user <username> --reset  (if pam_faillock present)"
echo "Or for pam_tally2:"
echo "  pam_tally2 -u <username> -r"

echo "If anything goes wrong, restore backups from ${BACKUP_DIR}, for example:"
echo "  sudo cp ${BACKUP_DIR}/common-auth /etc/pam.d/common-auth && sudo cp ${BACKUP_DIR}/common-account /etc/pam.d/common-account && sudo cp ${BACKUP_DIR}/sshd /etc/pam.d/sshd"

echo "Done. Test by attempting SSH auth failures until ban triggers, then verify user is locked out per settings."

exit 0
