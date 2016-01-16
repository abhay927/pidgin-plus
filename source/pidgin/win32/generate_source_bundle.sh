#!/bin/bash

# Pidgin++ Source Bundles Generator
# Copyright (C) 2014-2016 Renato Silva
# Licensed under GNU GPLv2 or later

test -z "$3" && exit 1
bazaar_branch="$3"
display_version="$2"
pidgin_base=$(readlink -f "$1")
library_dir='libraries/windows'
zip_file="pidgin++_${display_version}_source.zip"
working_dir="${pidgin_base}/pidgin/win32/source_bundle_stage"
source "${pidgin_base}/pidgin/win32/dependencies.sh"
source "${pidgin_base}/colored.sh"

mkdir -p "${working_dir}/${library_dir}"
cd "${working_dir}/${library_dir}"
rm -f MISSING.txt

for package in "${packages[@]}"; do
    package_name=$(package_name ${package})
    package_version=$(package_version ${package_name})
    source_name=$(package_source ${package})
    source_package="${source_name}-${package_version}.src.tar.gz"
    source_package_simple="${source_package/-${package_architecture}/}"
    echo "Integrating ${source_package_simple}"
    for file in "${source_name}"*src.tar.gz "${source_name/-${package_architecture}/}"*src.tar.gz; do
        [[ "${file}" = "${source_package}"        && -s "${file}" ]] && continue
        [[ "${file}" = "${source_package_simple}" && -s "${file}" ]] && continue
        rm -f "${file}"
    done
    [[ -s "${source_package}"        ]] && continue
    [[ -s "${source_package_simple}" ]] && continue
    if ! wget --quiet "http://repo.msys2.org/mingw/sources/${source_package}" &&
       ! wget --quiet "http://repo.msys2.org/mingw/sources/${source_package_simple}"; then
        warn "failed downloading ${source_package}"
        echo "${source_package}" >> MISSING.txt
        rm -f "${source_package}"
    fi
done

echo "Creating ${zip_file}"
cd "${working_dir}"
bzr export --root= --uncommitted --directory "${bazaar_branch}" "${pidgin_base}/${zip_file}"
zip -9 -qr "${pidgin_base}/${zip_file}" "${library_dir}"
