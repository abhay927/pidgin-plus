#!/bin/bash

##
##     Pidgin++ Windows Builder
##     Copyright (c) 2014, 2015 Renato Silva
##     GNU GPLv2 licensed
##
## This is the builder script for Pidgin++ on Windows. Source code will be
## exported to an appropriate staging directory within the specified development
## root. Default output is a standard installer, placed under the distribution
## subdirectory in the development root.
##
## Usage:
##     @script.name DEVELOPMENT_ROOT [options]
##
##     -p, --prepare        Create the required build environment under
##                          DEVELOPMENT_ROOT and exit. This is not needed for
##                          creating an MSYS2 package.
##
##     -t, --update-pot     Update the translations template and exit.
##     -d, --dictionaries   Build the dictionaries bundle instead of installers.
##         --make=TARGET    Execute an arbitrary makefile target.
##
##         --no-update      Disable the application update checking.
##     -c, --cleanup        Clean up the staging dir then exit.
##     -o, --offline        Build both the standard and offline installers. The
##                          offline installer includes debug symbols and spell
##                          checking dictionaries.
##     -s, --source         Build the source code bundle together with the
##                          installer, if this source code tree is a Bazaar
##                          branch. Requires Bazaar.
##
##         --sign           Enable code signing with GnuPG. This applies to the
##                          source code and dictionary bundles, as well as to
##                          the installers. Requires GnuPG.
##
##         --cert=FILE      Enable code signing with Microsoft Authenticode,
##                          using FILE as the PKCS #12 / PFX certificate. This
##                          applies to the main executable and the installers.
##                          Requires the signtool utility from Windows SDK.
##                          Implies --sign.
##
##         --directory=DIR  Save result to DIR instead of default location
##                          (DEVELOPMENT_ROOT/distribution).
##         --staging=DIR    Custom staging directory.
##     -r, --reset          Recreates the staging directory from scratch.
##
##         --color=SWITCH   Enable or disable colors in output. SWITCH is either
##                          on or off. Default is enabling for terminals.
##         --encoding=NAME  Convert output from the encoding specified in $LANG
##                          to NAME. If NAME is "default" then target encoding
##                          is set to that of the current locale.
##

# Parse options
source easyoptions || exit
devroot="${arguments[0]}"
if [[ -z "$prepare" && ! -d "$devroot" ]]; then
    echo "No valid development root specified, see --help."
    exit 1
fi

# Other variables
[[ -n "$prepare" ]] && mkdir -p "$devroot"
case $(gcc -dumpmachine) in
    i686-w64-mingw*)   bitness=32; architecture=x86 ;;
    x86_64-w64-mingw*) bitness=64; architecture=x64 ;;
esac
devroot=$(readlink -e $devroot)
base_dir=$(readlink -e "$(dirname "$0")/..")
source_dir="$base_dir/source"
build_dir="$base_dir/build"
sign="${sign:-$cert}"
sign="${sign:+yes}"
version=$($build_dir/changelog.sh --version)
windev="$devroot/win32-dev/pidgin-windev.sh"
staging="$devroot/${staging:-pidgin.build.$bitness}"
target_top="${directory:-$devroot/distribution/$version}"
target="$target_top/$architecture"
target_source="$target_top/source"

# Colored output
if [[ -n "$color" && ("$color" != on && "$color" != off) ]]; then
    echo "Please specify a valid value for --color, see --help."
    exit 1
fi
if [[ "$color" = on || (-z "$color" && -t 1) ]]; then
    export PIDGIN_BUILD_COLORS="yes"
fi
source "$source_dir/colored.sh"

# Build functions and output encoding
domake() {
    ${PIDGIN_BUILD_COLORS:+color}make -f Makefile.mingw "$1" \
        SIGNTOOL_PASSWORD="$pfx_password" GPG_PASSWORD="$gpg_password" \
        ${no_update:+DISABLE_UPDATE_CHECK=yes} "${@:2}"
    return $?
}
if [[ -n "$encoding" ]]; then
    case "$encoding" in
    default) iconv="iconv -f ${LANG##*.}" ;;
          *) iconv="iconv -f ${LANG##*.} ${encoding:+-t $encoding}" ;;
    esac
    mv() { command mv "$@" > >($iconv) 2> >($iconv); }
    build() { domake "$@" > >($iconv) 2> >($iconv) || exit 1; }
else
    build() { domake "$@" || exit 1; }
fi

# Translations template
if [[ -n "$update_pot" ]]; then
    cd "$source_dir/po"
    echo "Updating the translation template"
    XGETTEXT_ARGS="--no-location --sort-output" intltool-update --pot
    exit
fi

# GnuPG version
gpg=gpg
gpg_version=$($gpg --version | head -1)
gpg_version="${gpg_version##* }"
[[ "$gpg_version" = 1.* ]] && hash gpg2 2> /dev/null && gpg=gpg2

# Code signing passwords
if [[ -n "$sign" || -n "$cert" ]]; then
    step "Configuring code signing"
    if [[ -n "$cert" ]]; then
        signtool="$(dirname "$(which pvk2pfx)")/signtool.exe"
        echo "Using SignTool from $signtool"
    fi
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

# Build environment
if [[ ! -e "$windev" ]]; then
    step "Downloading Pidgin Windev"
    echo "Downloading latest revision from Launchpad"
    windev_tarball="$devroot/downloads/pidgin-windev.tar.gz"
    mkdir -p "$devroot/downloads"
    if ! wget --quiet --output-document "$windev_tarball" "http://bazaar.launchpad.net/~renatosilva/pidgin-windev/trunk/tarball/head:"; then
        oops "failed downloading to $windev_tarball"
        exit 1
    fi
    if ! bsdtar -xzf "$windev_tarball" --strip-components 3 --directory "$devroot/win32-dev" "~renatosilva/pidgin-windev/trunk/pidgin-windev.sh"; then
        oops "failed extracting $windev_tarball"
        exit 1
    fi
    echo "Extracted to $windev"
    echo
fi
if [[ -n "$prepare" ]]; then
    "$windev" --no-source "$devroot"
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
    echo "Removing $staging"
    rm -rf "$staging"
fi
if [[ ! -d "$staging" ]]; then
    echo "Creating $staging"
    mkdir -p "$staging"
else
    echo "Updating $staging"
    rm -f "$staging/local.mak"
fi
cp -rup "$source_dir/"* "$staging"
touch "$staging/pidgin/gtkdialogs.c"
"$build_dir/changelog.sh" --html --output "$staging/CHANGES.html"

# Code signing
cd "$staging"
if [[ -n "$cert" || -n "$sign" ]]; then
    echo "Configuring code signing with GnuPG${cert:+ and Authenticode}"
    if [[ -n "$cert" ]]; then
        echo "SIGNTOOL_PFX = $cert" > local.mak
        echo "SIGNTOOL = \"$signtool\"" >> local.mak
        echo "GPG_SIGN = $gpg" >> local.mak
    else
        echo "GPG_SIGN = $gpg" > local.mak
    fi
fi

# System path
echo "Configuring system path"
eval $("$windev" "$devroot" --path) || exit

# Arbitrary target
if [[ -n "$make" ]]; then
    pace "Executing arbitrary target $make"
    build "$make"
    exit
fi

# Dictionaries bundle
mkdir -p "$target"
if [[ -n "$dictionaries" ]]; then
    build dictionaries_bundle_force
    for asc in "" ${sign:+.asc}; do
        mv -v pidgin/win32/nsis/dictionaries.zip$asc "$target/Pidgin++ Dictionaries.zip$asc"
    done
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
    mkdir -p "$target_source"
    for asc in "" ${sign:+.asc}; do
        mv -v pidgin++_*_source_main.zip$asc   "${target_source}/Pidgin++ ${version} Source.zip$asc"
        mv -v pidgin++_*_source_gtk.zip$asc    "${target_source}/Pidgin++ ${version} Source GTK+.zip$asc"
        mv -v pidgin++_*_source_other.zip$asc  "${target_source}/Pidgin++ ${version} Source Other.zip$asc"
    done
fi

# Installers
pace "Building the installer${offline:+s} for $version"
gcc_dir=$(dirname $(which gcc))
gcc_version=$(gcc -dumpversion)
echo "Using GCC $gcc_version from $gcc_dir"
build "installer${offline:+s}"
for asc in "" ${sign:+.asc}; do
    [[ -n "$offline" ]] && mv -v pidgin++_*_offline.exe$asc "$target/Pidgin++ $version $architecture Offline Setup.exe$asc"
    mv -v pidgin++_*.exe$asc "$target/Pidgin++ $version $architecture Setup.exe$asc"
done
build uninstall
step "Build finished."
echo
