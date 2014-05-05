#!/bin/bash

if [[ -z "$1" ]]; then
    echo "Usage: $(basename "$0") DEVELOPMENT_ROOT"
    exit
fi

devroot="$1"
pidgin="$devroot/pidgin.build"
[[ -e "$pidgin" ]] || bzr export --directory ../source "$pidgin"
changelog.sh && mv -v changelog.html "$pidgin/CHANGES.html"
eval $(../../windev/pidgin-windev.sh "$devroot" --path)
cd "$pidgin"

make -f Makefile.mingw installer
mv -v pidgin-*.exe "$devroot/Pidgin $(cat VERSION) Setup.exe"
make -f Makefile.mingw uninstall
rm -fv *.zip
cd -
