# Project Context: Webserver Hestia

## Critical Rules

- **SSH Connections**: All agent connections to the production server `217.216.40.207` MUST use the SSH key located at `~/.ssh/web-cmdev`. This ensures passwordless access and consistency across agent sessions.
- **User**: Use the `cmdev` user for administrative tasks on the remote server unless otherwise specified.

## Infrastructure Patterns

- **Primary Server**: `217.216.40.207` (host1.confidentialhost.com)
- **Control Panel**: HestiaCP
- **OS**: Ubuntu 24.04 LTS
