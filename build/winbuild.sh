#!/bin/bash

if [[ -z "$1" ]]; then
    echo "Usage: $(basename "$0") DEVELOPMENT_ROOT [--reset]"
    exit
fi

devroot="$1"
pidgin="$devroot/pidgin.build"
[[ "$2" = "--reset" ]] && rm -rf "$pidgin"
mkdir -p "$pidgin"
cp -r ../source/* "$pidgin"
changelog.sh && mv -v changelog.html "$pidgin/CHANGES.html"
eval $(../../windev/pidgin-windev.sh "$devroot" --path)
cd "$pidgin"

make -f Makefile.mingw installer
mv -v pidgin-*.exe "$devroot/Pidgin $(cat VERSION) Setup.exe"
make -f Makefile.mingw uninstall
rm -fv *.zip
cd -
