# Story 3.1: Registrar Setup

Status: done

## Story

As a System Administrator,
I want to configure Glue records for ns1 and ns2 at the domain registrar,
so that the domain confidentialhost.com can use its own nameservers.

## Acceptance Criteria

1. Glue records for `ns1.confidentialhost.com` pointing to `217.216.40.207` are configured.
2. Glue records for `ns2.confidentialhost.com` pointing to `217.216.40.207` are configured.
3. Nameservers for `confidentialhost.com` are set to `ns1.confidentialhost.com` and `ns2.confidentialhost.com`.

## Tasks / Subtasks

- [x] Verify Glue records propagation (AC: 1, 2)
  - [x] Run `dig +short ns1.confidentialhost.com`
  - [x] Run `dig +short ns2.confidentialhost.com`
- [x] Verify Nameserver configuration (AC: 3)
  - [x] Run `dig +short NS confidentialhost.com`

## Dev Notes

- This story primarily involves external configuration at the registrar.
- Verification can be done from the local machine or the server.
- The server IP is `217.216.40.207`.

### References

- [Source: docs/epics.md#Epic 3: Domain & DNS Configuration]

## Dev Agent Record

### Agent Model Used

Antigravity (Gemini 2.0 Flash)

### Completion Notes List

### File List
