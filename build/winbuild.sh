#!/bin/bash

##
##     Pidgin++ Windows Builder
##     Copyright (c) 2014, 2015 Renato Silva
##     Licensed under GNU GPLv2 or later
##
## Usage:
##     @script.name [options] BUILD_ROOT
##
##     -p, --prepare        Install the required package dependencies and exit.
##
##     -o, --offline        Build both the standard and offline installers. The
##                          offline installer includes debug symbols and spell
##                          checking dictionaries.
##
##     -s, --source         Build the source code bundle together with the
##                          installer, if this source code tree is a Bazaar
##                          branch. Requires Bazaar.
##
##     -d, --dictionaries   Build the dictionaries bundle instead of installers.
##         --no-update      Disable the application update checking.
##     -c, --cleanup        Clean up the build directory and exit.
##         --make=TARGET    Execute an arbitrary makefile target.
##
##         --build=NAME     Custom name for build directory.
##         --reset          Recreate the build directory from scratch.
##         --output=DIR     Output to DIR instead of BUILD_ROOT/distribution.
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
##         --color=SWITCH   Enable or disable colors in output. SWITCH is either
##                          on or off. Default is enabling for terminals.
##
##         --encoding=NAME  Convert output from the encoding specified in $LANG
##                          to NAME. If NAME is "default" then target encoding
##                          is set to that of the current locale.
##

# Parse options
source easyoptions || exit
build_root="${arguments[0]}"
if [[ -z "$build_root" ]]; then
    echo 'No build root specified, see --help.'
    exit 1
fi

# Other variables
machine=$(gcc -dumpmachine)
case "$machine" in
    i686-w64-mingw*)   architecture="x86"; bitness="32" ;;
    x86_64-w64-mingw*) architecture="x64"; bitness="64" ;;
    *)                 architecture="$machine"
esac
build_root=$(readlink -f "$build_root")
base_dir=$(readlink -e "$(dirname "$0")/..")
source_dir="$base_dir/source"
sign="${sign:-$cert}"
sign="${sign:+yes}"
version=$("${base_dir}/build/changelog.sh" --version)
build="$build_root/build/${build:-pidgin.${bitness:-$machine}}"
target="${output:-$build_root/distribution/$version/$architecture}"
documents="$build/documents"

# Colored output
if [[ -n "$color" && ("$color" != on && "$color" != off) ]]; then
    echo "Please specify a valid value for --color, see --help."
    exit 1
fi
if [[ "$color" = on || (-z "$color" && -t 1) ]]; then
    export PIDGIN_BUILD_COLORS="yes"
fi
source "$source_dir/colored.sh"

# Functions and output encoding
move_signed() {
    mv -v "${1}" "${2}"
    test -n "${sign}" && mv -v "${1}.asc" "${2}.asc"
}
domake() {
    ${PIDGIN_BUILD_COLORS:+color}make -f Makefile.mingw "$1" \
        BAZAAR_BRANCH="$base_dir" SIGNTOOL_PASSWORD="$pfx_password" GPG_PASSWORD="$gpg_password" \
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

# Install dependencies
source "${source_dir}/pidgin/win32/dependencies.sh"
if [[ -n "$prepare" ]]; then
    pacman --color auto --noconfirm --needed --sync "${build_dependencies[@]}" "${runtime_dependencies[@]}"
    exit
fi

# Cleanup
if [[ -n "$cleanup" ]]; then
    step "Cleaning up build directory"
    if [[ -d "$build" ]]; then
        cd "$build"
        build uninstall
        build clean
        echo
    else
        oops "cannot clean up missing directory $build"
    fi
    exit
fi

# Build directory
step "Preparing the build directory"
if [[ -n "$reset" ]]; then
    echo "Removing $build"
    rm -rf "$build"
fi
if [[ ! -d "$build" ]]; then
    echo "Creating $build"
    mkdir -p "$build"
else
    echo "Updating $build"
    rm -f "$build/local.mak"
fi
rsync --recursive --times "$source_dir/"* "$build" || exit 1
touch "$build/pidgin/gtkdialogs.c"
rm -rf "$documents"
mkdir -p "$documents/libraries"
"${base_dir}/build/changelog.sh" --html --screenshot-prefix "../" --output "$documents/CHANGELOG.html"

# Library information
echo "Creating library manifest"
library_manifest "$documents/libraries/MANIFEST"

# Library licenses
echo "Integrating library licenses"
licenses="$documents/libraries/licenses"
rm -rf "$licenses"
library_licenses "$licenses" || warn "error installing licenses to ${licenses}"

# Code signing
cd "$build"
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
    move_signed 'pidgin/win32/nsis/dictionaries.zip' "${target}/Pidgin++ Dictionaries.zip"
    echo
    exit
fi

# Source code bundle
if [[ -n "$source" ]]; then
    if [[ ! -d "$base_dir/.bzr" ]]; then
        oops "creation failed, this is not a Bazaar branch"
        exit 1
    fi
    build source_code_zip
    move_signed pidgin++_*_source.zip "${target}/Pidgin++ ${version} ${architecture} Source.zip"
fi

# Installers
pace "Building the installer${offline:+s} for $version"
gcc_dir=$(dirname $(which gcc))
gcc_version=$(gcc -dumpversion)
echo "Using GCC $gcc_version from $gcc_dir"
build "installer${offline:+s}"
test -n "${offline}" && move_signed pidgin++_*_offline.exe "${target}/Pidgin++ ${version} ${architecture} Offline Setup.exe"
move_signed pidgin++_*.exe "${target}/Pidgin++ ${version} ${architecture} Setup.exe"
build uninstall
step "Build finished."
echo
