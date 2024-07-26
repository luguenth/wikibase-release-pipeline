#!/bin/sh

echo "test"
su nobody
echo "wfLoadExtension('SemanticMediaWiki');" >> LocalSettings.php
composer require mediawiki/semantic-media-wiki

echo "done" 
# Install Composer dependencies
#composer install

# Update Composer dependencies
#composer update

# Keeping the container running
tail -f /dev/null
