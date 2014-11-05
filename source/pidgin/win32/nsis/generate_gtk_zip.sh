#!/bin/bash

# This script generates the GTK+ runtime bundle to be included in the Windows
# installer, if not already built and uploaded, and if the application version
# is suffixed with "devel" or --force has been specified.

# GTK+ bundle version
architecture=$(gcc -dumpmachine)
architecture="${architecture%%-*}"
bundle_version=$(pacman -Q mingw-w64-${architecture}-gtk2)
bundle_version="${bundle_version##* }"
bundle_version="${bundle_version%-*}.R247"
if [[ "$1" = --gtk-version ]]; then
    echo "$bundle_version"
    exit
fi

# Arguments
force="$3"
bitness="$2"
pidgin_base="$1"
if [ ! -e "$pidgin_base/ChangeLog" ]; then
    oops "$(basename $0) must have the base directory specified as a parameter"
    exit 1
fi

# Configuration
install_dir="Gtk"
application_version=$(<$pidgin_base/VERSION)
stage_dir=$(readlink -f $pidgin_base/pidgin/win32/nsis/gtk_runtime_stage)
zip_file="$pidgin_base/pidgin/win32/nsis/gtk-runtime-$bundle_version.zip"
source "$pidgin_base/colored.sh"

# SHA-1 check
check_sha1sum() {
    local file_sha1sum=$(sha1sum "$1")
    local file_sha1sum="${file_sha1sum%%\ *}"
    local sha1sum_error="sha1sum check failed for $1\nexpected: $2\nobtained: $file_sha1sum"
    if [[ "$file_sha1sum" != "$2" ]]; then
        if [[ "$3" = quit ]]; then
            oops "the $sha1sum_error"
            exit 1
        fi
        printf "The $sha1sum_error\n"
        return 1
    fi
    return 0
}

# Expected SHA-1 hash
case "$bitness" in
    32) architecture_short=x86; bundle_sha1sum=e05684c45301a0e5c2fd328dbf1a19846a0f8190 ;;
    64) architecture_short=x64; bundle_sha1sum=15c4c55d711285a4c3e415b7e84b5ec15202e3c7 ;;
esac

# Try downloading first
if [ ! -e "$zip_file" ]; then
    url="https://launchpad.net/pidgin++/trunk/14.1/+download/Pidgin++ ${architecture_short} GTK+ Runtime ${bundle_version}.zip"
    echo "Downloading $url"
    wget --quiet "$url" --output-document "$zip_file"
fi

# If the sha1sum check succeeds, then extract and quit
# If the sha1sum check fails and not forcing, then quit
# If the sha1sum check fails and forcing, then continue bundle creation

[[ "$application_version" == *"devel" || -n "$force" ]] && force="yes"
if ! check_sha1sum "$zip_file" "$bundle_sha1sum" ${force:-quit}; then
    echo "Continuing GTK+ Bundle creation for Pidgin++ ${application_version}${force:+ (--force has been specified)}"
else
    echo "Extracting $zip_file"
    cd "$pidgin_base/pidgin/win32/nsis"
    unzip -qo "$zip_file"
    exit
fi

# Prepare
mkdir -p "$stage_dir"
rm -rf "$stage_dir/$install_dir"
mkdir "$stage_dir/$install_dir"
cd "$stage_dir/$install_dir"

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
       bin/libpixman-1-0.dll
       bin/libpng16-16.dll
       bin/libwinpthread-1.dll
       bin/zlib1.dll
       etc/fonts
       etc/gtk-2.0
       etc/pango
       lib/gtk-2.0/2.10.0/engines/libpixmap.dll
       lib/gtk-2.0/2.10.0/engines/libwimp.dll
       lib/gtk-2.0/modules/libgail.dll
       share/fontconfig
       share/licenses/libpng
       share/mime
       share/themes
       share/xml/fontconfig)

# Exception handling
case "$bitness" in
32) files+=(bin/libgcc_s_dw2-1.dll) ;;
64) files+=(bin/libgcc_s_seh-1.dll) ;;
esac

# Install main files
info "Installing main files"
for file in "${files[@]}"; do
    mkdir -p "${file%/*}"
    echo "Installing ${file}"
    cp -r {/mingw${bitness}/,}$file
done

# Install locales
info "Installing locales"
for locale_dir in /mingw${bitness}/share/locale/*; do
    locale=$(basename "$locale_dir")
    [[ ! -d "$locale_dir" ]] && continue
    [[ ! -f "$pidgin_base/po/$locale.po" ]] && continue
    echo "Installing language $locale"
    mkdir -p share/locale/${locale}/LC_MESSAGES
    for module in atk10 gdk-pixbuf gettext-runtime gettext-tools glib20 gtk20 gtk20-properties libiconv shared-mime-info; do
        file=share/locale/${locale}/LC_MESSAGES/${module}.mo
        [[ -f /mingw${bitness}/${file} ]] && cp /mingw${bitness}/${file} $file
    done
done

# Gettext as intl.dll and GTK+ customizations
info "Installing remaining files"
cp -v bin/libintl-8.dll bin/intl.dll
cp -vr "$pidgin_base/pidgin/win32/gtk"/* .

# Generate binary zip
info "Creating the GTK+ bundle"
cd "$stage_dir"
rm -f "$zip_file"
echo "Creating ${zip_file##*/}"
zip -9 -qr "$zip_file" "$install_dir"
exit 0
