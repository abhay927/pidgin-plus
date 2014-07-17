#!/bin/bash

##
##     Pidgin++ Windows Builder
##     Copyright (c) 2014 Renato Silva
##     GNU GPLv2 licensed
##
## This is the builder script for Pidgin++ on Windows. Source code will be
## exported to an appropriate staging directory within the specified development
## root. Result is a standard installer (without GTK+) placed alongside the
## staging directory by default.
##
## Usage:
##     @script.name DEVELOPMENT_ROOT [options]
##
##     -g, --gtk            Build the GTK+ runtime instead of installers, if
##                          version is suffixed with "devel".
##     -o, --offline        Build both the standard and offline installers.
##     -c, --cleanup        Clean up the staging dir then exit.
##
##     -r, --reset          Recreates the staging directory from scratch.
##     -s, --staging=DIR    Staging directory, defaults to "pidgin.build".
##     -d, --directory=DIR  Save result to DIR instead of DEVELOPMENT_ROOT.
##

# Parse options
eval "$(from="$0" easyoptions.rb "$@"; echo result=$?)"
[[ ! -d "${arguments[0]}" && $result  = 0 ]] && echo "No valid development root specified, see --help."
[[ ! -d "${arguments[0]}" || $result != 0 ]] && exit

# Variables
devroot="${arguments[0]}"
version=$(./changelog.sh --version)
staging="$devroot/${staging:-pidgin.build}"
target="${directory:-$devroot}"
windev="$devroot/win32-dev/pidgin-windev.sh"

# GTK+ runtime only for devel version
if [[ -n "$gtk" && "$version" != *devel ]]; then
    echo 'GTK+ can only be generated for "devel" versions, see --help.'
    exit 1
fi

# Pidgin Windev
if [[ ! -e "$windev" ]]; then
    tarball="$devroot/downloads/pidgin-windev.tar.gz"
    url="http://bazaar.launchpad.net/~renatosilva/pidgin-windev/main/tarball"
    wget -nv "$url" -O "$tarball" && bsdtar -xzf "$tarball" --strip-components 3 --directory "$devroot/win32-dev"
    [[ $? != 0 ]] && exit 1
    echo "Extracted $windev"
fi

# Cleanup
if [[ -n "$cleanup" ]]; then
    if [[ -d "$staging" ]]; then
        cd "$staging"
        make -f Makefile.mingw uninstall
        make -f Makefile.mingw clean
    else
        echo "Nothing to clean up."
    fi
    exit
fi

# Staging dir
[[ -n "$reset" ]] && rm -rf "$staging"
mkdir -p "$staging"
cp -r ../source/* "$staging"
./changelog.sh --html && mv -v changelog.html "$staging/CHANGES.html"

# Prepare
eval $("$windev" "$devroot" --path --system-gcc)
cd "$staging"

# GTK+ runtime
if [[ -n "$gtk" ]]; then
    make -f Makefile.mingw gtk_runtime_zip
    exit
fi

# Installers
make -f Makefile.mingw "installer${offline:+s}" || exit
[[ -n "$offline" ]] && mv -v pidgin-*-offline.exe "$target/Pidgin $version Offline Setup.exe"
mv -v pidgin-*.exe "$target/Pidgin $version Setup.exe"
mv -v pidgin-*-dbgsym.zip "$target/Pidgin Debug Symbols $version.zip"
make -f Makefile.mingw uninstall
cd -
