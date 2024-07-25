#!/bin/bash

su nobody

composer require mediawiki/semantic-media-wiki

# Install Composer dependencies
#composer install

# Update Composer dependencies
#composer update

# Keeping the container running
tail -f /dev/null
