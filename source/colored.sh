#!/bin/bash

# Pidgin++ Colored Output Helper
# Copyright (c) 2014 Renato Silva
# GNU GPLv2 licensed

if [[ -n "$PIDGIN_BUILD_COLORS" ]]; then

    # Which colors
    normal="\e[0m"
    if [[ "$MSYSCON" = mintty* && "$TERM" = *256color* ]]; then
        red="\e[38;05;9m"
        green="\e[38;05;76m"
        blue="\e[38;05;74m"
        cyan="\e[0;36m"
        purple="\e[38;05;165m"
        yellow="\e[0;33m"
        gray="\e[38;05;244m"
    else
        red="\e[1;31m"
        green="\e[1;32m"
        blue="\e[1;34m"
        cyan="\e[1;36m"
        purple="\e[1;35m"
        yellow="\e[1;33m"
        gray="\e[1;30m"
    fi

    # Errors, warnings and notes
    error="s/^(.*error:)/$(printf $red)\\1$(printf $normal)/i"
    warning="s/^(.*warning:)/$(printf $yellow)\\1$(printf $normal)/"
    make="s/^make(\[[0-9]+\])?:/$(printf $blue)make\\1:$(printf $normal)/"

    # Compiler recipes
    source_dir=$(readlink -f "$(dirname "$BASH_SOURCE")")
    compiler=$(grep "CC\\s*:=" "$source_dir/libpurple/win32/global.mak" | awk -F':=[[:space:]*]' '{print $2}')
    compiler_recipe="s/^($compiler .*)/\n$(printf $gray)\\1$(printf $normal)\n/"

    # Colored make
    colormake() {
        make "$@" \
            2> >(sed -E -e "$warning" -e "$error" -e "$make" -e "$compiler_recipe") \
            >  >(sed -E -e "$warning" -e "$error" -e "$make" -e "$compiler_recipe")
    }
fi

# Output functions
# pace [color] TEXT - First-level header
# step [color] TEXT - First-level header with leading line break
# info [color] TEXT - Second-level header with leading line break
# note [color] TEXT - Information with leading note indicator
# warn [color] TEXT - Information with leading warning indicator
# oops [color] TEXT - Information with leading error indicator

step() { printf "${2:+${!1}}${2:-${green}$1}${normal}\n"; }
pace() { printf "\n${2:+${!1}}${2:-${green}$1}${normal}\n"; }
info() { printf "\n${2:+${!1}}${2:-${purple}$1}${normal}\n"; }
note() { printf "${2:+${!1}Note:${normal} }${2:-${cyan}Note:${normal} $1}\n"; }
warn() { printf "${2:+${!1}Warning:${normal} }${2:-${yellow}Warning:${normal} $1}\n"; }
oops() { printf "${2:+${!1}Error:${normal} }${2:-${red}Error:${normal} $1}\n"; }

# Allow non-sourcing usage
[[ "$0" = "$BASH_SOURCE" && -n "$1" ]] && "$1" "${@:2}"
