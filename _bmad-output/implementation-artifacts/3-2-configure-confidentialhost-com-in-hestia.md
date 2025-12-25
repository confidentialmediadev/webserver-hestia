# Story 3.2: Configure confidentialhost.com in Hestia

Status: done

## Story

As a System Administrator,
I want to add confidentialhost.com to HestiaCP and configure its DNS and SSL,
so that the primary domain is fully functional and secured.

## Acceptance Criteria

1. Domain `confidentialhost.com` is added to the `cfeadmin` user in HestiaCP.
2. DNS records are configured in HestiaCP:
   - A record for `ns1` -> `217.216.40.207`
   - A record for `ns2` -> `217.216.40.207`
   - A record for `panel` -> `217.216.40.207`
   - A record for `mail` -> `217.216.40.207`
   - A record for `webmail` -> `217.216.40.207`
3. Let's Encrypt SSL is enabled for the domain and its mail services.

## Tasks / Subtasks

- [x] Add domain to HestiaCP (AC: 1)
  - [x] Run `v-add-web-domain cfeadmin confidentialhost.com`
  - [x] Run `v-add-dns-domain cfeadmin confidentialhost.com 217.216.40.207`
  - [x] Run `v-add-mail-domain cfeadmin confidentialhost.com`
- [x] Configure DNS records (AC: 2)
  - [x] Add A records for ns1, ns2, panel, mail, webmail
- [x] Enable Let's Encrypt (AC: 3)
  - [x] Run `v-add-letsencrypt-domain cfeadmin confidentialhost.com`
  - [x] Run `v-add-letsencrypt-mail-domain cfeadmin confidentialhost.com`

## Dev Notes

- Use HestiaCP CLI tools (`v-*` commands).
- Connection to server requires `web-cmdev` key.
- Ensure DNS propagation is sufficient for Let's Encrypt validation (or use DNS-01 if supported/needed, but HTTP-01 is default).

### References

- [Source: docs/epics.md#Epic 3: Domain & DNS Configuration]

## Dev Agent Record

### Agent Model Used

Antigravity (Gemini 2.0 Flash)

### Completion Notes List

### File List
