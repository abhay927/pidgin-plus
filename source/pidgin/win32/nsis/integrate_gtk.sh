#!/bin/bash

##
##     Pidgin++ Windows Installer GTK+ Integrator
##     Copyright (c) 2014, 2015 Renato Silva
##     Licensed under GNU GPLv2 or later
##
## Usage:
##     @script.name [options] PIDGIN_BASE BITNESS
##
## Options:
##     --gtk-version  Prints the GTK+ version and exit.
##

source easyoptions || exit
architecture=$(gcc -dumpmachine)
architecture="${architecture%%-*}"
gtk_package_version=$(pacman -Q mingw-w64-${architecture}-gtk2)
gtk_package_version="${gtk_package_version##* }"
gtk_package_version="${gtk_package_version/-/.}"

if [[ -n "$gtk_version" ]]; then
    echo "$gtk_package_version"
    exit
fi

bitness="${arguments[1]}"
if [[ -z "$bitness" ]]; then
    echo "Missing argument, see --help for usage and options."
    exit 1
fi

pidgin_base=$(readlink -f "${arguments[0]}")
install_dir="${pidgin_base}/pidgin/win32/nsis/Gtk"
rm -rf "$install_dir"
mkdir "$install_dir"
cd "$install_dir"

# Main files
files=(bin/gspawn-win${bitness}-helper.exe
       bin/gspawn-win${bitness}-helper-console.exe
       bin/gtk-update-icon-cache.exe
       bin/libatk-1.0-0.dll
       bin/libbz2-1.dll
       bin/libcairo-2.dll
       bin/libexpat-1.dll
       bin/libffi-6.dll
       bin/libfontconfig-1.dll
       bin/libfreetype-6.dll
       bin/libgdk_pixbuf-2.0-0.dll
       bin/libgdk-win32-2.0-0.dll
       bin/libgio-2.0-0.dll
       bin/libglib-2.0-0.dll
       bin/libgmodule-2.0-0.dll
       bin/libgobject-2.0-0.dll
       bin/libgthread-2.0-0.dll
       bin/libgtk-win32-2.0-0.dll
       bin/libharfbuzz-0.dll
       bin/libiconv-2.dll
       bin/libintl-8.dll
       bin/libpango-1.0-0.dll
       bin/libpangocairo-1.0-0.dll
       bin/libpangoft2-1.0-0.dll
       bin/libpangowin32-1.0-0.dll
       bin/libpcre-1.dll
       bin/libpixman-1-0.dll
       bin/libpng16-16.dll
       bin/libwinpthread-1.dll
       bin/zlib1.dll
       etc/fonts
       etc/gtk-2.0
       lib/gtk-2.0/2.10.0/engines/libpixmap.dll
       lib/gtk-2.0/2.10.0/engines/libwimp.dll
       lib/gtk-2.0/modules/libgail.dll
       share/fontconfig
       share/mime
       share/themes
       share/xml/fontconfig)

# Exception handling
case "$bitness" in
    32) files+=(bin/libgcc_s_dw2-1.dll) ;;
    64) files+=(bin/libgcc_s_seh-1.dll) ;;
esac

# Integrate main files
for file in "${files[@]}"; do
    mkdir -p "${file%/*}"
    echo "Integrating ${file}"
    cp -r /mingw${bitness}/${file} $file
done
echo

# Integrate locales
for locale_dir in /mingw${bitness}/share/locale/*; do
    locale=$(basename "$locale_dir")
    [[ ! -d "$locale_dir" ]] && continue
    [[ ! -f "${pidgin_base}/po/${locale}.po" ]] && continue
    echo "Integrating language ${locale}"
    mkdir -p share/locale/${locale}/LC_MESSAGES
    for module in atk10 gdk-pixbuf gettext-runtime gettext-tools glib20 gtk20 gtk20-properties libiconv shared-mime-info; do
        file=share/locale/${locale}/LC_MESSAGES/${module}.mo
        [[ -f /mingw${bitness}/${file} ]] && cp /mingw${bitness}/${file} $file
    done
done
echo

# GTK+ customizations and version information
cp -vr "$pidgin_base/pidgin/win32/gtk"/* .
echo "Bundle Version ${gtk_package_version}" > CONTENTS
