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
##     -t, --update-pot     Update the translations template and exit.
##     -d, --dictionaries   Build the dictionaries bundle instead of installers.
##     -g, --gtk            Build the GTK+ runtime instead of installers, if
##                          not already built and uploaded. Both binary and
##                          source code packages are generated.
##
##     -c, --cleanup        Clean up the staging dir then exit.
##     -o, --offline        Build both the standard and offline installers.
##     -s, --source         Build the source code bundle together with the
##                          installer, if this source code tree is a Bazaar
##                          branch. Requires Bazaar.
##
##         --sign           Enable code signing with GnuPG. This applies to the
##                          source code, dictionary and GTK+ bundles, as well as
##                          to the installers. Requires GnuPG.
##
##         --cert=FILE      Enable code signing with Microsoft Authenticode,
##                          using FILE as the PKCS #12 / PFX certificate. This
##                          applies to the main executable and the installers.
##                          Requires the signtool utility from Windows SDK.
##                          Implies --sign.
##
##     -r, --reset          Recreates the staging directory from scratch.
##         --staging=DIR    Staging directory, defaults to "pidgin.build".
##         --directory=DIR  Save result to DIR instead of default location
##                          (DEVELOPMENT_ROOT/distribution).
##

# Parse options
eval "$(from="$0" easyoptions.rb "$@"; echo result=$?)"
[[ ! -d "${arguments[0]}" && $result  = 0 ]] && echo "No valid development root specified, see --help."
[[ ! -d "${arguments[0]}" || $result != 0 ]] && exit

# Variables and functions
sign="${sign:-$cert}"
sign="${sign:+yes}"
devroot="${arguments[0]}"
version=$(./changelog.sh --version)
staging="$devroot/${staging:-pidgin.build}"
target="${directory:-$devroot/distribution/$version}"
windev="$devroot/win32-dev/pidgin-windev.sh"
build() { make -f Makefile.mingw "$1" SIGNTOOL_PASSWORD="$pfx_password" GPG_PASSWORD="$gpg_password" "${@:2}" || exit 1; }

# Translations template
if [[ -n "$update_pot" ]]; then
    cd ../source/po
    intltool_home=$(readlink -e "$devroot/win32-dev/intltool_"*)
    PATH="$PATH:$intltool_home/bin" XGETTEXT_ARGS="--no-location --sort-output" intltool-update --pot
    exit
fi

# GnuPG version and password
if [[ -n "$sign" ]]; then
    gpg_version=$(gpg --version | head -1)
    gpg_version="${gpg_version##* }"
    [[ "$gpg_version" = 1.* ]] && hash gpg2 2> /dev/null && gpg=gpg2
    read -s -p "Enter password for GnuPG: " gpg_password; echo
    $gpg --batch --yes --passphrase "$gpg_password" --output /tmp/test.asc -ab "$0" || exit 1
    rm /tmp/test.asc
fi

# Authenticode password
if [[ -n "$cert" ]]; then
    read -s -p "Enter password for Authenticode: " pfx_password; echo
    openssl pkcs12 -in "$cert" -nodes -password "pass:$pfx_password" > /dev/null || exit 1
fi

# Pidgin Windev
if [[ ! -e "$windev" ]]; then
    tarball="$devroot/downloads/pidgin-windev.tar.gz"
    url="http://bazaar.launchpad.net/~renatosilva/pidgin-windev/trunk/tarball/head:"
    wget -nv "$url" -O "$tarball" && bsdtar -xzf "$tarball" --strip-components 3 --directory "$devroot/win32-dev" "~renatosilva/pidgin-windev/trunk/pidgin-windev.sh"
    [[ $? != 0 ]] && exit 1
    echo "Extracted $windev"
fi

# Cleanup
if [[ -n "$cleanup" ]]; then
    if [[ -d "$staging" ]]; then
        cd "$staging"
        build uninstall
        build clean
    else
        echo "Nothing to clean up."
    fi
    exit
fi

# Staging dir
if [[ -n "$reset" ]]; then
    echo "Removing $staging..."
    rm -rf "$staging"
fi
echo "Exporting source code to $staging..."
mkdir -p "$staging"
cp -r ../source/* "$staging"
./changelog.sh --html && mv -v changelog.html "$staging/CHANGES.html"

# Prepare
branch=$(readlink -m "$(pwd)/..")
eval $("$windev" "$devroot" --path --system-gcc)
cd "$staging"

# Code signing
if [[ -n "$cert" ]]; then
    rm local.mak
    echo "SIGNTOOL_PFX = $cert" >> local.mak
    echo "GPG_SIGN = $gpg" >> local.mak
elif [[ -n "$sign" ]]; then
    sed -i "s/^GPG_SIGN.*/GPG_SIGN = $gpg/" local.mak
fi

# GTK+ and dictionary bundles
mkdir -p "$target"
if [[ -n "$gtk" || -n "$dictionaries" ]]; then
    if [[ -n "$gtk" ]]; then
        build gtk_runtime_zip_force
        gtk_version=$(pidgin/win32/nsis/generate_gtk_zip.sh --gtk-version)
        for asc in "" ${sign:+.asc}; do
            mv -v pidgin/win32/nsis/gtk-runtime-*-source.zip$asc "$target/Pidgin GTK+ Runtime $gtk_version Source.zip$asc"
            mv -v pidgin/win32/nsis/gtk-runtime-*.zip$asc "$target/Pidgin GTK+ Runtime $gtk_version.zip$asc"
        done
    fi
    if [[ -n "$dictionaries" ]]; then
        build dictionaries_bundle_force
        for asc in "" ${sign:+.asc}; do
            mv -v pidgin/win32/nsis/dictionaries.zip$asc "$target/Pidgin Dictionaries.zip$asc"
        done
    fi
    exit
fi

# Source code bundle
if [[ -n "$source" ]]; then
    if [[ ! -d "$branch/.bzr" ]]; then
        echo "Error: cannot create source code bundle because this is not a Bazaar branch."
        exit 1
    fi
    echo
    echo "Creating the source code bundle..."
    build source_code_zip BAZAAR_BRANCH="$branch"
    for asc in "" ${sign:+.asc}; do
        mv -v pidgin-*-source.zip$asc "$target/Pidgin $version Source.zip$asc"
    done
    echo
fi

# Installers
build "installer${offline:+s}"
for asc in "" ${sign:+.asc}; do
    [[ -n "$offline" ]] && mv -v pidgin-*-offline.exe$asc "$target/Pidgin $version Offline Setup.exe$asc"
    mv -v pidgin-*.exe$asc "$target/Pidgin $version Setup.exe$asc"
    mv -v pidgin-*-dbgsym.zip$asc "$target/Pidgin Debug Symbols $version.zip$asc"
done
build uninstall
echo "Build finished."
cd - > /dev/null
