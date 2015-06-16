#!/bin/bash

##
##     Pidgin++ Translations Helper
##     Copyright (c) 2014, 2015 Renato Silva
##     Licensed under GNU GPLv2 or later
##
## Usage: @script.name OPTIONS
##
##     -u, --update       Update the translations template.
##     -m, --merge        Merge translations from Launchpad.
##         --from=BRANCH  Alternative branch to merge with.
##

source easyoptions || exit
source="$(dirname "$0")/../source"

if [[ -n "$update" ]]; then
    cd "$source/po"
    echo 'Updating the translation template'
    XGETTEXT_ARGS='--no-location --sort-output' intltool-update --pot
fi

if [[ -n "$merge" ]]; then
    bzr merge "${from:-lp:~renatosilva/pidgin++/translation}"
    [[ $? = 3 ]] && exit # Not a branch
    bzr resolve "$source/po/ab.po"
    bzr resolve "$source/po/ms.po"
    bzr resolve "$source/po/my.po"
fi
