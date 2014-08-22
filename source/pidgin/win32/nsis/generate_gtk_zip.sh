#!/bin/bash
# Script to generate zip file for GTK+ runtime to be included in Pidgin installer

#This needs to be changed every time there is any sort of change.
BUNDLE_VERSION=2.24.24.3
BUNDLE_SHA1SUM=e4a3e3f37b8b7bda02d98674f4034a57cfe4255c

if [[ "$1" = --gtk-version ]]; then
    echo $BUNDLE_VERSION
    exit
fi

PIDGIN_BASE=$1
PIDGIN_VERSION=$( < $PIDGIN_BASE/VERSION )
source "$PIDGIN_BASE/colored.sh"

# Allow "devel" versions or those using the --force option to build their own bundles if the download doesn't succeed
[[ "$PIDGIN_VERSION" == *"devel" || "$2" = --force ]] && FORCE="yes"

if [ ! -e $PIDGIN_BASE/ChangeLog ]; then
	oops "$(basename $0) must have the pidgin base dir specified as a parameter"
	exit 1
fi

STAGE_DIR=`readlink -f $PIDGIN_BASE/pidgin/win32/nsis/gtk_runtime_stage`
#Subdirectory of $STAGE_DIR
INSTALL_DIR=Gtk
SOURCE_DIR=Gtk-source
CONTENTS_FILE=$INSTALL_DIR/CONTENTS
ZIP_FILE="$PIDGIN_BASE/pidgin/win32/nsis/gtk-runtime-$BUNDLE_VERSION.zip"

#Download the existing file (so that we distribute the exact same file for all releases with the same bundle version)
FILE="$ZIP_FILE"
if [ ! -e "$FILE" ]; then
	url="https://launchpad.net/pidgin++/trunk/2.10.9-rs226/+download/Pidgin GTK+ Runtime $BUNDLE_VERSION.zip"
	echo "Downloading $url"
	wget --quiet "$url" -O "$FILE"
fi

check_sha1sum() {
	FILE_SHA1SUM=`sha1sum $1`
	FILE_SHA1SUM=${FILE_SHA1SUM%%\ *}
	SHA1SUM_ERROR="sha1sum check failed for $1\nexpected: $2\nobtained: $FILE_SHA1SUM"
	if [[ "$FILE_SHA1SUM" != "$2" ]]; then
		if [[ "$3" = quit ]]; then
			oops "the $SHA1SUM_ERROR"
			exit 1
		fi
		printf "The $SHA1SUM_ERROR\n"
		return 1
	fi
	return 0
}

if ! check_sha1sum "$FILE" "$BUNDLE_SHA1SUM" ${FORCE:-quit}; then
	echo "Continuing GTK+ Bundle creation for Pidgin ${PIDGIN_VERSION}${FORCE:+ (--force has been specified)}"
else
	echo "Extracting $ZIP_FILE"
	cd "$PIDGIN_BASE/pidgin/win32/nsis"
	unzip -qo "$ZIP_FILE"
	exit
fi


ATK="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-atk-2.12.0-2.fc21.noarch.rpm ATK 2.12.0-2 sha1sum:b45a978edb3de3d6a0445df88de23ca619e21730,93c7cb44d5a6789a7f95c066dc81267fe1dcf949"
PIXMAN="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-pixman-0.32.0-2.fc21.noarch.rpm Pixman 0.32.0-2 sha1sum:457a369ba60afea88d2594055e5098d741f13ab4,c032b20181d394cbe063a42d4170f949a28b1368"
CAIRO="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-cairo-1.12.16-3.fc21.noarch.rpm Cairo 1.12.16-3 sha1sum:3a64e41ad243e9129eace1e73440f6f3ffc22235,c607a9d6594a41cf8de69c9414d119a15527a6a4"
EXPAT="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-expat-2.1.0-6.fc21.noarch.rpm Expat 2.1.0-6 sha1sum:dff18fa1dbe74ba7b564910f762e57b3ee2bea26,7959966bf0499edb6e429e6b943e247955e3e80f"
FONTCONFIG="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-fontconfig-2.11.1-2.fc21.noarch.rpm Fontconfig 2.11.1-2 sha1sum:ef9be3b4dc5fe4d276f3759935c2df8c1ade5dad,c457837e69655f9821ba6eacb8fde5d3ea75c2f5"
FREETYPE="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-freetype-2.5.3-2.fc21.noarch.rpm Freetype 2.5.3-2 sha1sum:0217f4d9b0a883b4917d9c78db7aac047506c814,a747f4e6bd3c82de53c5c7cfe1d61e025ab6ed36"
ICONV="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-win-iconv-0.0.6-2.fc21.noarch.rpm Iconv 0.0.6-2 sha1sum:47d33d7178b89db60ac50797731a9f33c58995c2,f0bb2b68247c31a9bea218ee75f4307d235a8f51"
GETTEXT="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-gettext-0.18.3.2-2.fc21.noarch.rpm Gettext 0.18.3.2-2 sha1sum:26247b98279bb8ed17f83a4ff70c4ee4420c3986,8dba4e3baf02e8b4a0fa829f0df796d85b2e4df0"
LIBFFI="http://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-libffi-3.0.13-5.fc21.noarch.rpm Libffi 3.0.13-5 sha1sum:156b69157b7a09d024ae54d9bead8aff2613f7c4,89dc469ee50927543b1bcef7f87d110dcfe8367a"
GLIB="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-glib2-2.41.2-1.fc22.noarch.rpm Glib 2.41.2-1 sha1sum:a143ebf2922656cf3a2908699be61a3eaab66909,9545eb831938a1d7f7a65f8aa6fb9a4a9d2772fb"
GTK="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-gtk2-2.24.24-2.fc22.noarch.rpm GTK+ 2.24.24-2 sha1sum:d6cec978e9defafbe857ac07614204ebd2f0cf8d,e1fd5d9e0eb0ad4a2b6d30dbf7462e0ca670e2fd"
GDK_PIXBUF="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-gdk-pixbuf-2.30.8-2.fc21.noarch.rpm GDK-Pixbuf 2.30.8-2 sha1sum:2ed07b24239837436ce933ec463f7ddd43f53997,3bc4c7b078230e6e9e7567afbe156805058d5a01"
LIBPNG="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-libpng-1.6.10-2.fc21.noarch.rpm libpng 1.6.10-2 sha1sum:0bedb7a32c8ffbdac7ca32972a00001667777a58,9b0b43ee1ab101362578df9740071226e37df1bf"
PANGO="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-pango-1.36.5-2.fc22.noarch.rpm Pango 1.36.5-2 sha1sum:8ed5d8e2163b543118569587bf1cef002fd67eaf,d9ce955b501c51353acf9a3b4d1f6b38e4776a47"
ZLIB="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-zlib-1.2.8-3.fc21.noarch.rpm zlib 1.2.8-3 sha1sum:480b65828c4cce4060facaeb8a0431e12939b731,adb96b7c769b880807288442f9fdbdd0dbfef404"

ALL="ATK PIXMAN CAIRO EXPAT FONTCONFIG FREETYPE ICONV GETTEXT LIBFFI GLIB GTK GDK_PIXBUF LIBPNG PANGO ZLIB"

mkdir -p $STAGE_DIR
cd $STAGE_DIR

rm -rf $INSTALL_DIR $SOURCE_DIR
mkdir $INSTALL_DIR $SOURCE_DIR

#new CONTENTS file
echo Bundle Version $BUNDLE_VERSION > $CONTENTS_FILE

function download_and_extract {
	URL_BINARY=${1%%\ *}
	URL_SOURCE=${URL_BINARY/i386\/os\/Packages/source\/SRPMS}
	URL_SOURCE=${URL_SOURCE/mingw32/mingw}
	URL_SOURCE=${URL_SOURCE/noarch/src}
	VALIDATION=${1##*\ }
	NAME=${1%\ *}
	NAME=${NAME#*\ }
	SHORT_NAME=${NAME%\ *}
	for URL in $URL_BINARY $URL_SOURCE; do
		FILE=$(basename $URL)
		case $URL in
			$URL_BINARY) info "Integrating ${SHORT_NAME}"
			             task "Downloading binary from $URL" ;;
			$URL_SOURCE) task "Downloading source code from $URL" ;;
		esac
		if [[ ! -e $FILE ]]; then
			wget --quiet $URL && echo || exit 1
		else
			echo
		fi
		VALIDATION_TYPE=${VALIDATION%%:*}
		VALIDATION_VALUES=${VALIDATION##*:}
		if [[ $URL = $URL_SOURCE ]]; then
			VALIDATION_VALUE=${VALIDATION_VALUES#*,}
		else
			VALIDATION_VALUE=${VALIDATION_VALUES%,*}
		fi
		if [[ $VALIDATION_TYPE == 'sha1sum' ]]; then
			check_sha1sum "$FILE" "$VALIDATION_VALUE" quit
		elif [ $VALIDATION_TYPE == 'gpg' ]; then
			if [ ! -e "$FILE.asc" ]; then
				echo Downloading GPG key for $NAME
				wget -nv "$URL.asc" || exit 1
			fi
			#Use our own keyring to avoid adding stuff to the main keyring
			#This doesn't use $GPG_SIGN because we don't this validation to be bypassed when people are skipping signing output
			if [[ $(which gpg) = /usr/* ]]; then
				GPG_BASE="gpg -q --keyring $STAGE_DIR/$VALIDATION_VALUE-keyring.gpg"
			else
				# This looks like a native GnuPG, stick to Windows paths
				GPG_BASE="gpg -q --keyring $(cmd //c echo $STAGE_DIR/$VALIDATION_VALUE-keyring.gpg | tr / \\\\)"
			fi
			if [[ ! -e $STAGE_DIR/$VALIDATION_VALUE-keyring.gpg \
					|| `$GPG_BASE --list-keys "$VALIDATION_VALUE" > /dev/null && echo -n "0"` -ne 0 ]]; then
				touch $STAGE_DIR/$VALIDATION_VALUE-keyring.gpg
				# Try a few times getting the public key
				try=1
				while [[ ! -s $STAGE_DIR/$VALIDATION_VALUE-keyring.gpg && $try -lt 10 ]]; do
					$GPG_BASE --no-default-keyring --keyserver pgp.mit.edu --recv-key "$VALIDATION_VALUE"
					try=$((try + 1))
				done
			fi
			if ! $GPG_BASE --verify "$FILE.asc"; then
				oops "$FILE failed signature verification"
				exit 1
			fi
		else
			oops "unrecognized validation type of $VALIDATION_TYPE"
			exit 1
		fi
		if [[ $URL = $URL_SOURCE ]]; then
			cp -v $FILE $SOURCE_DIR
			continue
		fi
		EXTENSION=${FILE##*.}
		case $EXTENSION in
			zip) unzip -q $FILE -d $INSTALL_DIR || exit 1 ;;
			dll) cp $FILE $INSTALL_DIR/bin || exit 1 ;;
			rpm) task "Extracting binary to $(readlink -f "$(pwd)")"
			     if ! 7z x -y $FILE > /dev/null; then
			         oops "failed extracting $FILE"
			         exit 1
			     fi
			     CPIO=${FILE%.rpm}.cpio
			     if ! 7z x -y $CPIO > /dev/null; then
			         oops "failed extracting $CPIO"
			         exit 1
			     fi
			     echo

			     task "Installing binary to $(readlink -f "$INSTALL_DIR")"
			     rm -rf usr/i686-w64-mingw32/sys-root/mingw/lib/gio
			     rm -rf usr/i686-w64-mingw32/sys-root/mingw/lib/glib-2.0
			     rm -rf usr/i686-w64-mingw32/sys-root/mingw/lib/gtk-2.0/include
			     rm -rf usr/i686-w64-mingw32/sys-root/mingw/lib/libffi-3.0.13
			     rm -rf usr/i686-w64-mingw32/sys-root/mingw/lib/pkgconfig

			     rm -rf usr/i686-w64-mingw32/sys-root/mingw/share/aclocal
			     rm -rf usr/i686-w64-mingw32/sys-root/mingw/share/gettext
			     rm -rf usr/i686-w64-mingw32/sys-root/mingw/share/glib-2.0
			     rm -rf usr/i686-w64-mingw32/sys-root/mingw/share/gtk-2.0
			     find usr/i686-w64-mingw32/sys-root/mingw/lib -name "*.dll.a" -delete

			     [[ -d usr/i686-w64-mingw32/sys-root/mingw/bin   ]] && cp -r usr/i686-w64-mingw32/sys-root/mingw/bin $INSTALL_DIR
			     [[ -d usr/i686-w64-mingw32/sys-root/mingw/etc   ]] && cp -r usr/i686-w64-mingw32/sys-root/mingw/etc $INSTALL_DIR
			     [[ -d usr/i686-w64-mingw32/sys-root/mingw/lib   ]] && cp -r usr/i686-w64-mingw32/sys-root/mingw/lib $INSTALL_DIR
			     [[ -d usr/i686-w64-mingw32/sys-root/mingw/share ]] && cp -r usr/i686-w64-mingw32/sys-root/mingw/share $INSTALL_DIR
			     [[ -d usr/share                                 ]] && cp -r usr/share $INSTALL_DIR

			     rm -rf usr/i686-w64-mingw32/sys-root/mingw/bin
			     rm -rf usr/i686-w64-mingw32/sys-root/mingw/etc
			     rm -rf usr/i686-w64-mingw32/sys-root/mingw/lib
			     rm -rf usr/i686-w64-mingw32/sys-root/mingw/share
			     rm -rf usr/share
			     echo ;;
		esac
	done
	echo "$NAME" >> $CONTENTS_FILE
}

for VAL in $ALL
do
	VAR=${!VAL}
	download_and_extract "$VAR"
done

info "Configuring GTK+"
printf "New name for the Gettext DLL: "
cp -v $INSTALL_DIR/bin/libintl-8.dll $INSTALL_DIR/bin/intl.dll

printf "Default theme: "
echo gtk-theme-name = \"MS-Windows\" > $INSTALL_DIR/etc/gtk-2.0/gtkrc
cat $INSTALL_DIR/etc/gtk-2.0/gtkrc
echo

# GTK+ customizations
echo "Applying GTK+ customizations"
cp -vr ../../gtk/* $INSTALL_DIR
cp -vr ../../gtk/* $SOURCE_DIR

#Blow away translations that we don't have in Pidgin
info "Creating binary and source code bundles"
for LOCALE_DIR in $INSTALL_DIR/share/locale/*
do
	LOCALE=$(basename $LOCALE_DIR)
	if [ ! -e $PIDGIN_BASE/po/$LOCALE.po ]; then
		note "removing $LOCALE translation as it is missing from Pidgin"
		rm -r $LOCALE_DIR
	fi
done

#Generate zip file to be included in installer and its source zip
for suffix in "" "-source"; do
	ZIP_FILE="${ZIP_FILE%.zip}$suffix.zip"
	rm -f $ZIP_FILE
	echo "Creating ${ZIP_FILE##*/}"
	zip -9 -qr $ZIP_FILE Gtk$suffix
done
exit 0
