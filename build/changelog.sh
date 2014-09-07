#!/bin/bash

##
##     Pidgin++ Changelog Manager
##     Copyright (c) 2014 Renato Silva
##     GNU GPLv2 licensed
##
## This utility converts the XML-based changelog into presentable formats,
## either HTML or Debian changelog. It also manages the Pidgin++ version.
##
## Usage:
##     @script.name OPTIONS
##
##    -u, --update-version         Bump version suffix to RS{day-of-year}.
##    -d, --debian                 Generate the Debian package changelog entry.
##    -m, --markdown               Generate the Markdown changelog.
##    -H, --html                   Generate the HTML changelog.
##        --output=FILE            Save generated changelog to FILE.
##
##    -v, --version                Print the Pidgin++ version.
##    -V, --upstream-version       Print the Pidgin version.
##    -p, --package-version        Print the package version in Debian systems.
##    -P, --package-version-full   Print the package version in Debian systems,
##                                 including the epoch component.
##

eval "$(from="$0" easyoptions.rb "$@" || echo exit 1)"
base_dir=$(readlink -e "$(dirname "$0")/..")
source_dir="$base_dir/source"
build_dir="$base_dir/build"

version_pattern="PACKAGE_VERSION=[\"']?([^\"']+)[\"']?"
suffix_pattern='m4_define\(\[purple_version_suffix\], \[.(.*)\]\)'
pidgin_version=$(grep -E "$version_pattern" "$source_dir/configure" | sed -r s/"$version_pattern"/'\1'/)
custom_version=$(grep -E "$suffix_pattern" "$source_dir/configure.ac" | sed -r s/"$suffix_pattern"/'\1'/)

# Bump version suffix
if [[ -n "$update_version" ]]; then
    new_custom_version="RS$(date +%j)"
    if [[ $new_custom_version != $custom_version ]]; then
        sed -ri "s/$suffix_pattern/m4_define([purple_version_suffix], [-$new_custom_version])/" "$source_dir/configure.ac"
        echo "Version bumped to $new_custom_version"
        custom_version="$new_custom_version"
    fi
fi

full_version="${pidgin_version}-${custom_version}"
xsl_parameters="-s version=$full_version -s bugs.url=https://developer.pidgin.im/ticket"
[[ $(uname -s) = Linux ]] && ubuntu_package_version=$(apt-cache show pidgin | grep -m 1 Version | awk -F': ' '{ print $2 }' | sed -E "s/-(${custom_version,,}\+){0,1}/-${custom_version,,}+/")
[[ -n "$output" ]] && output=$(readlink -f "$output")

# Versions
[[ -n "$version"              ]] &&  printf "${full_version:+$full_version\n}"
[[ -n "$upstream_version"     ]] &&  printf "${pidgin_version:+$pidgin_version\n}"
[[ -n "$package_version"      ]] &&  printf "${ubuntu_package_version:+${ubuntu_package_version#*:}\n}"
[[ -n "$package_version_full" ]] &&  printf "${ubuntu_package_version:+${ubuntu_package_version}\n}"

# HTML changelog
if [[ -n "$html" ]]; then
    cd "$build_dir"
    output="${output:-$base_dir/changelog.html}"
    unformatted="/tmp/changelog.unformatted.html"
    xmlstarlet transform --omit-decl changelog.html.xsl $xsl_parameters changelog.xml | dos2unix > "$unformatted"
    xmlstarlet format --html --omit-decl --nocdata --indent-spaces 4 "$unformatted" | dos2unix > "$output"
    rm "$unformatted"
    sed -i -E "s/(<\!\[CDATA\[|(\s{4})?\]\]>)//" "$output"
    echo "Changelog exported to $output"
fi

# Markdown changelog
if [[ -n "$markdown" ]]; then
    cd "$build_dir"
    output="${output:-$base_dir/changelog.md}"
    xsl_parameters="$xsl_parameters -s screenshots.url=http://pidgin.renatosilva.me"
    xmlstarlet transform --omit-decl changelog.markdown.xsl $xsl_parameters changelog.xml | dos2unix > "$output"
    echo "Changelog exported to $output"
fi

# Debian changelog
if [[ -n "$debian" ]]; then
    cd "$build_dir"
    output="${output:-$base_dir/changelog.debian.txt}"
    distribution=$(lsb_release --codename --short 2> /dev/null || echo DISTRIBUTION)
    maintainer=$(bzr whoami 2> /dev/null || echo "${DEBFULLNAME:-NAME} <${DEBEMAIL:-EMAIL}>")
    xsl_parameters="$xsl_parameters -s package.version=${ubuntu_package_version:-VERSION} -s distribution=$distribution"
    xmlstarlet transform --omit-decl changelog.debian.xsl $xsl_parameters -s maintainer="$maintainer" -s date="$(date -R)" changelog.xml | dos2unix > "$output"
    echo "Changelog exported to $output"
fi
