#!/bin/bash

if [[ "$1" != "--ubuntu" ]]; then
    csvt changelog.csv changelog.html changelog.template.html
    exit
fi

version_pattern='m4_define\(\[purple_version_suffix\], \[.(.*)\]\)'
version=$(grep -E "$version_pattern" ../source/configure.ac | sed -r s/"$version_pattern"/'\1'/)
maintainer=$(bzr whoami || echo "NAME <EMAIL>")
date=$(date '+%a, %d %b %Y %H:%M:%S %z')

csvt changelog.csv changelog.ubuntu.txt changelog.template.debian.txt
eval echo "\"$(cat changelog.ubuntu.txt)\"" > changelog.ubuntu.txt
