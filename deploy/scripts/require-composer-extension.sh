#!/bin/bash

# Read the extensions.csv file into an array
packages=""
while IFS=, read -r type source path version; do
    # Check if the extension is a composer package
    if [ "$source" == "composer" ]; then
        packages="$packages $path:$version"
    fi
done < extensions.csv

# Install the composer packages
if [ ! -z "$packages" ]; then
    echo "Installing $packages"
    composer require $packages --no-update
fi

