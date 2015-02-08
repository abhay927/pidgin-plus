#!/bin/bash

# Pidgin++ Library Information
# Copyright (C) 2015 Renato Silva
# GNU GPLv2 licensed

# Package format: binary[::source]
# Tarball format: name::version::source_format::source_url

# Required only by GTK+
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
common_packages=(gcc-libs::gcc
                 libwinpthread-git::winpthreads-git)

# Non-packaged dependencies
tarballs=(winsparkle::0.4::tar.gz::"https://github.com/vslavik/winsparkle/archive/v0.4.tar.gz")

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
