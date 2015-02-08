#!/bin/bash

# Pidgin++ Library Information
# Copyright (C) 2015 Renato Silva
# GNU GPLv2 licensed

# Package format: binary[::source]
# Tarball format: name::version::license_file::source_format::source_url

# Required only by GTK+
gtk_packages=(bzip2
              expat
              fontconfig
              freetype
              gtk2
              harfbuzz
              libffi
              libiconv
              libpng
              pixman
              shared-mime-info)

# Required only by main source code
other_packages=(cyrus-sasl
                drmingw
                enchant
                gtkspell
                hunspell
                libsystre
                libtre-git
                libxml2
                meanwhile
                nspr
                nss
                perl
                silc-toolkit
                sqlite3)

# Required by both GTK+ and main source code
common_packages=(atk
                 cairo
                 gdk-pixbuf2
                 gettext
                 glib2
                 pango
                 zlib
                 gcc-libs::gcc
                 libwinpthread-git::winpthreads-git)

# All packages
packages=("${gtk_packages[@]}"
          "${other_packages[@]}"
          "${common_packages[@]}")

# Non-packaged dependencies
tarballs=(winsparkle::0.4::COPYING::tar.gz::"https://github.com/vslavik/winsparkle/archive/v0.4.tar.gz")

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

tarball_name() {
    echo "${1%%::*}"
}

tarball_version() {
    local result="${1#*::}"
    echo "${result%%::*}"
}

tarball_license() {
    local result="${1#*::*::}"
    echo "${result%%::*}"
}

tarball_source_format() {
    local result="${1%::*}"
    echo "${result##*::}"
}

tarball_source_url() {
    echo "${1##*::}"
}

tarball_source_filename() {
    echo "$(tarball_name "$1")-$(tarball_version "$1").$(tarball_source_format "$1")"
}

library_manifest() {
    local output_file="$1"
    rm -f "$output_file"
    echo "# Required by both GTK+ and Pidgin++" >> "$output_file"; for library in "${common_packages[@]}"; do printf "$(package_name $library)=$(package_version $library)\n" >> "$output_file"; done; echo >> "$output_file"
    echo "# Required by GTK+ only"              >> "$output_file"; for library in "${gtk_packages[@]}";    do printf "$(package_name $library)=$(package_version $library)\n" >> "$output_file"; done; echo >> "$output_file"
    echo "# Required by Pidgin++ only"          >> "$output_file"; for library in "${other_packages[@]}";  do printf "$(package_name $library)=$(package_version $library)\n" >> "$output_file"; done
                                                                   for library in "${tarballs[@]}";        do printf "$(tarball_name $library)=$(tarball_version $library)\n" >> "$output_file"; done
}

library_licenses() {
    local devroot="$1"
    local output_directory="$2"
    local missing="${output_directory}/MISSING.txt"
    local license_top
    case $(gcc -dumpmachine) in
        i686-w64-mingw*)   license_top=/mingw32/share/licenses ;;
        x86_64-w64-mingw*) license_top=/mingw64/share/licenses ;;
        *)                 return 1
    esac
    rm -f "$missing"
    for library in "${packages[@]}"; do
        local package_name=$(package_name "$library")
        local package_name_short="${package_name}"
        package_name_short="${package_name_short%-git}"
        package_name_short="${package_name_short%-bzr}"
        package_name_short="${package_name_short%-hg}"
        mkdir -p "${output_directory}/${package_name}"
        if [[ -d "${license_top}/${package_name_short}" ]]; then
            cp -r "${license_top}/${package_name_short}"/* "${output_directory}/${package_name}"
        else
            rm -rf "${output_directory}/${package_name}"
            echo "$package_name" >> "$missing"
        fi
    done
    for library in "${tarballs[@]}"; do
        local tarball_name=$(tarball_name "$library")
        local tarball_version=$(tarball_version "$library")
        local tarball_license=$(tarball_license "$library")
        local library_location="${devroot}/win32-dev/${tarball_name}-${tarball_version}"
        mkdir -p "${output_directory}/${tarball_name}"
        if [[ -d "${library_location}" ]]; then
            cp -r "${library_location}"/${tarball_license} "${output_directory}/${tarball_name}"
        else
            rm -rf "${output_directory}/${tarball_name}"
            echo "$tarball_name" >> "$missing"
        fi
    done
}
