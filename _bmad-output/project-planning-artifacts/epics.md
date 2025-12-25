# Webserver Hestia - Epics & Stories

**Based on ConfidentialHost PRD (Version 3.0)**

---

## Epic 1: Server Provisioning & Hardening
*Initial setup and security hardening of the primary server.*

- **Story 1.1**: Set Hostname & Timezone
    - **Goal**: Set hostname to `host1.confidentialhost.com` and timezone to `America/Chicago`.
- **Story 1.2**: SSH Hardening
    - **Goal**: Run `ssh-hardening.sh` to secure SSH access and add `cfeaiagent` user.
- **Story 1.3**: Firewall Configuration
    - **Goal**: Ensure Hestia's firewall is ready (UFW disabled).

---

## Epic 2: HestiaCP Installation
*Install the full HestiaCP stack on the primary server.*

- **Story 2.1**: Install HestiaCP
    - **Goal**: Run the HestiaCP installation script with the full stack (Apache, NGINX, PHP-FPM, Multi-PHP, Bind, Exim, Dovecot, ClamAV, SpamAssassin, MariaDB).
- **Story 2.2**: Post-Install Verification
    - **Goal**: Verify panel access and service status.

---

## Epic 3: Domain & DNS Configuration
*Establish the primary hosting domain and DNS records.*

- **Story 3.1**: Registrar Setup
    - **Goal**: Configure Glue records for `ns1` and `ns2` pointing to `217.216.40.207`.
- **Story 3.2**: Configure confidentialhost.com in Hestia
    - **Goal**: Add the domain to the admin user, setup DNS records (A records for ns1, ns2, panel, mail, webmail), and enable Let's Encrypt.

---

## Epic 4: Optimization & Security
*Tune the server for performance and implement additional security.*

- **Story 4.1**: Performance Optimization
    - **Goal**: Install Redis, configure PHP OPcache, and enable ModSecurity.
- **Story 4.2**: Security Enhancements
    - **Goal**: Verify Fail2Ban jails and setup daily ClamAV scans.

---

## Epic 5: Backups & Onboarding
*Ensure data safety and define the client workflow.*

- **Story 5.1**: Backup Configuration
    - **Goal**: Setup local Hestia backups and Rclone sync to Backblaze B2.
- **Story 5.2**: Client Onboarding Process
    - **Goal**: Document the workflow for adding new clients/sites.

---
