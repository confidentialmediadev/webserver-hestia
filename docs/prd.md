# Webserver Hestia - Simplified Product Requirements Document

**Author:** Cfeaiagent (based on input from cfebrian)
**Date:** 2025-12-18
**Version:** 2.0 (Simplified)

---

## Executive Summary

**CFE Web Host 26** is a simplified, self-managed hosting platform built on HestiaCP and Contabo VPS infrastructure. The goal is to replace a cPanel reseller account with a cost-effective, isolated environment for hosting WordPress sites. The focus is on standardization using HestiaCP's built-in features and minimal shell scripting for hardening, rather than complex custom automation.

**Primary Goal:** Establish a stable, secure, and performant hosting environment on `cfehost.net` with DNS redundancy and off-site backups.

---

## Project Scope

### In Scope
- **Infrastructure**:
    - **Server A (Master)**: Contabo VPS (US), HestiaCP (Web, DNS Master, Mail, DB).
    - **Server B (Slave)**: Contabo VPS (EU), HestiaCP (DNS Slave only).
- **Domain**: `cfehost.net` as the hosting provider domain.
- **DNS**: Master/Slave cluster (Hestia API).
- **Web Stack**: Apache + NGINX + PHP-FPM (Multi-PHP) + Redis + ModSecurity.
- **Email**: Exim4 + Dovecot + SnappyMail + ManageSieve.
- **Security**: SSH hardening (Key-based), Fail2Ban, ClamAV, AppArmor.
- **Backups**: Local Hestia backups + Rclone to Backblaze B2.
- **Standardization**: Shell scripts for initial server setup and hardening.

### Out of Scope
- Complex provisioning automation (Ansible/Terraform) for "lots of servers".
- Custom control panels (relying on HestiaCP UI).
- Multi-runtime support (Node.js/Python) for MVP (focus is WordPress).

---

## Functional Requirements

### FR1: Server Infrastructure
- **FR1.1**: Provision Server A (Master) with full HestiaCP stack.
- **FR1.2**: Provision Server B (Slave) with minimal HestiaCP stack (DNS only).
- **FR1.3**: Configure hostnames (`host1.cfehost.net`, `ns2.cfehost.net`) and timezone.

### FR2: DNS Configuration
- **FR2.1**: Configure Glue records for `ns1` and `ns2`.
- **FR2.2**: Setup Master-Slave DNS clustering via Hestia API.
- **FR2.3**: Ensure zone transfers work automatically from Master to Slave.

### FR3: Hosting Environment
- **FR3.1**: Configure `cfehost.net` in Hestia with SSL (Let's Encrypt).
- **FR3.2**: Enable Redis object caching and configure PHP OPcache.
- **FR3.3**: Enable ModSecurity and ClamAV for security scanning.

### FR4: Email Services
- **FR4.1**: Configure mail server (Exim/Dovecot) on Master.
- **FR4.2**: Install/Configure SnappyMail for webmail access.
- **FR4.3**: Enable ManageSieve for email filtering.

### FR5: Security & Hardening
- **FR5.1**: Implement SSH hardening (disable password auth, root login, use keys).
- **FR5.2**: Configure Firewall (iptables via Hestia) and Fail2Ban.
- **FR5.3**: Schedule daily ClamAV scans.

### FR6: Backups
- **FR6.1**: Configure daily local backups in Hestia.
- **FR6.2**: Configure Rclone for off-site sync to Backblaze B2.
- **FR6.3**: Schedule backup sync via cron.

---

## Implementation Plan (Based on `new-plan-summary.md`)

The implementation follows a 14-step plan:

1.  **Servers & Roles Definition** (Done)
2.  **Registrar Setup** (Moved to Step 9)
3.  **Provisioning** (Done)
4.  **SSH Hardening** (Done)
5.  **Firewall Configuration** (Done)
6.  **Master Server Install** (Done)
7.  **Slave DNS Server Install** (Done)
8.  **DNS Cluster Configuration** (To Do)
9.  **Configure cfehost.net** (To Do)
10. **Mail Configuration** (To Do)
11. **Performance Optimization** (To Do)
12. **Security Enhancements** (To Do)
13. **Backups Setup** (To Do)
14. **Client Workflow Definition** (To Do)

---
