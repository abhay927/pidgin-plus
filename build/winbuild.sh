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
##     -p, --prepare        Create the required build environment under
##                          DEVELOPMENT_ROOT and exit.
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
##         --color=SWITCH   Enable or disable colors in output. SWITCH is either
##                          on or off. Default is enabling for terminals.
##

# Parse options
eval "$(from="$0" easyoptions.rb "$@"; echo result=$?)"
[[ ! -d "${arguments[0]}" && $result  = 0 ]] && echo "No valid development root specified, see --help."
[[ ! -d "${arguments[0]}" || $result != 0 ]] && exit

# Variables
base_dir=$(readlink -e "$(dirname "$0")/..")
source_dir="$base_dir/source"
build_dir="$base_dir/build"
sign="${sign:-$cert}"
sign="${sign:+yes}"
devroot="${arguments[0]}"
version=$($build_dir/changelog.sh --version)
staging="$devroot/${staging:-pidgin.build}"
target="${directory:-$devroot/distribution/$version}"
windev="$devroot/win32-dev/pidgin-windev.sh"

# Colored output and build function
if [[ -n "$color" && ("$color" != on && "$color" != off) ]]; then
    echo "Please specify a valid value for --color, see --help."
    exit 1
fi
if [[ "$color" = on || (-z "$color" && -t 1) ]]; then
    export PIDGIN_BUILD_COLORS="yes"
fi
source "$source_dir/colored.sh"
build() { ${PIDGIN_BUILD_COLORS:+color}make -f Makefile.mingw "$1" SIGNTOOL_PASSWORD="$pfx_password" GPG_PASSWORD="$gpg_password" "${@:2}" || exit 1; }

# Translations template
if [[ -n "$update_pot" ]]; then
    cd "$source_dir/po"
    intltool_home=$(readlink -e "$devroot/win32-dev/intltool_"*)
    PATH="$PATH:$intltool_home/bin" XGETTEXT_ARGS="--no-location --sort-output" intltool-update --pot
    exit
fi

# GnuPG version
gpg_version=$(gpg --version | head -1)
gpg_version="${gpg_version##* }"
[[ "$gpg_version" = 1.* ]] && hash gpg2 2> /dev/null && gpg=gpg2

# Code signing passwords
if [[ -n "$sign" || -n "$cert" ]]; then
    step "Configuring passwords"
    if [[ -n "$sign" ]]; then
        read -s -p "Enter password for GnuPG: " gpg_password; echo
        if ! $gpg --batch --yes --passphrase "$gpg_password" --output /tmp/test.asc -ab "$0"; then
            oops "failed validating GnuPG password"
            exit 1
        fi
        rm /tmp/test.asc
    fi
    if [[ -n "$cert" ]]; then
        read -s -p "Enter password for Authenticode: " pfx_password; echo
        if ! openssl pkcs12 -in "$cert" -nodes -password "pass:$pfx_password" > /dev/null; then
            oops "failed validating the Authenticode password"
            exit 1
        fi
    fi
    echo
fi

# Pidgin Windev
if [[ ! -e "$windev" ]]; then
    step "Downloading Pidgin Windev"
    tarball="$devroot/downloads/pidgin-windev.tar.gz"
    url="http://bazaar.launchpad.net/~renatosilva/pidgin-windev/trunk/tarball/head:"
    wget -nv "$url" -O "$tarball" && bsdtar -xzf "$tarball" --strip-components 3 --directory "$devroot/win32-dev" "~renatosilva/pidgin-windev/trunk/pidgin-windev.sh"
    [[ $? != 0 ]] && exit 1
    rm -f "$tarball"
    echo "Extracted $windev"
    echo
fi

# Build environment
if [[ -n "$prepare" ]]; then
    "$windev" --link-to-me --for pidgin++ --no-source --system-gcc "$devroot"
    exit
fi

# Cleanup
if [[ -n "$cleanup" ]]; then
    step "Cleaning up staging directory"
    if [[ -d "$staging" ]]; then
        cd "$staging"
        build uninstall
        build clean
        echo
    else
        oops "cannot clean up missing directory $staging"
    fi
    exit
fi

# Staging dir
step "Preparing the staging directory"
if [[ -n "$reset" ]]; then
    task "Removing $staging"
    rm -rf "$staging"
    echo
fi
if [[ ! -d "$staging" ]]; then
    task "Creating $staging"
    mkdir -p "$staging"
else
    task "Updating $staging"
fi
cp -rup "$source_dir/"* "$staging"; echo
"$build_dir/changelog.sh" --html --output "$staging/CHANGES.html"

# Code signing
cd "$staging"
if [[ -n "$cert" || -n "$sign" ]]; then
    task "Configuring code signing with GnuPG${cert:+ and Authenticode}"
    if [[ -n "$cert" ]]; then
        rm local.mak
        echo "SIGNTOOL_PFX = $cert" >> local.mak
        echo "GPG_SIGN = $gpg" >> local.mak
    else
        sed -i "s/^GPG_SIGN.*/GPG_SIGN = $gpg/" local.mak
    fi
    echo
fi

# System path
task "Configuring system path"
eval $("$windev" "$devroot" --path --system-gcc)
echo

# GTK+ and dictionary bundles
mkdir -p "$target"
if [[ -n "$gtk" || -n "$dictionaries" ]]; then
    if [[ -n "$gtk" ]]; then
        build gtk_runtime_zip_force
        gtk_version=$(pidgin/win32/nsis/generate_gtk_zip.sh --gtk-version)
        for asc in "" ${sign:+.asc}; do
            mv -v pidgin/win32/nsis/gtk-runtime-$gtk_version.zip$asc "$target/Pidgin GTK+ Runtime $gtk_version.zip$asc"
            [[ -f pidgin/win32/nsis/gtk-runtime-$gtk_version-source.zip$asc ]] && mv -v pidgin/win32/nsis/gtk-runtime-$gtk_version-source.zip$asc "$target/Pidgin GTK+ Runtime $gtk_version Source.zip$asc"
        done
    fi
    if [[ -n "$dictionaries" ]]; then
        build dictionaries_bundle_force
        for asc in "" ${sign:+.asc}; do
            mv -v pidgin/win32/nsis/dictionaries.zip$asc "$target/Pidgin Dictionaries.zip$asc"
        done
    fi
    echo
    exit
fi

# Source code bundle
if [[ -n "$source" ]]; then
    if [[ ! -d "$base_dir/.bzr" ]]; then
        oops "creation failed, this is not a Bazaar branch"
        exit 1
    fi
    build source_code_zip BAZAAR_BRANCH="$base_dir"
    for asc in "" ${sign:+.asc}; do
        mv -v pidgin-*-source.zip$asc "$target/Pidgin $version Source.zip$asc"
    done
fi

# Installers
pace "Building the installer${offline:+s}"
build "installer${offline:+s}"
for asc in "" ${sign:+.asc}; do
    [[ -n "$offline" ]] && mv -v pidgin-*-offline.exe$asc "$target/Pidgin $version Offline Setup.exe$asc"
    mv -v pidgin-*.exe$asc "$target/Pidgin $version Setup.exe$asc"
    mv -v pidgin-*-dbgsym.zip$asc "$target/Pidgin Debug Symbols $version.zip$asc"
done
build uninstall
step "Build finished."
echo
