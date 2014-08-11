#!/bin/bash

# This script selects the appropriate SSP DLL for inclusion in the Windows
# installation. This is for fixing a crash on exit caused by the SSP shipped
# with GCC 4.9.1 in MSYS2.

gcc_top="$1"
target="$2"

case $(uname -or) in
    1.*Msys)
        # Use whatever is shipped with current GCC
        cp "$gcc_top/libssp-0.dll" "$target" ;;

    2.*Msys)
        # If GCC version is greater than 4.9.0, then stick to the SSP used in
        # that version until a newer GCC is known to have fixed the problem.

        gcc_version=$(gcc -dumpversion)
        gcc_minor_version="${gcc_version##*.}"

        if [[ $gcc_version = 4.9.* && $gcc_minor_version -gt 0 ]]; then
            architecture=$(uname -m)
            case $architecture in
                  i686) bitness=32 ;;
                x86_64) bitness=64 ;;
            esac
            package="mingw-w64-${architecture}-gcc-libs-4.9.0-4-any.pkg.tar.xz"
            wget -O "$package" "http://sourceforge.net/projects/msys2/files/REPOS/MINGW/${architecture}/$package/download"
            tar --xz -xvf "$package" mingw${bitness}/bin/libssp-0.dll --strip-components 2
            rm "$package"
            mv -v "libssp-0.dll" "$target"
        fi ;;
esac
