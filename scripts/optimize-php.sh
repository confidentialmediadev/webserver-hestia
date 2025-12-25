#!/bin/bash
# Script: optimize-php.sh
# Purpose: Configure PHP OPcache settings as per Story 4.1
# Usage: ./optimize-php.sh

set -euo pipefail

PHP_VERSIONS=("8.1" "8.2" "8.3" "8.4")

for VERSION in "${PHP_VERSIONS[@]}"; do
    INI_FILE="/etc/php/$VERSION/fpm/php.ini"
    if [ -f "$INI_FILE" ]; then
        echo "Optimizing PHP $VERSION OPcache..."
        sudo sed -i "s/^;*opcache.memory_consumption=.*/opcache.memory_consumption=128/" "$INI_FILE"
        sudo sed -i "s/^;*opcache.interned_strings_buffer=.*/opcache.interned_strings_buffer=8/" "$INI_FILE"
        sudo sed -i "s/^;*opcache.max_accelerated_files=.*/opcache.max_accelerated_files=10000/" "$INI_FILE"
        sudo sed -i "s/^;*opcache.revalidate_freq=.*/opcache.revalidate_freq=60/" "$INI_FILE"
        
        # Ensure opcache is enabled
        sudo sed -i "s/^;*opcache.enable=.*/opcache.enable=1/" "$INI_FILE"
        
        echo "Restarting PHP $VERSION FPM..."
        sudo systemctl restart "php$VERSION-fpm"
    fi
done

echo "PHP Optimization complete."
