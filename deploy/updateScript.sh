#!/bin/sh
composer require mediawiki/semantic-media-wiki:* --ignore-platform-req=php
composer update --no-dev

echo "done" 
# Install Composer dependencies
#composer install

# Update Composer dependencies
#composer update

cp /opt/LocalSettingsExtra.d/* LocalSettings.d/

# Keeping the container running
tail -f /dev/null
