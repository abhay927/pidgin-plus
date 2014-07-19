#!/bin/bash

##
##     Pidgin++ Translations Merge Helper
##     Copyright (c) 2014 Renato Silva
##     GNU GPLv2 licensed
##
## This script merges translations from Launchpad, performing adjustments in
## order to circumvent some Launchpad limitations.
##
## Usage: @script.name OPTIONS
##
##     -m, --merge        Perform the merge.
##         --from=BRANCH  Alternative branch to merge with.
##

eval "$(from="$0" easyoptions.rb "$@" || echo exit 1)"

if [[ -n "$merge" ]]; then
    bzr merge "${from:-lp:~renatosilva/pidgin++/translation}" || exit 1
    cp -v source/po/ms.po source/po/ms_MY.po
    cp -v source/po/my.po source/po/my_MM.po

    bzr remove source/po/ms.po
    bzr remove source/po/my.po
    bzr remove source/po/ab.po

    rm -v source/po/ms.po.~*~
    rm -v source/po/my.po.~*~
    rm -v source/po/ab.po.~*~
fi
