#!/bin/bash

##
##     Pidgin++ Changelog Manager
##     Copyright (c) 2014, 2015 Renato Silva
##     Licensed under GNU GPLv2 or later
##
## This utility converts the XML-based changelog into presentable formats,
## either HTML or Debian changelog. It also manages the Pidgin++ version.
##
## Usage:
##     @script.name OPTIONS
##
##        --bump-major-version     Bump the major version in version suffix.
##    -B, --bump-minor-version     Bump the minor version in version suffix.
##    -b, --bump-micro-version     Bump the micro version in version suffix.
##
##    -d, --debian                 Generate the Debian package changelog entry.
##    -m, --markdown               Generate the Markdown changelog.
##    -H, --html                   Generate the HTML changelog.
##        --output=FILE            Save generated changelog to FILE.
##        --screenshot-prefix=URL  Prefix for the screenshot URLs.
##
##    -v, --version                Print the Pidgin++ version.
##    -V, --version-full           Print the Pidgin++ version, always including
##                                 the micro component.
##    -u, --upstream-version       Print the Pidgin version.
##

source easyoptions || exit
base_dir=$(readlink -e "$(dirname "$0")/..")
source_dir="$base_dir/source"
build_dir="$base_dir/build"

pidgin_version_pattern="PACKAGE_VERSION=[\"']?([^\"']+)[\"']?"
version_pattern='m4_define\(\[purple_version_suffix\], \[.(.*)\]\)'
pidgin_version=$(grep -E "$pidgin_version_pattern" "$source_dir/configure" | sed -r s/"$pidgin_version_pattern"/'\1'/)
suffix_delimiter="-"

full_version=$(grep -E "$version_pattern" "$source_dir/configure.ac" | sed -r s/"$version_pattern"/'\1'/)
full_version="${full_version#$suffix_delimiter}"
major_version="${full_version%%.*}"
minor_version="${full_version#*.}"
minor_version="${minor_version%%.*}"
micro_version="${full_version##*.}"
display_version="${full_version%.0}"

# Versions
[[ -n "$version"              ]] &&  printf "${display_version:+$display_version\n}"
[[ -n "$version_full"         ]] &&  printf "${full_version:+$full_version\n}"
[[ -n "$upstream_version"     ]] &&  printf "${pidgin_version:+$pidgin_version\n}"

# Bump version
if [[ -n "$bump_major_version" || -n "$bump_minor_version" || -n "$bump_micro_version" ]]; then
    [[ -n "$bump_major_version" ]] && major_version=$(($major_version + 1))
    [[ -n "$bump_minor_version" ]] && minor_version=$(($minor_version + 1))
    [[ -n "$bump_micro_version" ]] && micro_version=$(($micro_version + 1))
    full_version="${major_version}.${minor_version}.${micro_version}"
    display_version="${full_version%.0}"
    sed -ri "s/$version_pattern/m4_define([purple_version_suffix], [${suffix_delimiter}${full_version}])/" "$source_dir/configure.ac"
    echo "Version bumped to $full_version"
fi

xsl_parameters="-s version=$display_version -s bugs.url=https://developer.pidgin.im/ticket"
if [[ -n "$output" ]]; then
    if [[ -d "$output" ]]; then
        echo "Please specify a file, not a directory."
        exit 1
    fi
    cd "$(dirname "$output")" || exit
    output=$(readlink -f "$output")
fi

# One format at a time
if [[ (-n "$html"   && -n "$markdown") ||
      (-n "$html"   && -n   "$debian") ||
      (-n "$debian" && -n "$markdown") ]]; then
      echo "Please specify one export format at a time."
      exit 1
fi

# HTML changelog
if [[ -n "$html" ]]; then
    cd "$build_dir"
    output="${output:-$base_dir/changelog.html}"
    unformatted="/tmp/changelog.unformatted.html"
    xsl_parameters="${xsl_parameters} -s screenshot.prefix=${screenshot_prefix}"
    xmlstarlet transform --omit-decl changelog.html.xsl $xsl_parameters changelog.xml | dos2unix > "$unformatted"
    xmlstarlet format --html --omit-decl --nocdata --indent-spaces 4 "$unformatted" | dos2unix > "$output"
    rm "$unformatted"
    sed -i -E "s/(<\!\[CDATA\[|(\s{4})?\]\]>)//" "$output"
    echo "Changelog exported to $output"
    exit
fi

# Markdown changelog
if [[ -n "$markdown" ]]; then
    cd "$build_dir"
    output="${output:-$base_dir/changelog.md}"
    xsl_parameters="${xsl_parameters} -s screenshot.prefix=${screenshot_prefix:-http://pidgin.renatosilva.me/}"
    xmlstarlet transform --omit-decl changelog.markdown.xsl $xsl_parameters changelog.xml | dos2unix > "$output"
    echo "Changelog exported to $output"
    exit
fi

# Debian changelog
if [[ -n "$debian" ]]; then
    cd "$build_dir"
    output="${output:-$base_dir/changelog.debian.txt}"
    distribution=$(lsb_release --codename --short 2> /dev/null || echo DISTRIBUTION)
    maintainer=$(bzr whoami 2> /dev/null || echo "${DEBFULLNAME:-NAME} <${DEBEMAIL:-EMAIL}>")
    xsl_parameters="$xsl_parameters -s package.version=VERSION -s distribution=$distribution"
    xmlstarlet transform --omit-decl changelog.debian.xsl $xsl_parameters -s maintainer="$maintainer" -s date="$(date -R)" changelog.xml | dos2unix > "$output"
    echo "Changelog exported to $output"
    exit
fi
