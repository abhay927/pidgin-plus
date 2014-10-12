#!/bin/bash

# This script selects the appropriate SSP DLL for inclusion in the Windows
# installation. This is for fixing a crash on exit caused by the SSP shipped
# with GCC 4.9.1 in MSYS2.

gcc_top="$1"
target="$2"
gcc_version=$(gcc -dumpversion)
gcc_micro_version="${gcc_version##*.}"
script_dir=$(readlink -e "$(dirname "$0")")
source "$script_dir/colored.sh"

# If system is MSYS2 and the GCC version is greater than 4.9.0, then stick to
# the SSP used in that version until a newer GCC is known to have been fixed.

if [[ $(uname -or) = 2.*Msys && "$gcc_version" = 4.9.* && "$gcc_micro_version" -gt 0 ]]; then
    package="mingw-w64-i686-gcc-libs-4.9.0-4-any.pkg.tar.xz"
    url="http://sourceforge.net/projects/msys2/files/REPOS/MINGW/i686/$package/download"
    echo "Downloading $url"
    wget --quiet -O "$package" "$url"

    echo "Extracting $package"
    tar --xz -xf "$package" mingw32/bin/libssp-0.dll --strip-components 2
    rm "$package"
    mv -v "libssp-0.dll" "$target"
    exit
fi

# Otherwise, use whatever is shipped with current GCC
cp -v "$gcc_top/libssp-0.dll" "$target"
