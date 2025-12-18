---
stepsCompleted: []
inputDocuments: []
workflowType: 'product-brief'
lastStep: 0
project_name: 'webserver-hestia'
user_name: 'Cfeaiagent'
date: '2025-12-17'
---
# Product Brief: webserver-hestia

**Date:** 2025-12-17
**Author:** Cfeaiagent

---


## Product Vision
Build a simplified, fully isolated hosting environment to replace a cPanel reseller account using HestiaCP on Contabo VPS infrastructure.

## Key Features
- **Infrastructure**: Two Contabo VPS instances (US Central + EU)
- **Control Panel**: HestiaCP with multi-user isolation
- **DNS**: Master/Slave DNS cluster (ns1/ns2.cfehost.net)
- **Web Stack**: Apache + NGINX + PHP-FPM + Redis + ModSecurity
- **Email**: Exim4 + Dovecot + SnappyMail + ManageSieve
- **Security**: SSH hardening, Fail2Ban, ClamAV, AppArmor
- **Backups**: Local + Off-site (Rclone to Backblaze B2)

## Success Criteria
- Fully functional hosting environment on `cfehost.net`
- DNS redundancy with Master/Slave setup
- Secure SSH access with key-based auth only
- Optimized performance for WordPress (Redis + OPcache)
- Automated backups to off-site storage

## Implementation Strategy
- **Manual/Scripted Setup**: Use shell scripts for standardization (e.g., SSH hardening) but rely on HestiaCP for most management.
- **No Complex Automation**: Avoid over-engineering; focus on stability and standard Hestia features.

