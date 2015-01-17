#!/bin/bash

# Pidgin++ Source Bundle Generator
# Copyright (C) 2014 Renato Silva
#
# This script generates the source code bundle for Pidgin++, including the
# sources for the MSYS2 libraries used, except for GTK+ which uses a separate
# source code bundle.

bazaar_branch="$3"
display_version="$2"
pidgin_base=$(readlink -f "$1")
architecture=$(gcc -dumpmachine)
architecture="${architecture%%-*}"
zip_root="pidgin++_${display_version}"
zip_file="${zip_root}_source.zip"
library_dir="${zip_root}/libraries"
working_dir="${pidgin_base}/pidgin/win32/source_bundle_stage"
source "$pidgin_base/colored.sh"

tarballs=(winsparkle-0.4.tar.gz:"https://github.com/vslavik/winsparkle/archive/v0.4.tar.gz")
packages=(cyrus-sasl
          drmingw
          enchant
          gcc
          gtkspell
          hunspell
          libgnurx
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
    package_source="mingw-w64-i686-${package_name}-${package_version}.src.tar.gz"
    url="https://sourceforge.net/projects/msys2/files/REPOS/MINGW/Sources/${package_source}/download"
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

cd "$working_dir"
echo "Creating $zip_file"
bzr export --uncommitted --directory "$bazaar_branch" --root "${zip_root}" "${pidgin_base}/${zip_file}"
zip -9 -qr "${pidgin_base}/${zip_file}" "$library_dir"
