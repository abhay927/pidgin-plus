#!/bin/bash

# This script generates the GTK+ runtime bundle to be included in the Windows
# installer, if not already built and uploaded, and if the application version
# is suffixed with "devel" or --force has been specified.

# GTK+ bundle version
architecture=$(gcc -dumpmachine)
architecture="${architecture%%-*}"
bundle_version=$(pacman -Q mingw-w64-${architecture}-gtk2)
bundle_version="${bundle_version##* }"
bundle_version="${bundle_version%-*}.R285"
if [[ "$1" = --gtk-version ]]; then
    echo "$bundle_version"
    exit
fi

# Arguments
force="$3"
bitness="$2"
pidgin_base=$(readlink -f "$1")
if [ ! -e "$pidgin_base/ChangeLog" ]; then
    oops "$(basename $0) must have the base directory specified as a parameter"
    exit 1
fi

# Configuration
install_dir="Gtk"
application_version=$(<$pidgin_base/VERSION)
stage_dir_binary="$pidgin_base/pidgin/win32/nsis/gtk_binary_stage"
stage_dir_source="$pidgin_base/pidgin/win32/nsis/gtk_source_stage"
zip_binary="$pidgin_base/pidgin/win32/nsis/gtk-runtime-$bundle_version.zip"
zip_source="$pidgin_base/pidgin/win32/nsis/gtk-runtime-$bundle_version-source.zip"
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
    32) architecture_short=x86; bundle_sha1sum=17163b355c17829e346212e87cefac574b539e49 ;;
    64) architecture_short=x64; bundle_sha1sum=d1bf93c51d2a16cf87ac3fc5767e1297ec338299 ;;
esac

# Try downloading first
if [ ! -e "$zip_binary" ]; then
    url="https://launchpad.net/pidgin++/trunk/15.1/+download/Pidgin++ GTK+ Runtime ${bundle_version} ${architecture_short}.zip"
    echo "Downloading $url"
    wget "$url" --quiet --output-document "$zip_binary"
fi

# If the sha1sum check succeeds, then extract and quit
# If the sha1sum check fails and not forcing, then quit
# If the sha1sum check fails and forcing, then continue bundle creation

[[ "$application_version" == *"devel" || -n "$force" ]] && force="yes"
if ! check_sha1sum "$zip_binary" "$bundle_sha1sum" ${force:-quit}; then
    echo "Continuing GTK+ Bundle creation for Pidgin++ ${application_version}${force:+ (--force has been specified)}"
else
    echo "Extracting $zip_binary"
    cd "$pidgin_base/pidgin/win32/nsis"
    rm -rf "$install_dir"
    unzip -qo "$zip_binary"
    exit
fi

# Prepare for binary bundle
mkdir -p "$stage_dir_binary/$install_dir"
cd "$stage_dir_binary/$install_dir"

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

# Prepare the source bundle
info "Downloading source packages"
mkdir -p "$stage_dir_source"
cd "$stage_dir_source"
rm -f MISSING.txt
packages=(atk
          bzip2
          cairo
          expat
          fontconfig
          freetype
          gcc
          gdk-pixbuf2
          gettext
          glib2
          gtk2
          harfbuzz
          libffi
          libiconv
          libpng
          pango
          pixman
          shared-mime-info
          winpthreads-git
          zlib)
for package_name in "${packages[@]}"; do
    package="mingw-w64-${architecture}-${package_name}"
    package_version=$(pacman -Q $package)
    package_version="${package_version##* }"
    package_source="mingw-w64-i686-${package_name}-${package_version}.src.tar.gz"
    url="https://sourceforge.net/projects/msys2/files/REPOS/MINGW/Sources/${package_source}/download"
    echo "Integrating ${package} ${package_version}"
    [[ -s "$package_source" ]] && continue || rm -f "$package_source"
    if ! wget "$url" --quiet --output-document "$package_source"; then
        warn "failed downloading ${package_source}"
        echo "${package_source}" >> MISSING.txt
        rm "$package_source"
    fi
done
info "Preparing source of customizations"
cp -vr "$pidgin_base/pidgin/win32/gtk"/* .

# Generate binary and source bundles
info "Creating the GTK+ bundle"
cd "$stage_dir_binary"; rm -f "$zip_binary"; echo "Creating ${zip_binary##*/}"; zip -9 -qr "$zip_binary" "$install_dir"
cd "$stage_dir_source"; rm -f "$zip_source"; echo "Creating ${zip_source##*/}"; zip -9 -qr "$zip_source" .
rm -rf "$stage_dir_binary"
