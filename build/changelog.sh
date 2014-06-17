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

distribution=$(lsb_release --codename --short || DISTRIBUTION)
maintainer=$(bzr whoami || echo "${DEBFULLNAME:-NAME} <${DEBEMAIL:-EMAIL}>")
package_version=$(apt-cache show pidgin | grep -m 1 Version | awk -F': ' '{ print $2 }' | sed s/-/-${custom_version,,}+/)
xsl_parameters="$xsl_parameters -s package.version=$package_version -s distribution=$distribution"
xmlstarlet transform --omit-decl changelog.debian.xsl $xsl_parameters -s maintainer="$maintainer" -s date="$(date -R)" changelog.xml | dos2unix > changelog.ubuntu.txt
