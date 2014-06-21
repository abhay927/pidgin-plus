#!/bin/bash

# Pidgin Changelog Generator
# Copyright (c) 2014 Renato Silva
# GNU GPLv2 licensed

suffix_pattern='m4_define\(\[purple_version_suffix\], \[.(.*)\]\)'

# Bump version suffix
if [[ "$1" = "--update-version" ]]; then
    script_dir=$(dirname "$0")
    source_dir=$(readlink -e "$script_dir/../source")
    sed -ri "s/$suffix_pattern/m4_define([purple_version_suffix], [-RS$(date +%j)])/" "$source_dir/configure.ac"
    exit
fi

# Prepare for changelog generation
if [[ "$1" = --html || "$1" = --debian || "$1" = --*version* ]]; then
    version_pattern="PACKAGE_VERSION=[\"']?([^\"']+)[\"']?"
    pidgin_version=$(grep -E "$version_pattern" ../source/configure | sed -r s/"$version_pattern"/'\1'/)
    custom_version=$(grep -E "$suffix_pattern" ../source/configure.ac | sed -r s/"$suffix_pattern"/'\1'/)
    [[ $(uname -s) = Linux ]] && package_version=$(apt-cache show pidgin | grep -m 1 Version | awk -F': ' '{ print $2 }' | sed s/-/-${custom_version,,}+/)
    xsl_parameters="-s version=$pidgin_version -s version.custom=$custom_version -s bugs.url=https://developer.pidgin.im/ticket"
fi

# Just print the version
case "$1" in
    --version)               echo "${pidgin_version}-${custom_version}"; exit ;;
    --package-version)       echo "${package_version#*:}"; exit ;;
    --package-version-full)  echo "$package_version"; exit ;;
    --upstream-version)      echo "$pidgin_version"; exit ;;
esac

# HTML changelog
if [[ "$1" = "--html" ]]; then
    xmlstarlet transform --omit-decl changelog.html.xsl $xsl_parameters changelog.xml | dos2unix > changelog.unformatted.html
    xmlstarlet format --html --omit-decl --nocdata --indent-spaces 4 changelog.unformatted.html | dos2unix > changelog.html
    sed -i -E "s/(<\!\[CDATA\[|(\s{4})?\]\]>)//" changelog.html
    rm changelog.unformatted.html
    exit
fi

# Debian changelog
if [[ "$1" = "--debian" ]]; then
    distribution=$(lsb_release --codename --short 2> /dev/null || echo DISTRIBUTION)
    maintainer=$(bzr whoami 2> /dev/null || echo "${DEBFULLNAME:-NAME} <${DEBEMAIL:-EMAIL}>")
    xsl_parameters="$xsl_parameters -s package.version=${package_version:-VERSION} -s distribution=$distribution"
    xmlstarlet transform --omit-decl changelog.debian.xsl $xsl_parameters -s maintainer="$maintainer" -s date="$(date -R)" changelog.xml | dos2unix > changelog.debian.txt
    exit
fi

echo "Usage: $(basename "$0") OPTION
    --html                   Generate the HTML changelog.
    --debian                 Generate the Debian package changelog entry.
    --update-version         Bump version suffix to RS{day-of-year}.

    --version                Print current version.
    --package-version        Print current Ubuntu package version.
    --package-version-full   Include the epoch component.
    --upstream-version       Print Pidgin version."
