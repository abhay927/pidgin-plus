#!/bin/bash

version_pattern="PACKAGE_VERSION=[\"']?([^\"']+)[\"']?"
suffix_pattern='m4_define\(\[purple_version_suffix\], \[.(.*)\]\)'

pidgin_version=$(grep -E "$version_pattern" ../source/configure | sed -r s/"$version_pattern"/'\1'/)
custom_version=$(grep -E "$suffix_pattern" ../source/configure.ac | sed -r s/"$suffix_pattern"/'\1'/)
xsl_parameters="-s version=$pidgin_version -s version.custom=$custom_version -s bugs.url=https://developer.pidgin.im/ticket"

if [[ "$1" != "--ubuntu" ]]; then
    xmlstarlet transform --omit-decl changelog.html.xsl $xsl_parameters changelog.xml | dos2unix > changelog.unformatted.html
    xmlstarlet format --html --omit-decl --nocdata --indent-spaces 4 changelog.unformatted.html | dos2unix > changelog.html
    sed -i -E "s/(<\!\[CDATA\[|(\s{4})?\]\]>)//" changelog.html
    rm changelog.unformatted.html
    exit
fi

date=$(date '+%a, %d %b %Y %H:%M:%S %z')
maintainer=$(bzr whoami || echo "NAME <EMAIL>")
xmlstarlet transform --omit-decl changelog.debian.xsl $xsl_parameters -s maintainer="$maintainer" -s date="$date" changelog.xml | dos2unix > changelog.ubuntu.txt
