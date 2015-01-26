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
source "${pidgin_base}/pidgin/win32/libraries.sh"
source "${pidgin_base}/colored.sh"

library_bundle() {
    local packages
    local type="$1"
    local zip_file="$2"
    case "$type" in
        GTK+)  packages=("${gtk_packages[@]}")
               unset tarballs
               ;;
        other) packages=("${other_packages[@]}")
               packages+=("${common_packages[@]}")
               ;;
    esac
    mkdir -p "${working_dir}/${type}"
    cd "${working_dir}/${type}"
    rm -f MISSING.txt

    for package in "${packages[@]}"; do
        local name=$(package_name $package)
        local source_suffix="$(package_source $package)-$(package_version $name).src.tar.gz"
        local source_package="mingw-w64-${source_suffix}"
        local source_url="https://sourceforge.net/projects/msys2/files/REPOS/MINGW/Sources/mingw-w64-i686-${source_suffix}/download"
        echo "Integrating ${source_package}"
        [[ -s "$source_package" ]] && continue || rm -f "$source_package"
        if ! wget "$source_url" --quiet --output-document "$source_package"; then
            warn "failed downloading ${source_package}"
            echo "${source_package}" >> MISSING.txt
            rm "$source_package"
        fi
    done

    for tarball in "${tarballs[@]}"; do
        local source_file=$(tarball_source_filename "$tarball")
        local source_url=$(tarball_source_url "$tarball")
        echo "Integrating ${source_file}"
        [[ -s "$source_file" ]] && continue || rm -f "$source_file"
        if ! wget "$source_url" --quiet --output-document "$source_file"; then
            warn "failed downloading ${source_file}"
            echo "${source_file}" >> MISSING.txt
            rm "$source_file"
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
