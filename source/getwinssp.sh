#!/bin/bash

# This script selects the appropriate SSP DLL for inclusion in the Windows
# installation. This is for fixing a crash on exit caused by the SSP shipped
# with GCC 4.9.1 in MSYS2.

gcc_top="$1"
target="$2"
system=$(uname -or)
gcc_version=$(gcc -dumpversion)
gcc_micro_version="${gcc_version##*.}"
script_dir=$(readlink -e "$(dirname "$0")")
source "$script_dir/colored.sh"

case "$system" in
    1.*Msys) echo "Using GCC $gcc_version under MinGW MSYS" ;;
    2.*Msys) echo "Using GCC $gcc_version under MSYS2" ;;
esac

# If system is MSYS2 and the GCC version is greater than 4.9.0, then stick to
# the SSP used in that version until a newer GCC is known to have been fixed.

if [[ "$system" = 2.*Msys && "$gcc_version" = 4.9.* && "$gcc_micro_version" -gt 0 ]]; then
    architecture=$(uname -m)
    case $architecture in
          i686) bitness=32 ;;
        x86_64) bitness=64 ;;
    esac

    package="mingw-w64-${architecture}-gcc-libs-4.9.0-4-any.pkg.tar.xz"
    url="http://sourceforge.net/projects/msys2/files/REPOS/MINGW/${architecture}/$package/download"
    echo "Downloading $url"
    wget --quiet -O "$package" "$url"

    echo "Extracting $package"
    tar --xz -xf "$package" mingw${bitness}/bin/libssp-0.dll --strip-components 2
    rm "$package"
    mv -v "libssp-0.dll" "$target"
    exit
fi

# Otherwise, use whatever is shipped with current GCC
cp -v "$gcc_top/libssp-0.dll" "$target"
