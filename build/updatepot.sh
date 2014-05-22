#!/bin/bash

if [[ -z "$1" ]]; then
    echo "Usage: $(basename "$0") DEVELOPMENT_ROOT"
    exit
fi

cd ../source/po
intltool_home=$(readlink -e "$1/win32-dev/intltool_"*)
PATH="$PATH:$intltool_home/bin" XGETTEXT_ARGS=--no-location intltool-update --pot
