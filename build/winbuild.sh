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
##                          not already built and uploaded.
##     -o, --offline        Build both the standard and offline installers.
##     -c, --cleanup        Clean up the staging dir then exit.
##
##         --sign=FILE      Enable code signing with Microsoft Authenticode and
##                          GnuPG, using FILE as the PKCS #12 / PFX certificate
##                          for Authenticode. Both GnuPG and the signtool
##                          utility must be available from system path.
##
##     -r, --reset          Recreates the staging directory from scratch.
##         --staging=DIR    Staging directory, defaults to "pidgin.build".
##         --directory=DIR  Save result to DIR instead of DEVELOPMENT_ROOT.
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

# Prepare for code signing
if [[ -n "$sign" ]]; then
    gpg_version=$(gpg --version | head -1)
    gpg_version="${gpg_version##* }"
    [[ "$gpg_version" = 1.* ]] && hash gpg2 2> /dev/null && gpg=gpg2

    # Authenticode password
    read -s -p "Enter password for $sign: " pfx_password; echo
    openssl pkcs12 -in "$sign" -nodes -password "pass:$pfx_password" > /dev/null || exit 1

    # GnuPG password
    read -s -p "Enter password for GnuPG: " gpg_password; echo
    $gpg --batch --yes --passphrase "$gpg_password" --output /tmp/test.asc -ab "$0" || exit 1
    rm /tmp/test.asc
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

# Code signing
if [[ -n "$sign" ]]; then
    rm local.mak
    echo "SIGNTOOL_PFX = $sign" >> local.mak
    echo "GPG_SIGN = $gpg" >> local.mak
fi

# GTK+ runtime
build_binary() {
    make -f Makefile.mingw "$1" SIGNTOOL_PASSWORD="$pfx_password" GPG_PASSWORD="$gpg_password"
}
if [[ -n "$gtk" ]]; then
    build_binary gtk_runtime_zip_force
    exit
fi

# Installers
build_binary "installer${offline:+s}" || exit
for asc in "" ${sign:+.asc}; do
    [[ -n "$offline" ]] && mv -v pidgin-*-offline.exe$asc "$target/Pidgin $version Offline Setup.exe$asc"
    mv -v pidgin-*.exe$asc "$target/Pidgin $version Setup.exe$asc"
    mv -v pidgin-*-dbgsym.zip$asc "$target/Pidgin Debug Symbols $version.zip$asc"
done
make -f Makefile.mingw uninstall
cd -
