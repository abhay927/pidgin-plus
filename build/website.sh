#!/bin/bash

##
##     Pidgin++ Website Builder
##     Copyright (c) 2014 Renato Silva
##     Licensed under GNU GPLv2 or later
##
## Usage:
##     @script.name TARGET_DIRECTORY
##

# Parse Options
source easyoptions || exit
directory="${arguments[0]}"
if [[ -z "$directory" ]]; then
    echo "No target directory specified."
    exit 1
fi

# Directories
mkdir -p "$directory" || exit
base_dir=$(readlink -e "$(dirname "$0")/..")
build_dir="$base_dir/build"
source_dir="$base_dir/source"
website_dir="$base_dir/website"

# Build the website
tray_dir="$directory/pixmaps/pidgin/tray/hicolor"
status_dir="$directory/pixmaps/pidgin/status"
mkdir -p "$status_dir" "$tray_dir" || exit
cp "$website_dir/index.html" "$directory"
cp "$website_dir/update.xml" "$directory"
cp -r "$source_dir/pidgin/pixmaps/status/48" "$status_dir"
cp -r "$source_dir/pidgin/pixmaps/tray/hicolor/48x48" "$tray_dir"
cp -r "$website_dir/pixmaps/site" "$directory/pixmaps"
"$build_dir/changelog.sh" --html --output "$directory/changelog.html" > /dev/null
echo "Website exported to $directory"
