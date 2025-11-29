# Webserver Hestia - Initial Requirements

**Date:** 2025-11-28
**Project Type:** Greenfield
**Track:** Enterprise BMad Method

## Project Overview

Migration from cPanel reseller account (GreenGeeks) to self-hosted VPS solution using HestiaCP control panel on Contabo infrastructure.

## Business Context

- **Current Setup:** cPanel reseller account with GreenGeeks
- **Target Setup:** Self-hosted server on Contabo VPS
- **Primary Use Case:** WordPress hosting (multiple sites)
- **Infrastructure:** 4 CPU / 8GB RAM server

## Key Requirements

### Control Panel Selection
- **Selected:** HestiaCP (open-source)
- **Rationale:**
  - Most cPanel-like experience
  - Built-in DNS management (BIND9)
  - Full email server stack
  - Good cPanel migration tools
  - Lightweight resource footprint

### Core Capabilities Required

1. **DNS Management**
   - Built-in DNS server (BIND9)
   - Self-hosted DNS capability
   - Independence from third-party DNS providers

2. **Email Server**
   - Full email stack (Exim4 + Dovecot)
   - Spam filtering (SpamAssassin)
   - Antivirus (ClamAV)
   - Complete email independence

3. **Web Server Stack**
   - **Web Server:** Nginx (not LiteSpeed due to licensing costs)
   - **PHP:** PHP-FPM 8.1+
   - **Database:** MariaDB 10.6+
   - **Caching:** Redis for object caching
   - **Additional:** OPcache for PHP bytecode caching

### Performance Optimization

**WordPress-Optimized Stack:**
- Nginx + PHP-FPM (FastCGI)
- Redis object caching (replaces database queries)
- Nginx FastCGI Cache or Redis Page Cache
- OPcache for PHP bytecode
- MariaDB with query caching tuned

**Target:** Handle dozens of WordPress sites on 4CPU/8GB infrastructure

### Multi-Language Runtime Support

1. **PHP** - Primary (WordPress)
2. **Node.js** - Via reverse proxy + PM2
3. **Python** - Native support via WSGI
4. **Ruby** - Via rbenv/rvm (if needed)

### Cloudflare Integration

**Requirement:** Integration with Cloudflare for CDN/proxy
**Approach:**
- Manual Cloudflare setup per domain (HestiaCP doesn't have native API integration)
- Cloudflare as proxy/CDN in front of HestiaCP
- SSL via Cloudflare Origin certificates or Let's Encrypt
- Accept manual DNS record management in Cloudflare dashboard

**Note:** CloudPanel has native Cloudflare API integration but lacks email server - not suitable for this use case.

### Backup Strategy

**Requirements:**
- cPanel JetBackup-like functionality
- Incremental backups
- Off-site storage
- Point-in-time restoration
- Encryption

**Proposed Solution:**
1. **Local:** HestiaCP built-in daily backups (7-day retention)
2. **Remote:** restic + rclone to Backblaze B2
   - Incremental, encrypted backups
   - 30-day retention
   - Cost: ~$0.005/GB/month
3. **WordPress-specific:** UpdraftPlus plugin for WordPress sites

**3-2-1 Backup Rule Implementation:**
- 1 primary (production)
- 2 backup copies (local + remote)
- 1 off-site (Backblaze B2)

### Migration Requirements

- Import from cPanel backups
- Support for existing WordPress sites
- Minimal downtime during migration
- DNS cutover strategy
- Email migration without loss

## Technical Constraints

- **Budget-conscious:** Open-source/free software preferred
- **No LiteSpeed commercial licensing:** Performance via Nginx optimization instead
- **Contabo VPS:** 4 CPU / 8GB RAM target infrastructure
- **Self-hosted preference:** Full control over DNS, email, web hosting

## Success Criteria

1. Successfully migrate from cPanel to HestiaCP
2. Maintain or improve WordPress performance vs current setup
3. Full DNS and email independence
4. Reliable backup/restore capability
5. Support for multiple programming languages/runtimes
6. Cloudflare integration working
7. Cost savings vs cPanel reseller account

## Open Questions for PRD

1. How many WordPress sites need to be migrated?
2. Current email volume and mailbox requirements?
3. Downtime tolerance for migration?
4. DNS propagation strategy during cutover?
5. Specific WordPress plugins/themes that need validation?
6. SSL certificate strategy (Let's Encrypt vs Cloudflare Origin)?
7. Monitoring and alerting requirements?
8. Backup retention policies (regulatory/compliance needs)?
9. Multi-tenant requirements (reseller hosting for clients)?
10. Geographic considerations (server location, CDN strategy)?

## Next Steps

Proceed to PRD workflow with PM agent to formalize:
- Detailed functional requirements
- Non-functional requirements (performance, security, reliability)
- Migration strategy and timeline
- Risk assessment
- Success metrics
