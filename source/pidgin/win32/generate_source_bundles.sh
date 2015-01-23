#!/bin/bash

# Pidgin++ Source Bundles Generator
# Copyright (C) 2014 Renato Silva
#
# This script generates the source code bundles for Pidgin++ and used libraries,
# except for GTK+ which uses a separate source code bundle.

bazaar_branch="$3"
display_version="$2"
pidgin_base=$(readlink -f "$1")
architecture=$(gcc -dumpmachine)
architecture="${architecture%%-*}"
zip_root_main="pidgin++_${display_version}"
zip_file_main="${zip_root_main}_source_main.zip"
zip_file_libs="${zip_root_main}_source_libs.zip"
library_dir="${zip_root_main}/libraries"
working_dir="${pidgin_base}/pidgin/win32/source_bundle_stage"
source "$pidgin_base/colored.sh"

tarballs=(winsparkle-0.4.tar.gz:"https://github.com/vslavik/winsparkle/archive/v0.4.tar.gz")
packages=(cyrus-sasl
          drmingw
          enchant
          gcc
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
          winpthreads-git)

mkdir -p "${working_dir}/${library_dir}"
cd "${working_dir}/${library_dir}"
rm -f MISSING.txt

for package_name in "${packages[@]}"; do
    package="mingw-w64-${architecture}-${package_name}"
    package_version=$(pacman -Q $package)
    package_version="${package_version##* }"
    package_source_suffix="${package_name}-${package_version}.src.tar.gz"
    package_source="mingw-w64-${package_source_suffix}"
    url="https://sourceforge.net/projects/msys2/files/REPOS/MINGW/Sources/mingw-w64-i686-${package_source_suffix}/download"
    echo "Integrating ${package} ${package_version}"
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

echo "Creating $zip_file_main"; bzr export --uncommitted --directory "$bazaar_branch" --root "${zip_root_main}" "${pidgin_base}/${zip_file_main}"
echo "Creating $zip_file_libs"; zip -9 -qr "${pidgin_base}/${zip_file_libs}" .
