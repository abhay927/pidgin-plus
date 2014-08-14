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
source="$(dirname "$0")/../source"

if [[ -n "$merge" ]]; then
    bzr merge "${from:-lp:~renatosilva/pidgin++/translation}"
    [[ $? = 3 ]] && exit # Not a branch
    bzr remove "$source/po/ab.po"
    rm -v "$source/po/ab.po.~"*"~"
fi
