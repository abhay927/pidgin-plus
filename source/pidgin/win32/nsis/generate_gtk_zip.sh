#!/bin/bash
# Script to generate zip file for GTK+ runtime to be included in Pidgin installer

PIDGIN_BASE=$1
GPG_SIGN=$2
[[ "$3" = --force ]] && FORCE="yes"

if [ ! -e $PIDGIN_BASE/ChangeLog ]; then
	echo $(basename $0) must must have the pidgin base dir specified as a parameter.
	exit 1
fi

STAGE_DIR=`readlink -f $PIDGIN_BASE/pidgin/win32/nsis/gtk_runtime_stage`
#Subdirectory of $STAGE_DIR
INSTALL_DIR=Gtk
CONTENTS_FILE=$INSTALL_DIR/CONTENTS
PIDGIN_VERSION=$( < $PIDGIN_BASE/VERSION )

#This needs to be changed every time there is any sort of change.
BUNDLE_VERSION=2.24.24.1
BUNDLE_SHA1SUM=3d2767b8154acb84778e9afa2de450d09755c2ed
ZIP_FILE="$PIDGIN_BASE/pidgin/win32/nsis/gtk-runtime-$BUNDLE_VERSION.zip"

#Download the existing file (so that we distribute the exact same file for all releases with the same bundle version)
FILE="$ZIP_FILE"
if [ ! -e "$FILE" ]; then
	wget "https://launchpad.net/pidgin++/trunk/2.10.9-rs219/+download/Pidgin GTK+ Runtime $BUNDLE_VERSION.zip" -O "$FILE"
fi
CHECK_SHA1SUM=`sha1sum $FILE`
CHECK_SHA1SUM=${CHECK_SHA1SUM%%\ *}
if [ "$CHECK_SHA1SUM" != "$BUNDLE_SHA1SUM" ]; then
	echo "sha1sum ($CHECK_SHA1SUM) for $FILE doesn't match expected value of $BUNDLE_SHA1SUM"
	# Allow "devel" versions or those using the --force option to build their own bundles if the download doesn't succeed
	if [[ "$PIDGIN_VERSION" == *"devel" || -n "$FORCE" ]]; then
		echo "Continuing GTK+ Bundle creation for Pidgin ${PIDGIN_VERSION}${FORCE:+ (--force has been specified)}"
	else
		exit 1
	fi
else
	exit 0
fi


ATK="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-atk-2.12.0-2.fc21.noarch.rpm ATK 2.12.0-2 sha1sum:b45a978edb3de3d6a0445df88de23ca619e21730"
PIXMAN="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-pixman-0.32.0-2.fc21.noarch.rpm Pixman 0.32.0-2 sha1sum:457a369ba60afea88d2594055e5098d741f13ab4"
CAIRO="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-cairo-1.12.16-3.fc21.noarch.rpm Cairo 1.12.16-3 sha1sum:3a64e41ad243e9129eace1e73440f6f3ffc22235"
EXPAT="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-expat-2.1.0-6.fc21.noarch.rpm Expat 2.1.0-6 sha1sum:dff18fa1dbe74ba7b564910f762e57b3ee2bea26"
FONTCONFIG="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-fontconfig-2.11.1-2.fc21.noarch.rpm Fontconfig 2.11.1-2 sha1sum:ef9be3b4dc5fe4d276f3759935c2df8c1ade5dad"
FREETYPE="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-freetype-2.5.3-2.fc21.noarch.rpm Freetype 2.5.3-2 sha1sum:0217f4d9b0a883b4917d9c78db7aac047506c814"
ICONV="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-win-iconv-0.0.6-2.fc21.noarch.rpm Iconv 0.0.6-2 sha1sum:47d33d7178b89db60ac50797731a9f33c58995c2"
GETTEXT="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-gettext-0.18.3.2-2.fc21.noarch.rpm Gettext 0.18.3.2-2 sha1sum:26247b98279bb8ed17f83a4ff70c4ee4420c3986"
GLIB="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-glib2-2.41.2-1.fc22.noarch.rpm Glib 2.41.2-1 sha1sum:a143ebf2922656cf3a2908699be61a3eaab66909"
GTK="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-gtk2-2.24.24-2.fc22.noarch.rpm GTK+ 2.24.24-2 sha1sum:d6cec978e9defafbe857ac07614204ebd2f0cf8d"
GDK_PIXBUF="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-gdk-pixbuf-2.30.8-2.fc21.noarch.rpm GDK-Pixbuf 2.30.8-2 sha1sum:2ed07b24239837436ce933ec463f7ddd43f53997"
LIBPNG="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-libpng-1.6.10-2.fc21.noarch.rpm libpng 1.6.10-2 sha1sum:0bedb7a32c8ffbdac7ca32972a00001667777a58"
PANGO="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-pango-1.36.5-2.fc22.noarch.rpm Pango 1.36.5-2 sha1sum:8ed5d8e2163b543118569587bf1cef002fd67eaf"
ZLIB="https://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/i386/os/Packages/m/mingw32-zlib-1.2.8-3.fc21.noarch.rpm zlib 1.2.8-3 sha1sum:480b65828c4cce4060facaeb8a0431e12939b731"

ALL="ATK PIXMAN CAIRO EXPAT FONTCONFIG FREETYPE ICONV GETTEXT GLIB GTK GDK_PIXBUF LIBPNG PANGO ZLIB"

mkdir -p $STAGE_DIR
cd $STAGE_DIR

rm -rf $INSTALL_DIR
mkdir $INSTALL_DIR

#new CONTENTS file
echo Bundle Version $BUNDLE_VERSION > $CONTENTS_FILE

function download_and_extract {
	URL=${1%%\ *}
	VALIDATION=${1##*\ }
	NAME=${1%\ *}
	NAME=${NAME#*\ }
	FILE=$(basename $URL)
	if [ ! -e $FILE ]; then
		echo
		echo Downloading $NAME
		wget $URL || exit 1
	fi
	VALIDATION_TYPE=${VALIDATION%%:*}
	VALIDATION_VALUE=${VALIDATION##*:}
	if [ $VALIDATION_TYPE == 'sha1sum' ]; then
		CHECK_SHA1SUM=`sha1sum $FILE`
		CHECK_SHA1SUM=${CHECK_SHA1SUM%%\ *}
		if [ "$CHECK_SHA1SUM" != "$VALIDATION_VALUE" ]; then
			echo "sha1sum ($CHECK_SHA1SUM) for $FILE doesn't match expected value of $VALIDATION_VALUE"
			exit 1
		fi
	elif [ $VALIDATION_TYPE == 'gpg' ]; then
		if [ ! -e "$FILE.asc" ]; then
			echo Downloading GPG key for $NAME
			wget "$URL.asc" || exit 1
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
		$GPG_BASE --verify "$FILE.asc" || (echo "$FILE failed signature verification"; exit 1) || exit 1
	else
		echo "Unrecognized validation type of $VALIDATION_TYPE"
		exit 1
	fi
	EXTENSION=${FILE##*.}
	case $EXTENSION in
		zip) unzip -q $FILE -d $INSTALL_DIR || exit 1 ;;
		dll) cp $FILE $INSTALL_DIR/bin || exit 1 ;;
		rpm) 7z x -y $FILE || exit 1
		     7z x -y ${FILE%.rpm}.cpio
		     rm -vrf usr/i686-w64-mingw32/sys-root/mingw/lib/pkgconfig
		     rm -vrf usr/i686-w64-mingw32/sys-root/mingw/lib/glib-2.0
		     rm -vrf usr/i686-w64-mingw32/sys-root/mingw/lib/gtk-2.0/include
		     rm -vrf usr/i686-w64-mingw32/sys-root/mingw/share/aclocal
		     rm -vrf usr/i686-w64-mingw32/sys-root/mingw/share/gettext
		     rm -vrf usr/i686-w64-mingw32/sys-root/mingw/share/glib-2.0
		     rm -vrf usr/i686-w64-mingw32/sys-root/mingw/share/gtk-2.0/demo
		     find usr/i686-w64-mingw32/sys-root/mingw/lib -name "*.dll.a" -delete
		     cp -vr usr/i686-w64-mingw32/sys-root/mingw/lib $INSTALL_DIR
		     cp -vr usr/i686-w64-mingw32/sys-root/mingw/bin $INSTALL_DIR
		     cp -vr usr/i686-w64-mingw32/sys-root/mingw/etc $INSTALL_DIR
		     cp -vr usr/i686-w64-mingw32/sys-root/mingw/share $INSTALL_DIR
		     cp -vr usr/share $INSTALL_DIR ;;
	esac
	echo "$NAME" >> $CONTENTS_FILE
}

for VAL in $ALL
do
	VAR=${!VAL}
	download_and_extract "$VAR"
done

echo
echo "Including Gettext DLL under additional name:"
cp -v $INSTALL_DIR/bin/libintl-8.dll $INSTALL_DIR/bin/intl.dll
echo

#Default GTK+ Theme to MS-Windows
echo gtk-theme-name = \"MS-Windows\" > $INSTALL_DIR/etc/gtk-2.0/gtkrc

# GTK+ customizations
echo "Applying GTK+ customizations:"
cp -vr ../../gtk/* $INSTALL_DIR
echo

#Blow away translations that we don't have in Pidgin
for LOCALE_DIR in $INSTALL_DIR/share/locale/*
do
	LOCALE=$(basename $LOCALE_DIR)
	if [ ! -e $PIDGIN_BASE/po/$LOCALE.po ]; then
		echo Removing $LOCALE translation as it is missing from Pidgin
		rm -r $LOCALE_DIR
	fi
done

#Generate zip file to be included in installer
rm -f $ZIP_FILE
zip -9 -r $ZIP_FILE Gtk
($GPG_SIGN -ab $ZIP_FILE && $GPG_SIGN --verify $ZIP_FILE.asc) || exit 1

exit 0

