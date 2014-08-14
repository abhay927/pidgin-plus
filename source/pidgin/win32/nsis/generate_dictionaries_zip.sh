#!/bin/bash

# Dictionaries Bundle Creator/Downloader
# Copyright (C) 2014 Renato Silva
#
# This script downloads the dictionaries to be included with the offline
# installer. When provided with the --create flag, it generates the dictionaries
# bundle for upload instead.

pidgin_base="$1"
pidgin_version="$2"
[[ "$3" = --create ]] && create="yes"
working_dir="$pidgin_base/pidgin/win32/nsis"
staging_dir="$working_dir/dictionaries"
zip_file="$working_dir/dictionaries.zip"
rm -rf "$staging_dir/unpacked"
mkdir -p "$staging_dir/unpacked"

echo
echo "Downloading dictionaries..."
echo

if [[ -z "$create" ]]; then
    wget -nc "https://launchpad.net/pidgin++/trunk/2.10.9-rs226/+download/Pidgin Dictionaries.zip" -O "$zip_file"
    zip_sha1sum_expected="719e3614ca9562ba8f77e70618f45ccc1d0d1579"
    zip_sha1sum=$(sha1sum "$zip_file")
    zip_sha1sum="${zip_sha1sum%%\ *}"
    if [[ "$zip_sha1sum" != "$zip_sha1sum_expected" ]]; then
        echo -e "The sha1sum check failed for $zip_file.
        expected: $zip_sha1sum_expected
        obtained: $zip_sha1sum"
        exit 1
    fi
    unzip -qo "$zip_file" -d "$staging_dir/unpacked"
else
    mkdir -p "$staging_dir/download"
    while IFS= read -r line; do
        [[ "$line" = "#"* || "$line" != *,* ]] && continue
        lang_file="${line##*,}"
        lang_code="${line#*,*,}"
        lang_code="${lang_code%%,*}"
        output_file="$staging_dir/download/$lang_file"
        try=1
        while [[ ! -s "$output_file" && "$try" -lt 10 ]]; do
            wget -nc "https://pidgin.im/win32/download_redir.php?version=${pidgin_version}&dl_pkg=oo_dict&lang=${lang_file}&lang_file=${lang_file}" -O "$output_file"
            [[ ! -s "$output_file" ]] && rm "$output_file"
            try=$((try + 1))
        done
        [[ -e "$output_file" ]] && unzip -qo "$output_file" -d "$staging_dir/unpacked/$lang_code"
    done < "$working_dir/available.lst"
    cd "$staging_dir/unpacked"
    rm -f "$zip_file"
    zip -9 -r "$zip_file" .
    cd - > /dev/null
fi
