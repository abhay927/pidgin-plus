#!/bin/bash

# Pidgin++ Library Information
# Copyright (C) 2015 Renato Silva
# Licensed under GNU GPLv2 or later

# Format: binary[::source]

packages=(# Required only by GTK+
          bzip2
          fontconfig
          freetype
          harfbuzz
          libffi
          libiconv
          pixman
          shared-mime-info

          # Required only by main source code
          cyrus-sasl
          drmingw
          enchant
          gtk2
          gtkspell
          hunspell
          libjpeg-turbo
          libsystre
          libtre-git
          libxml2
          meanwhile
          nspr
          nss
          perl
          silc-toolkit
          sqlite3
          winsparkle-git
          wxWidgets

          # Required by both GTK+ and main source code
          atk
          cairo
          expat
          gcc-libs::gcc
          gdk-pixbuf2
          gettext
          glib2
          libpng
          libwinpthread-git::winpthreads-git
          pango
          zlib)

package_name() {
    echo "${1%%::*}"
}

package_source() {
    local result="${1#*::}"
    echo "${result%%::*}"
}

package_version() {
    local result
    local architecture=$(gcc -dumpmachine)
    architecture="${architecture%%-*}"
    result=$(pacman -Q mingw-w64-${architecture}-$(package_name $1))
    echo "${result##* }"
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
    case $(gcc -dumpmachine) in
        i686-w64-mingw*)   license_top=/mingw32/share/licenses ;;
        x86_64-w64-mingw*) license_top=/mingw64/share/licenses ;;
        *)                 return 1
    esac
    rm -f "$missing"
    source "$script_dir/../../colored.sh"
    for library in "${packages[@]}"; do
        local package_name=$(package_name "$library")
        local package_name_short="${package_name}"
        package_name_short="${package_name_short%-git}"
        package_name_short="${package_name_short%-bzr}"
        package_name_short="${package_name_short%-hg}"
        mkdir -p "${output_directory}/${package_name}"
        if [[ -d "${license_top}/${package_name_short}" ]]; then
            cp -r "${license_top}/${package_name_short}"/* "${output_directory}/${package_name}" || return 1
        else
            rm -rf "${output_directory}/${package_name}"
            echo "$package_name" >> "$missing"
            warn "missing directory ${license_top}/${package_name_short}"
        fi
    done
}
