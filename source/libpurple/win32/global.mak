#
# global.mak
#
# This file should be included by all Makefile.mingw files for project
# wide definitions (after correctly defining PIDGIN_TREE_TOP).
#

#include optional $(PIDGIN_TREE_TOP)/local.mak to allow overriding of any definitions
-include $(PIDGIN_TREE_TOP)/local.mak

# Locations of our various dependencies
MSYS2_MINGW_TOP = $(shell which $(CC) | awk -F/bin/ '{ printf $$1; }')
WIN32_DEV_TOP ?= $(PIDGIN_TREE_TOP)/../win32-dev
GTKSPELL_TOP ?= $(MSYS2_MINGW_TOP)
ENCHANT_TOP ?= $(MSYS2_MINGW_TOP)
GTK_TOP ?= $(MSYS2_MINGW_TOP)
GTK_BIN ?= $(GTK_TOP)/bin
LIBXML2_TOP ?= $(MSYS2_MINGW_TOP)
MEANWHILE_TOP ?= $(MSYS2_MINGW_TOP)
NSS_TOP ?= $(MSYS2_MINGW_TOP)
PERL_LIB_TOP ?= $(MSYS2_MINGW_TOP)
SILC_TOOLKIT ?= $(MSYS2_MINGW_TOP)
TCL_LIB_TOP ?= $(MSYS2_MINGW_TOP)
GSTREAMER_TOP ?= $(MSYS2_MINGW_TOP)
GCC_TOP ?= $(MSYS2_MINGW_TOP)/bin
DRMINGW_TOP ?= $(MSYS2_MINGW_TOP)/bin
CYRUS_SASL_TOP ?= $(MSYS2_MINGW_TOP)
WINSPARKLE_TOP ?= $(WIN32_DEV_TOP)/WinSparkle-0.4

# Where we installing this stuff to?
PIDGIN_INSTALL_DIR := $(PIDGIN_TREE_TOP)/win32-install-dir
PURPLE_INSTALL_DIR := $(PIDGIN_TREE_TOP)/win32-install-dir
PIDGIN_INSTALL_PLUGINS_DIR := $(PIDGIN_INSTALL_DIR)/plugins
PIDGIN_INSTALL_PERL_DIR := $(PIDGIN_INSTALL_PLUGINS_DIR)/perl
PURPLE_INSTALL_PLUGINS_DIR := $(PURPLE_INSTALL_DIR)/plugins
PURPLE_INSTALL_PERL_DIR := $(PURPLE_INSTALL_PLUGINS_DIR)/perl
PURPLE_INSTALL_PO_DIR := $(PURPLE_INSTALL_DIR)/locale

# Important (enough) locations in our source code
PURPLE_TOP := $(PIDGIN_TREE_TOP)/libpurple
PURPLE_PLUGINS_TOP := $(PURPLE_TOP)/plugins
PURPLE_PERL_TOP := $(PURPLE_PLUGINS_TOP)/perl
PIDGIN_TOP := $(PIDGIN_TREE_TOP)/pidgin
PIDGIN_PIXMAPS_TOP := $(PIDGIN_TOP)/pixmaps
PIDGIN_PLUGINS_TOP := $(PIDGIN_TOP)/plugins
PURPLE_PO_TOP := $(PIDGIN_TREE_TOP)/po
PURPLE_PROTOS_TOP := $(PURPLE_TOP)/protocols

# Locations of important (in-tree) build targets
PIDGIN_CONFIG_H := $(PIDGIN_TREE_TOP)/config.h
PURPLE_CONFIG_H := $(PIDGIN_TREE_TOP)/config.h
PIDGIN_REVISION_H := $(PIDGIN_TREE_TOP)/package_revision.h
PIDGIN_REVISION_RAW_TXT := $(PIDGIN_TREE_TOP)/package_revision_raw.txt
PURPLE_PURPLE_H := $(PURPLE_TOP)/purple.h
PURPLE_VERSION_H := $(PURPLE_TOP)/version.h
PURPLE_DLL := $(PURPLE_TOP)/libpurple.dll
PURPLE_PERL_DLL := $(PURPLE_PERL_TOP)/perl.dll
PIDGIN_DLL := $(PIDGIN_TOP)/pidgin.dll
PIDGIN_EXE := $(PIDGIN_TOP)/pidgin.exe
PIDGIN_PORTABLE_EXE := $(PIDGIN_TOP)/pidgin-portable.exe

GCCWARNINGS ?= -Waggregate-return -Wcast-align -Wdeclaration-after-statement -Werror-implicit-function-declaration -Wextra -Wno-sign-compare -Wno-unused-parameter -Winit-self -Wmissing-declarations -Wmissing-prototypes -Wnested-externs -Wpointer-arith
CC_HARDENING_OPTIONS ?= -Wstack-protector -fwrapv -fno-strict-overflow -Wno-missing-field-initializers -Wformat-security -fstack-protector-all --param ssp-buffer-size=1
LD_HARDENING_OPTIONS ?= -Wl,--dynamicbase -Wl,--nxcompat

APPLICATION_NAME     := $(shell grep -E '\#define\s+APPLICATION_NAME\s'     $(PURPLE_TOP)/internal.h | awk -F'"' '{ print $$2 }' )
APPLICATION_WEBSITE  := $(shell grep -E '\#define\s+APPLICATION_WEBSITE\s'  $(PURPLE_TOP)/internal.h | awk -F'"' '{ print $$2 }' )
BUILD_DATE           := $(shell date +%Y%m%d)

# parse the version number from the configure.ac file if it is newer
#m4_define([purple_major_version], [2])
#m4_define([purple_minor_version], [0])
#m4_define([purple_micro_version], [0])
#m4_define([purple_version_suffix], [devel])
APPLICATION_VERSION := $(shell \
  if [ ! $(PIDGIN_TREE_TOP)/VERSION -nt $(PIDGIN_TREE_TOP)/configure.ac ]; then \
    awk 'BEGIN {FS="[\\(\\)\\[\\]]"} /^m4_define..purple_(major|minor)_version/ {printf("%s.",$$5);} /^m4_define..purple_micro_version/ {printf("%s",$$5);} /^m4_define..purple_version_suffix/ {printf("%s",$$5); exit}' \
      $(PIDGIN_TREE_TOP)/configure.ac > $(PIDGIN_TREE_TOP)/VERSION; \
  fi; \
  cat $(PIDGIN_TREE_TOP)/VERSION \
)
PURPLE_VERSION := $(APPLICATION_VERSION)
UPSTREAM_VERSION := $(shell sed -e 's/-.*//' <<< "$(APPLICATION_VERSION)")
DISPLAY_VERSION_FULL := $(shell sed -e 's/.*-//' <<< "$(APPLICATION_VERSION)")
DISPLAY_VERSION := $(shell sed -e 's/\.0$$//' <<< "$(DISPLAY_VERSION_FULL)")

ifeq ($(shell gcc -dumpmachine), x86_64-w64-mingw32)
BITNESS := 64
else
BITNESS := 32
endif

CYRUS_SASL ?= 1

ifeq ($(CYRUS_SASL), 1)
DEFINES += -DHAVE_CYRUS_SASL
endif

DEFINES += -DHAVE_CONFIG_H -DWIN32_LEAN_AND_MEAN

CFLAGS += -O2 -Wall $(GCCWARNINGS) $(CC_HARDENING_OPTIONS) -pipe -mms-bitfields -g -DBUILD_DATE=\"$(BUILD_DATE)\"

ifndef DISABLE_UPDATE_CHECK
	CFLAGS += -DENABLE_UPDATE_CHECK
endif

# If not specified, dlls are built with the default base address of 0x10000000.
# When loaded into a process address space a dll will be rebased if its base
# address colides with the base address of an existing dll.  To avoid rebasing
# we do the following.  Rebasing can slow down the load time of dlls and it
# also renders debug info useless.
DLL_LD_FLAGS += -Wl,--enable-auto-image-base -Wl,--enable-auto-import $(LD_HARDENING_OPTIONS) -lssp

# Build programs
ifeq "$(origin CC)" "default"
  CC := gcc.exe
endif
GMSGFMT ?= msgfmt
MAKENSIS ?= makensis.exe
PERL ?= perl
WINDRES ?= windres
STRIP ?= strip
INTLTOOL_MERGE ?= intltool-merge
SIGNTOOL ?= bypass
GPG_SIGN ?= bypass

PIDGIN_COMMON_RULES := $(PURPLE_TOP)/win32/rules.mak
PIDGIN_COMMON_TARGETS := $(PURPLE_TOP)/win32/targets.mak
MINGW_MAKEFILE := Makefile.mingw

INSTALL_PIXMAPS ?= 1
INSTALL_SSL_CERTIFICATES ?= 1
