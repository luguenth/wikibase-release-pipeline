#!/bin/bash

set -e

# Read the extensions.csv file into an array
while IFS=, read -r type source path version custom_name; do
    if [ "$source" == "git" ]; then
        dirname="$path"
        if [ "$type" == "extension" ]; then
            dirname=extensions
        elif [ "$type" == "skin" ]; then
            dirname=skins
        fi
        echo "Installing $path:$version"
        cd $dirname
        branch=""
        if [ "$version" != "" ]; then
            branch="-b $version"
            echo "Using branch: $branch"
        fi
        if [ "$custom_name" != "" ]; then
            echo "Using custom name: $custom_name"
            git clone "$path" $branch "$custom_name" --recurse-submodules || true
        else
            git clone "$path" $branch --recurse-submodules || true
        fi
        cd ..
    fi
done < extensions.csv
