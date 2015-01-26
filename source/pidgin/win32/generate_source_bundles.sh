#!/bin/bash

# Pidgin++ Source Bundles Generator
# Copyright (C) 2014, 2015 Renato Silva
# GNU GPLv2 licensed

bazaar_branch="$3"
display_version="$2"
pidgin_base=$(readlink -f "$1")
architecture=$(gcc -dumpmachine)
architecture="${architecture%%-*}"
zip_root_main="pidgin++_${display_version}"
zip_file_main="${zip_root_main}_source_main.zip"
zip_file_gtk="${zip_root_main}_source_gtk.zip"
zip_file_other="${zip_root_main}_source_other.zip"
working_dir="${pidgin_base}/pidgin/win32/source_bundle_stage"
source "$pidgin_base/colored.sh"

tarballs=(winsparkle-0.4.tar.gz:"https://github.com/vslavik/winsparkle/archive/v0.4.tar.gz")
gtk_packages=(atk
              bzip2
              cairo
              expat
              fontconfig
              freetype
              gdk-pixbuf2
              gettext
              glib2
              gtk2
              harfbuzz
              libffi
              libiconv
              libpng
              pango
              pixman
              shared-mime-info
              zlib)

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
                sqlite3
                # These are also used by GTK+
                gcc
                winpthreads-git)

library_bundle() {
    local packages
    local type="$1"
    local zip_file="$2"
    case "$type" in
        GTK+)  packages=("${gtk_packages[@]}"); unset tarballs ;;
        other) packages=("${other_packages[@]}") ;;
    esac
    mkdir -p "${working_dir}/${type}"
    cd "${working_dir}/${type}"
    rm -f MISSING.txt

    for package_name in "${packages[@]}"; do
        package="mingw-w64-${architecture}-${package_name}"
        package_version=$(pacman -Q $package)
        package_version="${package_version##* }"
        package_source_suffix="${package_name}-${package_version}.src.tar.gz"
        package_source="mingw-w64-${package_source_suffix}"
        url="https://sourceforge.net/projects/msys2/files/REPOS/MINGW/Sources/mingw-w64-i686-${package_source_suffix}/download"
        echo "Integrating ${package_source}"
        [[ -s "$package_source" ]] && continue || rm -f "$package_source"
        if ! wget "$url" --quiet --output-document "$package_source"; then
            warn "failed downloading ${package_source}"
            echo "${package_source}" >> MISSING.txt
            rm "$package_source"
        fi
    done

    for tarball in "${tarballs[@]}"; do
        url="${tarball#*:}"
        tarball="${tarball%%:*}"
        echo "Integrating ${tarball}"
        [[ -s "$tarball" ]] && continue || rm -f "$tarball"
        if ! wget "$url" --quiet --output-document "$tarball"; then
            warn "failed downloading ${tarball}"
            echo "${tarball}" >> MISSING.txt
            rm "$tarball"
        fi
    done
    echo "Creating $zip_file"
    zip -9 -qr "${pidgin_base}/${zip_file}" .
    echo
}

library_bundle GTK+  "$zip_file_gtk"
library_bundle other "$zip_file_other"

echo "Creating ${zip_file_main}"
bzr export --uncommitted --directory "$bazaar_branch" --root "$zip_root_main" "${pidgin_base}/${zip_file_main}"
