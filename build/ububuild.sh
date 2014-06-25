#!/bin/bash

# Pidgin++ Ubuntu Build helper
# Copyright (c) 2014 Renato Silva
# GNU GPLv2 licensed

if [[ ("$2" != "--prepare" && "$2" != "--build" && "$2" != "--upload" && "$2" != "--import") ||
    "$0" == "$BASH_SOURCE" ]]; then
    echo "Usage: source $BASH_SOURCE BUILD_ROOT OPTION
    --prepare           Prepare for building the Ubuntu package.
    --build             Build the source package.
    --upload [TARGET]   Upload the source package to the PPA at
                        ppa:<launchpad-user>/TARGET. TARGET defaults to main.
    --import            Import modified debian and quilt directories back into this
                        branch for further committing."
    [[ "$0" == "$BASH_SOURCE" ]] && exit
    return
fi

if [[ $(lsb_release --id --short 2> /dev/null) != "Ubuntu" ]]; then
    echo "This script should be run in Ubuntu."
    return 1
fi

build_dir="$1/pidgin-$(./changelog.sh --upstream-version)"

# Build the source package
if [[ "$2" = "--build" ]]; then
    cd "$build_dir"
    origtargz --download-only --tar-only
    debuild -S -sd
    cd - > /dev/null
    return
fi

# Upload to PPA
if [[ "$2" = "--upload" ]]; then
    source_changes="../pidgin_$(./changelog.sh --package-version)_source.changes"
    cd "$build_dir"
    dput "ppa:$(bzr launchpad-login)/${3:-main}" "$source_changes"
    cd - > /dev/null
    return
fi

# Import changes into branch
if [[ "$2" = "--import" ]]; then
    rm -rf ../ubuntu/*
    cp -vr "$build_dir/debian" ../ubuntu
    cp -vr "$build_dir/.pc" ../ubuntu
    mv ../ubuntu/.pc ../ubuntu/quilt
    return
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
echo "Creating ${build_dir##*/}...";  bzr export "$build_dir" ../source
echo "Creating debian directory...";  bzr export "$build_dir/debian" ../ubuntu/debian
echo "Creating quilt directory...";   bzr export "$build_dir/.pc" ../ubuntu/quilt
export QUILT_PATCHES=debian/patches

# Fix for UDD, see https://bugs.launchpad.net/bzr/+bug/888615
alias bzr="bzr -Olaunchpad.packaging_verbosity=off"
