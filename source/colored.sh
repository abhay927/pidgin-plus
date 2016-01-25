#!/bin/bash

# Pidgin++ Colored Output Helper
# Copyright (c) 2014 Renato Silva
# Licensed under GNU GPLv2 or later

if [[ -n "$PIDGIN_BUILD_COLORS" ]]; then
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
