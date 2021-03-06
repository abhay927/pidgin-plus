#!/bin/bash

# Pidgin++ Dependency Information
# Copyright (C) 2015 Renato Silva
# Licensed under GNU GPLv2 or later

package_architecture=$(gcc -dumpmachine)
package_architecture="${package_architecture%%-*}"
mingw_package_prefix="mingw-w64-${package_architecture}"

# Format: binary[::source]

build_dependencies=(base-devel
                    bsdtar
                    bzip2
                    coreutils
                    libiconv
                    libopenssl
                    rsync
                    unzip
                    zip
                    ${mingw_package_prefix}-gcc
                    ${mingw_package_prefix}-nsis
                    ${mingw_package_prefix}-nsis-nsisunz
                    ${mingw_package_prefix}-xmlstarlet)

runtime_dependencies=(${mingw_package_prefix}-cyrus-sasl
                      ${mingw_package_prefix}-drmingw
                      ${mingw_package_prefix}-gtk2
                      ${mingw_package_prefix}-gtkspell
                      ${mingw_package_prefix}-libxml2
                      ${mingw_package_prefix}-meanwhile
                      ${mingw_package_prefix}-nspr
                      ${mingw_package_prefix}-nss
                      ${mingw_package_prefix}-perl
                      ${mingw_package_prefix}-silc-toolkit
                      ${mingw_package_prefix}-winsparkle)

indirect_dependencies=(# Required only by GTK+
                       ${mingw_package_prefix}-bzip2
                       ${mingw_package_prefix}-fontconfig
                       ${mingw_package_prefix}-freetype
                       ${mingw_package_prefix}-graphite2
                       ${mingw_package_prefix}-harfbuzz
                       ${mingw_package_prefix}-libffi
                       ${mingw_package_prefix}-libiconv
                       ${mingw_package_prefix}-pcre
                       ${mingw_package_prefix}-pixman
                       ${mingw_package_prefix}-shared-mime-info

                       # Required only by main source code
                       ${mingw_package_prefix}-enchant
                       ${mingw_package_prefix}-hunspell
                       ${mingw_package_prefix}-libjpeg-turbo
                       ${mingw_package_prefix}-libsystre
                       ${mingw_package_prefix}-libtiff
                       ${mingw_package_prefix}-libtre
                       ${mingw_package_prefix}-sqlite3
                       ${mingw_package_prefix}-wxWidgets
                       ${mingw_package_prefix}-xz

                       # Required by both GTK+ and main source code
                       ${mingw_package_prefix}-atk
                       ${mingw_package_prefix}-cairo
                       ${mingw_package_prefix}-expat
                       ${mingw_package_prefix}-gcc-libs::${mingw_package_prefix}-gcc
                       ${mingw_package_prefix}-gdk-pixbuf2
                       ${mingw_package_prefix}-gettext
                       ${mingw_package_prefix}-glib2
                       ${mingw_package_prefix}-libpng
                       ${mingw_package_prefix}-libwinpthread::${mingw_package_prefix}-winpthreads
                       ${mingw_package_prefix}-pango
                       ${mingw_package_prefix}-zlib)

packages=("${runtime_dependencies[@]}" "${indirect_dependencies[@]}")

package_name() {
    echo "${1%%::*}"
}

package_source() {
    local result="${1#*::}"
    echo "${result%%::*}"
}

package_version_vcs() {
    local result
    local name="$1"
    local vcs="$2"
    result=$(pacman -Q $(package_name ${name}${vcs:+-${vcs}}) 2> /dev/null)
    result="${result##* }"
    test -z "$result" && return 1
    echo "${vcs:+${vcs}-}${result}"
}

package_version() {
    local package_name=$(package_name $1)
    package_version_vcs "${package_name}"     || \
    package_version_vcs "${package_name}" git || \
    package_version_vcs "${package_name}" bzr || \
    package_version_vcs "${package_name}" svn || \
    package_version_vcs "${package_name}" cvs || \
    package_version_vcs "${package_name}" hg  ||
    echo 'UNKNOWN'
}

library_manifest() {
    local output_file="$1"
    rm -f "$output_file"
    for library in "${packages[@]}"; do
        printf "$(package_name $library)=$(package_version $library)\n" >> "$output_file"
    done
}

library_licenses() {
    local output_directory="$1"
    local missing="${output_directory}/MISSING.txt"
    local script_dir=$(readlink -f "$(dirname "$BASH_SOURCE")")
    local license_top
    case "$package_architecture" in
        x86_64) license_top=/mingw64/share/licenses ;;
        i686)   license_top=/mingw32/share/licenses ;;
        *)      return 1
    esac
    rm -f "$missing"
    source "$script_dir/../../colored.sh"
    for library in "${packages[@]}"; do
        local package_name=$(package_name "$library")
        local library_name="${package_name#mingw-w64-$package_architecture-}"
        library_name="${library_name%-git}"
        library_name="${library_name%-bzr}"
        library_name="${library_name%-svn}"
        library_name="${library_name%-cvs}"
        library_name="${library_name%-hg}"
        mkdir -p "${output_directory}/${library_name}"
        if [[ -d "${license_top}/${library_name}" ]]; then
            cp -r "${license_top}/${library_name}"/* "${output_directory}/${library_name}" || return 1
        else
            rm -rf "${output_directory}/${library_name}"
            echo "$package_name" >> "$missing"
            warn "missing directory ${license_top}/${library_name}"
        fi
    done
}
