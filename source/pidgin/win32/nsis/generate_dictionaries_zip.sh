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
source "$pidgin_base/colored.sh"

working_dir="$pidgin_base/pidgin/win32/nsis"
staging_dir="$working_dir/dictionaries"
zip_file="$working_dir/dictionaries.zip"
rm -rf "$staging_dir/unpacked"
mkdir -p "$staging_dir/unpacked"

if [[ -z "$create" ]]; then
    if [[ ! -e "$zip_file" ]]; then
        url="https://launchpad.net/pidgin++/trunk/2.10.9-rs243/+download/Pidgin Dictionaries.zip"
        echo "Downloading $url"
        wget --quiet -O "$zip_file" "$url"
    fi
    zip_sha1sum_expected="719e3614ca9562ba8f77e70618f45ccc1d0d1579"
    zip_sha1sum=$(sha1sum "$zip_file")
    zip_sha1sum="${zip_sha1sum%%\ *}"
    if [[ "$zip_sha1sum" != "$zip_sha1sum_expected" ]]; then
        oops "the sha1sum check failed for ${zip_file}\nexpected: ${zip_sha1sum_expected}$2\nobtained: ${zip_sha1sum}"
        echo
        exit 1
    fi
    echo "Extracting $zip_file"
    unzip -qo "$zip_file" -d "$staging_dir/unpacked"
else
    printf "Downloading dictionaries...\n\n"
    mkdir -p "$staging_dir/download"
    while IFS= read -r line; do
        [[ "$line" = "#"* || "$line" != *,* ]] && continue
        lang_file="${line##*,}"
        lang_code="${line#*,*,}"
        lang_code="${lang_code%%,*}"
        #lang_name="${line#*,*,*,}"
        #lang_name="${lang_name%%,*}"
        output_file="$staging_dir/download/$lang_file"
        printf "${purple}%-20s${normal} " "${lang_code}:"
        try=1
        while [[ ! -s "$output_file" && "$try" -lt 10 ]]; do
            url="https://pidgin.im/win32/download_redir.php?version=${pidgin_version}&dl_pkg=oo_dict&lang=${lang_file}&lang_file=${lang_file}"
            wget --quiet --output-document "$output_file" "$url"
            [[ ! -s "$output_file" ]] && rm "$output_file"
            try=$((try + 1))
        done
        if [[ -e "$output_file" ]]; then
            target="$staging_dir/unpacked/$lang_code"
            if unzip -qo "$output_file" -d "$target" 2> /dev/null; then
                printf "downloaded and extracted to $target"
            else
                oops "failed extracting $output_file"
                exit 1
            fi
        else
            oops "failed downloading from $url"
            exit 1
        fi
        echo
    done < "$working_dir/available.lst"
    echo
    cd "$staging_dir/unpacked"
    rm -f "$zip_file"
    echo "Generating compressed file"
    zip -9 -qr "$zip_file" . && echo "Created $zip_file" || oops "failed creating $zip_file"
    exit 0
fi
