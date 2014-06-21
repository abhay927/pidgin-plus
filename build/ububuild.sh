#!/bin/bash

# Pidgin++ Ubuntu Build helper
# Copyright (c) 2014 Renato Silva
# GNU GPLv2 licensed

if [[ "$0" == "$BASH_SOURCE" || ("$2" != "--prepare" && "$2" != "--import") ]]; then
    echo "Usage: source $BASH_SOURCE BUILD_ROOT OPTION
    --prepare  Prepare for building the Ubuntu package. Currently the package
               should be built manually.
    --import   Import modified debian and quilt directories back into this
               branch for further committing."
    [[ "$0" == "$BASH_SOURCE" ]] && exit
    return
fi

if [[ $(lsb_release --id --short 2> /dev/null) != "Ubuntu" ]]; then
    echo "This script should be run in Ubuntu."
    return 1
fi

upstream_version=$(apt-cache show pidgin | grep -m 1 Version | awk -F'[:-]' '{ print $3 }')
build_dir="$1/pidgin-$upstream_version"

# Import changes into branch
if [[ "$2" = "--import" ]]; then
    rm -rf ../ubuntu/*
    cp -vr "$build_dir/debian" ../ubuntu
    cp -vr "$build_dir/.pc" ../ubuntu
    mv ../ubuntu/.pc ../ubuntu/quilt
    return 1
fi

# Set name and email address
if [[ -z "$DEBFULLNAME" || -z "$DEBEMAIL" ]]; then
    whoami=$(bzr whoami 2> /dev/null | tr -d "(<|>)")
    DEBFULLNAME="${whoami%[[:space:]]*}"
    DEBEMAIL="${whoami##*[[:space:]]}"
fi
[[ -z "$DEBFULLNAME" ]] && read -p "What is your name? " DEBFULLNAME
[[ -z "$DEBEMAIL" ]] && read -p "What is your email address?" DEBEMAIL
export DEBEMAIL
export DEBFULLNAME

# Do what quilt likes
if [[ -e "$build_dir" ]]; then
    echo "Error: target build directory already exists: $build_dir."
    return 1
fi
echo "Creating ${build_dir##*/}...";  bzr export -r 1 "$build_dir" ..
echo "Creating debian directory...";  bzr export "$build_dir/debian" ../ubuntu/debian
echo "Creating quilt directory...";   bzr export "$build_dir/.pc" ../ubuntu/quilt
export QUILT_PATCHES=debian/patches

# Fix for UDD, see https://bugs.launchpad.net/bzr/+bug/888615
alias bzr="bzr -Olaunchpad.packaging_verbosity=off"
