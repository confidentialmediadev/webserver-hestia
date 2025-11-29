# Ansible Backlog — Hestia / Cert Automation

Status: Deferred (scope = future automation sprint)

This file captures Ansible tasks and roles to implement once we resume provisioning automation.

- [ ] Role: `00-server-init`
  - Install base packages, users, SSH hardening, unattended-upgrades, fail2ban
  - Configure UFW (or document decision to rely on Hestia iptables)

- [ ] Role: `01-hestiacp-install`
  - Non-interactive HestiaCP installer wrapper (idempotent)
  - Preflight checks: ensure clean server (no bind9, ufw conflicts)

- [ ] Role: `hestia-deploy-hook`
  - Deploy `/etc/letsencrypt/renewal-hooks/deploy/hestia-deploy.sh`
  - Ensure perms and backup directory

- [ ] Role: `provision-site`
  - Create Hestia user, website, database, PHP-FPM pool
  - Configure DNS / certbot invocation

- [ ] Role: `migrate-mail`
  - Export/import mailboxes from old server (rsync/maildir)
  - Update Exim/Dovecot user mappings and quotas

- [ ] Role: `backup-and-restore`
  - Backup site files, DBs, mail for safe rollback

- [ ] CI / Linting
  - `ansible-lint`, `yamllint` in CI for playbooks

Notes:
- Keep secrets out of repo: use Ansible Vault for credentials, private keys, and `.env` files.
- Prioritize testing of playbooks in a disposable VM before running on production.
