#!/bin/bash

##
##     Pidgin++ SignCode Helper
##     Copyright (c) 2014 Renato Silva
##     GNU GPLv2 licensed
##
## This script converts a PEM certificate and private key into the SPC and PVK
## formats required by the Mono SignCode utility in order to sign code with the
## Microsoft Authenticode.
##
## Usage: @script.name OPTIONS
##
##     --certificate=FILE  Certificate file in PEM format.
##     --key=FILE          Private key in PEM format.
##

eval "$(from="$0" easyoptions.rb "$@" || echo exit 1)"
if [[ -f "$certificate" && -f "$key" ]]; then
    openssl rsa -in "$key" -outform PVK -pvk-strong -out "${key%.*}.pvk"
    openssl crl2pkcs7 -nocrl -certfile "$certificate" -outform DER -out "${certificate%.*}.spc"
    exit
fi
echo "A valid certificate and private key files must be specified, see --help."
