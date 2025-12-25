#!/bin/bash
# Script: verify-optimization.sh
# Purpose: Verify Story 4.1 implementation
# Usage: ./verify-optimization.sh

set -euo pipefail

echo "--- Redis Verification ---"
redis-cli ping
php -m | grep redis

echo "--- OPcache Verification ---"
php -i | grep opcache.memory_consumption
php -i | grep opcache.interned_strings_buffer
php -i | grep opcache.max_accelerated_files
php -i | grep opcache.revalidate_freq

echo "--- ModSecurity Verification ---"
sudo apache2ctl -M | grep security
sudo grep SecRuleEngine /etc/modsecurity/modsecurity.conf
