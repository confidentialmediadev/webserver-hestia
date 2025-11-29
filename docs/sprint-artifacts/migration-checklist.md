# Migration & Operational Checklist — Finish Migration, Decommission Old Servers

Goal: Finish making the new Hestia server fully operational, move accounts (sites, mail), verify service parity, then decommission old servers.

Preconditions
- DNS A record for `h26.cfesystems.com` already points to the new server (195.26.248.226).
- HestiaCP installed and admin login confirmed.
- Let's Encrypt cert issued and deploy hook installed.

Immediate (high priority)
- [ ] Verify backups exist for all sites and mailboxes on the old servers.
- [ ] Confirm webroot and database backups for each site (tar + mysqldump) and store off-server.
- [ ] Confirm maildir backups and exported user lists.
- [ ] Verify MX and SPF/DMARC/DMARC TXT records for each domain; prepare DNS change plan and TTL reductions.
- [ ] Test restore of one small site to the new server (dry-run): files + DB + URL mapping.
- [ ] Test email delivery for one test mailbox (send/receive via external account).

Migration steps (per domain / account)
- [ ] Reduce DNS TTL for domain(s) to 300s (24–48h before cutover).
- [ ] Create Hestia user/site on new server and configure domain settings.
- [ ] Copy website files to new server (rsync) and import database.
- [ ] Update config (wp-config.php) with new DB credentials, correct file permissions, test locally using hosts override.
- [ ] Request/verify SSL certificate (certbot already set up globally) and ensure Hestia serves the correct cert.
- [ ] Migrate mailboxes: rsync maildirs, create mail users in Hestia, set quotas, verify mail access via IMAP/SMTP.
- [ ] Switch DNS A/MX records and monitor propagation; for low-risk cutover, adjust specific records first.

Post-migration verification
- [ ] Monitor web site errors, logs, and performance for 24–72 hours.
- [ ] Verify mail queues, SPAM filtering and bounce rates.
- [ ] Confirm backups are running on the new server and backup retention is in place.

Decommission old servers
- [ ] When satisfied with stability and backups, power down old servers and keep backups for 30 days before destruction.
- [ ] Revoke any SSH keys no longer needed and update inventory/documentation.

Notes and safeguards
- Keep the old environment running (read-only) until at least one successful renewal cycle and 7 days of stable operation.
- Communicate planned cutover windows to stakeholders; prefer low-traffic hours.
