#!/bin/bash

# This script generates the GTK+ runtime bundle to be included in the Windows
# installer, if not already built and uploaded, and if the application version
# is suffixed with "devel" or --force has been specified.

# Bundle version and expected SHA-1 hash
bundle_sha1sum=e083dbb28ed3c331677b34d3f089171d968d2577
bundle_version=2.24.24.4

# GTK+ bundle version
if [[ "$1" = --gtk-version ]]; then
    echo "$bundle_version"
    exit
fi

# Base directory
pidgin_base="$1"
if [ ! -e "$pidgin_base/ChangeLog" ]; then
    oops "$(basename $0) must have the base directory specified as a parameter"
    exit 1
fi

# Configuration
source "$pidgin_base/colored.sh"
install_dir_binary="Gtk"
install_dir_source="Gtk-source"
application_version=$(<$pidgin_base/VERSION)
contents_file="$install_dir_binary/CONTENTS"
stage_dir=$(readlink -f $pidgin_base/pidgin/win32/nsis/gtk_runtime_stage)
zip_binary="$pidgin_base/pidgin/win32/nsis/gtk-runtime-$bundle_version.zip"
zip_source="$pidgin_base/pidgin/win32/nsis/gtk-runtime-$bundle_version-source.zip"
fedora_base_url_stable="https://archive.fedoraproject.org/pub/fedora/linux/updates/20/i386"
fedora_base_url="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m"
[[ $(uname -or) = 1.*Msys ]] && wget_extra_arguments="--no-check-certificate"

# Libraries
packages=("$fedora_base_url/mingw32-atk-2.13.90-1.fc22.noarch.rpm        name:ATK         version:2.13.90-1   sha1sum:444dc16186d613c9a4a2a343185de7eefa2ca7ba,85e7e74e8132e0ee1ac01dfe8ed236e6ac1ef51f"
          "$fedora_base_url/mingw32-pixman-0.32.0-2.fc21.noarch.rpm      name:Pixman      version:0.32.0-2    sha1sum:457a369ba60afea88d2594055e5098d741f13ab4,c032b20181d394cbe063a42d4170f949a28b1368"
          "$fedora_base_url/mingw32-cairo-1.12.16-3.fc21.noarch.rpm      name:Cairo       version:1.12.16-3   sha1sum:3a64e41ad243e9129eace1e73440f6f3ffc22235,46b8d2b4a31627ffd44ea98aa210cb98a5158bcf"
          "$fedora_base_url/mingw32-expat-2.1.0-6.fc21.noarch.rpm        name:Expat       version:2.1.0-6     sha1sum:dff18fa1dbe74ba7b564910f762e57b3ee2bea26,7959966bf0499edb6e429e6b943e247955e3e80f"
          "$fedora_base_url/mingw32-fontconfig-2.11.1-2.fc21.noarch.rpm  name:Fontconfig  version:2.11.1-2    sha1sum:ef9be3b4dc5fe4d276f3759935c2df8c1ade5dad,c457837e69655f9821ba6eacb8fde5d3ea75c2f5"
          "$fedora_base_url/mingw32-freetype-2.5.3-2.fc21.noarch.rpm     name:Freetype    version:2.5.3-2     sha1sum:0217f4d9b0a883b4917d9c78db7aac047506c814,a747f4e6bd3c82de53c5c7cfe1d61e025ab6ed36"
          "$fedora_base_url/mingw32-win-iconv-0.0.6-2.fc21.noarch.rpm    name:Iconv       version:0.0.6-2     sha1sum:47d33d7178b89db60ac50797731a9f33c58995c2,f0bb2b68247c31a9bea218ee75f4307d235a8f51"
          "$fedora_base_url/mingw32-gettext-0.18.3.2-2.fc21.noarch.rpm   name:Gettext     version:0.18.3.2-2  sha1sum:26247b98279bb8ed17f83a4ff70c4ee4420c3986,8dba4e3baf02e8b4a0fa829f0df796d85b2e4df0"
          "$fedora_base_url/mingw32-libffi-3.0.13-5.fc21.noarch.rpm      name:Libffi      version:3.0.13-5    sha1sum:156b69157b7a09d024ae54d9bead8aff2613f7c4,89dc469ee50927543b1bcef7f87d110dcfe8367a"
          "$fedora_base_url/mingw32-glib2-2.42.0-1.fc22.noarch.rpm       name:Glib        version:2.42.0-1    sha1sum:52c36ba8f7e43dddc54bf2e1bea3ecdb96430310,0be98952036a9efafbb696463a978974df4b2442"
          "$fedora_base_url/mingw32-gtk2-2.24.24-2.fc22.noarch.rpm       name:GTK+        version:2.24.24-2   sha1sum:d6cec978e9defafbe857ac07614204ebd2f0cf8d,e1fd5d9e0eb0ad4a2b6d30dbf7462e0ca670e2fd"
          "$fedora_base_url/mingw32-gdk-pixbuf-2.30.8-2.fc21.noarch.rpm  name:GDK-Pixbuf  version:2.30.8-2    sha1sum:2ed07b24239837436ce933ec463f7ddd43f53997,3bc4c7b078230e6e9e7567afbe156805058d5a01"
          "$fedora_base_url/mingw32-libpng-1.6.10-2.fc21.noarch.rpm      name:Libpng      version:1.6.10-2    sha1sum:0bedb7a32c8ffbdac7ca32972a00001667777a58,9b0b43ee1ab101362578df9740071226e37df1bf"
          "$fedora_base_url/mingw32-pango-1.36.8-1.fc22.noarch.rpm       name:Pango       version:1.36.8-1    sha1sum:c98a10c2720a46d501faf47496d2e473ad2882ed,55451da725e41d759b14dc761608444181ea8eb6"
          "$fedora_base_url_stable/mingw32-gcc-4.8.3-1.fc20.i686.rpm     name:GCC-SJLJ    version:4.8.3-1     sha1sum:18aa08555d826fa1eb8779c1f2e446e2f753e719,fa7b61126c2a6a0a2725bf89383f53391ddaf75b"
          "$fedora_base_url/mingw32-zlib-1.2.8-3.fc21.noarch.rpm         name:Zlib        version:1.2.8-3     sha1sum:480b65828c4cce4060facaeb8a0431e12939b731,adb96b7c769b880807288442f9fdbdd0dbfef404")

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

# GPG check
check_signature() {
    local file="$1"
    local name="$3"
    local validation_value="$2"

    if [ ! -e "$file.asc" ]; then
        echo "Downloading GPG key for $name"
        wget -nv $wget_extra_arguments "$url.asc" || exit 1
    fi

    # Use our own keyring to avoid adding stuff to the main keyring. This
    # doesn't use $GPG_SIGN because we don't want this validation to be bypassed
    # when people are skipping signing output. Stick to Windows paths if this
    # looks like a native GnuPG.

    keyring="$stage_dir/$validation_value-keyring.gpg"
    [[ $(which gpg) != /usr/* ]] && keyring="$(cmd //c echo $keyring | tr / \\\\)"
    gpg_base="gpg -q --keyring $keyring"

    if [[ ! -e "$keyring" || $($gpg_base --list-keys "$validation_value" > /dev/null && echo -n "0") -ne 0 ]]; then
        touch "$keyring"
        try=1
        while [[ ! -s "$keyring" && $try -lt 10 ]]; do
            $gpg_base --no-default-keyring --keyserver pgp.mit.edu --recv-key "$validation_value"
            try=$((try + 1))
        done
    fi
    if ! $gpg_base --verify "$file.asc"; then
        oops "$file failed signature verification"
        exit 1
    fi
}

# RPM installer
install_rpm() {
    local rpm="$1"
    local cpio="${file%.rpm}.cpio"
    local extract_location=$(readlink -f "$(pwd)")
    local install_location=$(readlink -f "$install_dir_binary")

    echo "Extracting binary to $extract_location"
    if ! 7z x -y "$rpm" > /dev/null; then
        oops "failed extracting $rpm"
        return 1
    fi
    if ! 7z x -y "$cpio" > /dev/null; then
        oops "failed extracting $cpio"
        return 1
    fi

    echo "Installing binary to $install_location"
    rm -rf usr/i686-w64-mingw32/sys-root/mingw/bin/libssp-0.dll
    rm -rf usr/i686-w64-mingw32/sys-root/mingw/lib/gio
    rm -rf usr/i686-w64-mingw32/sys-root/mingw/lib/glib-2.0
    rm -rf usr/i686-w64-mingw32/sys-root/mingw/lib/gtk-2.0/include
    rm -rf usr/i686-w64-mingw32/sys-root/mingw/lib/libffi-3.0.13
    rm -rf usr/i686-w64-mingw32/sys-root/mingw/lib/pkgconfig
    rm -rf usr/i686-w64-mingw32/sys-root/mingw/man
    rm -rf usr/i686-w64-mingw32/sys-root/mingw/share/aclocal
    rm -rf usr/i686-w64-mingw32/sys-root/mingw/share/gettext
    rm -rf usr/i686-w64-mingw32/sys-root/mingw/share/glib-2.0
    rm -rf usr/i686-w64-mingw32/sys-root/mingw/share/gtk-2.0
    find usr/i686-w64-mingw32/sys-root/mingw/lib -name "*.a" -delete

    [[ -d usr/i686-w64-mingw32/sys-root/mingw/bin   ]] && cp -r usr/i686-w64-mingw32/sys-root/mingw/bin "$install_dir_binary"
    [[ -d usr/i686-w64-mingw32/sys-root/mingw/etc   ]] && cp -r usr/i686-w64-mingw32/sys-root/mingw/etc "$install_dir_binary"
    [[ -d usr/i686-w64-mingw32/sys-root/mingw/lib   ]] && cp -r usr/i686-w64-mingw32/sys-root/mingw/lib "$install_dir_binary"
    [[ -d usr/i686-w64-mingw32/sys-root/mingw/share ]] && cp -r usr/i686-w64-mingw32/sys-root/mingw/share "$install_dir_binary"
    [[ -d usr/share                                 ]] && cp -r usr/share "$install_dir_binary"

    rm -rf usr/i686-w64-mingw32/sys-root/mingw/bin
    rm -rf usr/i686-w64-mingw32/sys-root/mingw/etc
    rm -rf usr/i686-w64-mingw32/sys-root/mingw/lib
    rm -rf usr/i686-w64-mingw32/sys-root/mingw/share
    rm -rf usr/share
    return 0
}

# Library installer
function download_and_extract {
    local validation="${1##*\ }"
    local validation_type="${validation%%:*}"
    local validation_values="${validation##*:}"

    local url_binary="${1%%\ *}"
    local url_source="${url_binary/20\/i386/20\/SRPMS}"
    local url_source="${url_source/i386\/os\/Packages/source\/SRPMS}"
    local url_source="${url_source/mingw32/mingw}"
    local url_source="${url_source/noarch/src}"
    local url_source="${url_source/i686/src}"

    local version="${1##*version:}"
    local version="${version%% *}"
    local name="${1##*name:}"
    local name="${name%% *}"

    for url in $url_binary $url_source; do
        case $url in
            $url_binary) info "Integrating $name"
                         echo "Downloading binary from $url"
                         validation_value="${validation_values%,*}" ;;
            $url_source) echo "Downloading source code from $url"
                         validation_value="${validation_values#*,}" ;;
        esac
        local file=$(basename $url)
        local extension="${file##*.}"

        if [[ ! -e "$file" ]]; then
            wget --quiet $wget_extra_arguments $url || exit 1
        fi
        case "$validation_type" in
        sha1sum) check_sha1sum "$file" "$validation_value" quit ;;
            gpg) check_signature "$file" "$validation_value" "$name" ;;
              *) oops "unrecognized validation type of $validation_type"
                 exit 1
        esac

        if [[ $url = $url_source ]]; then
            cp -v "$file" "$install_dir_source"
            continue
        fi
        case "$extension" in
            rpm) install_rpm "$file"                       || exit 1 ;;
            zip) unzip -q "$file" -d "$install_dir_binary" || exit 1 ;;
            dll) cp "$file" "$install_dir_binary/bin"      || exit 1 ;;
        esac
    done
    echo "$name $version" >> "$contents_file"
}

# Try downloading first
if [ ! -e "$zip_binary" ]; then
    url="https://launchpad.net/pidgin++/trunk/14.1/+download/Pidgin++ GTK+ Runtime $bundle_version.zip"
    echo "Downloading $url"
    wget --quiet $wget_extra_arguments --output-document "$zip_binary" "$url"
fi

# If the sha1sum check succeeds, then extract and quit
# If the sha1sum check fails and not forcing, then quit
# If the sha1sum check fails and forcing, then continue bundle creation

[[ "$application_version" == *"devel" || "$2" = --force ]] && force="yes"
if ! check_sha1sum "$zip_binary" "$bundle_sha1sum" ${force:-quit}; then
    echo "Continuing GTK+ Bundle creation for Pidgin++ ${application_version}${force:+ (--force has been specified)}"
else
    echo "Extracting $zip_binary"
    cd "$pidgin_base/pidgin/win32/nsis"
    unzip -qo "$zip_binary"
    exit
fi

# Prepare
mkdir -p "$stage_dir"
cd "$stage_dir"
rm -rf "$install_dir_binary" "$install_dir_source"
mkdir "$install_dir_binary" "$install_dir_source"
echo "Bundle Version $bundle_version" > "$contents_file"

# Integrate libraries
for package in "${packages[@]}"; do
    download_and_extract "$package"
done

# Gettext as intl.dll
info "Configuring GTK+"
printf "New name for the Gettext DLL: "
cp -v "$install_dir_binary/bin/libintl-8.dll" "$install_dir_binary/bin/intl.dll"

# Default theme
printf "Default theme: "
echo gtk-theme-name = \"MS-Windows\" > "$install_dir_binary/etc/gtk-2.0/gtkrc"
cat "$install_dir_binary/etc/gtk-2.0/gtkrc"
echo

# GTK+ customizations
echo "Applying GTK+ customizations"
cp -vr ../../gtk/* "$install_dir_binary"
cp -vr ../../gtk/* "$install_dir_source"

# Remove missing translations
info "Creating binary and source code bundles"
for locale_dir in "$install_dir_binary/share/locale/"*; do
    locale=$(basename $locale_dir)
    if [ ! -e "$pidgin_base/po/$locale.po" ]; then
        note "removing $locale translation as it is missing from Pidgin"
        rm -r "$locale_dir"
    fi
done

# Generate binary zip
rm -f "$zip_binary"
echo "Creating ${zip_binary##*/}"
zip -9 -qr "$zip_binary" "$install_dir_binary"

# Generate source zip
rm -f "$zip_source"
echo "Creating ${zip_source##*/}"
zip -9 -qr "$zip_source" "$install_dir_source"
exit 0
