#!/bin/bash

##
##     Pidgin++ Windows Builder
##     Copyright (c) 2014 Renato Silva
##     GNU GPLv2 licensed
##
## This is the builder script for Pidgin++ on Windows. Source code will be
## exported to an appropriate staging directory "pidgin.build" within the
## specified development root. After compilation the installer will have been
## generated alongside the staging directory.
##
## Usage:
##     @script.name DEVELOPMENT_ROOT [options]
##
##     -r, --reset  Recreates the staging directory from scratch.
##

eval "$(from="$0" easyoptions.rb "$@"; echo result=$?)"
[[ ! -d "${arguments[0]}" && $result  = 0 ]] && echo "No valid development root specified, see --help."
[[ ! -d "${arguments[0]}" || $result != 0 ]] && exit

devroot="${arguments[0]}"
pidgin="$devroot/pidgin.build"
[[ -n "$reset" ]] && rm -rf "$pidgin"
mkdir -p "$pidgin"
cp -r ../source/* "$pidgin"
changelog.sh --html && mv -v changelog.html "$pidgin/CHANGES.html"
eval $(../../windev/pidgin-windev.sh "$devroot" --path)
cd "$pidgin"

make -f Makefile.mingw installer
mv -v pidgin-*.exe "$devroot/Pidgin $(cat VERSION) Setup.exe"
make -f Makefile.mingw uninstall
rm -fv *.zip
cd -
