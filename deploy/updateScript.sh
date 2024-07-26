#!/bin/sh
chown -R root:root .

# check if path semanti media wiki is already in ectensions
if [ ! -d "extensions/SemanticMediaWiki" ]; then
    composer require mediawiki/semantic-media-wiki:* --ignore-platform-req=php
fi

# run mediawiki update script 
php maintenance/update.php --quick
#composer update --no-dev

#echo "done" 
# Install Composer dependencies
#composer install

# Update Composer dependencies
#composer update

cp /opt/mw/LocalSettingsExtra.d/* LocalSettings.d/

# Keeping the container running
tail -f /dev/null
