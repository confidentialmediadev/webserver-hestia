# Webserver Hestia - Simplified Product Requirements Document

**Author:** Cfeaiagent (based on input from cfebrian)
**Date:** 2025-12-24
**Version:** 3.0 (ConfidentialHost Pivot)

---

## Executive Summary

**ConfidentialHost** is a simplified, self-managed hosting platform built on HestiaCP and Contabo VPS infrastructure. The goal is to replace a cPanel reseller account with a cost-effective, isolated environment for hosting WordPress sites. The focus is on standardization using HestiaCP's built-in features and minimal shell scripting for hardening.

**Primary Goal:** Establish a stable, secure, and performant hosting environment on `confidentialhost.com` starting with a single-server setup and expanding to DNS redundancy later.

---

## Project Scope

### In Scope
- **Infrastructure**:
    - **Server A (Primary)**: Contabo VPS (IP: 217.216.40.207), HestiaCP (Web, DNS, Mail, DB).
- **Domain**: `confidentialhost.com` as the hosting provider domain.
- **DNS**: Initial setup with `ns1.confidentialhost.com` and `ns2.confidentialhost.com` pointing to the same server (initially).
- **Web Stack**: Apache + NGINX + PHP-FPM (Multi-PHP) + Redis + ModSecurity.
- **Email**: Exim4 + Dovecot + SnappyMail + ManageSieve.
- **Security**: SSH hardening (Key-based), Fail2Ban, ClamAV, AppArmor.
- **Backups**: Local Hestia backups + Rclone to Backblaze B2.
- **Standardization**: Shell scripts for initial server setup and hardening.

### Out of Scope
- Multi-server DNS clustering (Phase 2).
- Complex provisioning automation (Ansible/Terraform).
- Custom control panels.

---

## Functional Requirements

### FR1: Server Infrastructure
- **FR1.1**: Provision Primary Server (IP: 217.216.40.207) with full HestiaCP stack.
- **FR1.2**: Configure hostname (`host1.confidentialhost.com`) and timezone.

### FR2: DNS Configuration
- **FR2.1**: Configure Glue records for `ns1` and `ns2` at the registrar.
- **FR2.2**: Setup DNS zones for `confidentialhost.com` in Hestia.

### FR3: Hosting Environment
- **FR3.1**: Configure `confidentialhost.com` in Hestia with SSL (Let's Encrypt).
- **FR3.2**: Enable Redis object caching and configure PHP OPcache.
- **FR3.3**: Enable ModSecurity and ClamAV for security scanning.

### FR4: Email Services
- **FR4.1**: Configure mail server (Exim/Dovecot) on Primary.
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

## Implementation Plan

The implementation follows a phased approach:

1.  **Server Provisioning & Hardening**:
    - Set hostname and timezone.
    - Run `ssh-hardening.sh`.
2.  **HestiaCP Installation**:
    - Install full Hestia stack on Primary server.
3.  **Domain & DNS Setup**:
    - Configure Glue records at registrar.
    - Setup `confidentialhost.com` and subdomains in Hestia.
    - Enable SSL.
4.  **Optimization & Security**:
    - Configure Redis, OPcache, and ModSecurity.
    - Setup ClamAV scans.
5.  **Backups**:
    - Setup local and off-site backups.
6.  **Client Onboarding**:
    - Define workflow for adding new sites.

---
