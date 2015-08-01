#!/bin/bash

# Pidgin++ Source Bundles Generator
# Copyright (C) 2014, 2015 Renato Silva
# Licensed under GNU GPLv2 or later

bazaar_branch="$3"
display_version="$2"
pidgin_base=$(readlink -f "$1")
zip_root_main="pidgin++_${display_version}"
zip_file_main="${zip_root_main}_source_main.zip"
zip_file_lib1="${zip_root_main}_source_lib1.zip"
zip_file_lib2="${zip_root_main}_source_lib2.zip"
working_dir="${pidgin_base}/pidgin/win32/source_bundle_stage"
source "${pidgin_base}/pidgin/win32/dependencies.sh"
source "${pidgin_base}/colored.sh"

library_bundle() {
    local type="$1"
    local zip_file="$2"
    mkdir -p "${working_dir}/${type}"
    cd "${working_dir}/${type}"
    rm -f MISSING.txt

    for package in "${packages[@]}"; do
        [[   "$package" =~ mingw-w64.*gcc|mingw-w64.*libwinpthread && "$type" = lib1 ]] && continue
        [[ ! "$package" =~ mingw-w64.*gcc|mingw-w64.*libwinpthread && "$type" = lib2 ]] && continue
        local name=$(package_name $package)
        local version=$(package_version $name)
        local source_name=$(package_source $package)
        local source_package="${source_name}-${version}.src.tar.gz"
        echo "Integrating ${source_package}"
        for file in "${source_name}"*src.tar.gz; do
            [[ "${file}" = "${source_package}" && -s "${file}" ]] && continue
            rm -f "${file}"
        done
        [[ -s "$source_package" ]] && continue
        if ! wget --quiet "http://repo.msys2.org/mingw/sources/${source_package}"; then
            warn "failed downloading ${source_package}"
            echo "${source_package}" >> MISSING.txt
            rm "$source_package"
        fi
    done
    echo "Creating $zip_file"
    zip -9 -qr "${pidgin_base}/${zip_file}" .
    echo
}

library_bundle lib1 "$zip_file_lib1"
library_bundle lib2 "$zip_file_lib2"

echo "Creating ${zip_file_main}"
bzr export --uncommitted --directory "$bazaar_branch" --root "$zip_root_main" "${pidgin_base}/${zip_file_main}"
