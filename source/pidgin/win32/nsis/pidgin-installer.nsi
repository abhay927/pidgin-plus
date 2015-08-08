; Installer script for win32 Pidgin
; Original Author: Herman Bloggs <hermanator12002@yahoo.com>
; Updated By: Daniel Atallah <daniel_atallah@yahoo.com>

; NOTE: this .NSI script is intended for NSIS 2.27+
;

;--------------------------------
;Global Variables
Var name
Var STARTUP_RUN_KEY
Var CURRENT_GTK_STATE
Var WARNED_GTK_STATE

;--------------------------------
;Configuration

;The name var is set in .onInit
Name $name

!ifdef OFFLINE_INSTALLER
OutFile "pidgin++_${DISPLAY_VERSION}_offline.exe"
!else
OutFile "pidgin++_${DISPLAY_VERSION}.exe"
!endif

SetCompressor /SOLID lzma
ShowInstDetails show
ShowUninstDetails show
SetDateSave on
RequestExecutionLevel highest

; $name and $INSTDIR are set in .onInit function..

!include "MUI.nsh"
!include "Sections.nsh"
!include "LogicLib.nsh"
!include "Memento.nsh"
!include "x64.nsh"

!include "FileFunc.nsh"
!insertmacro GetParameters
!insertmacro GetOptions
!insertmacro GetParent

!include "WordFunc.nsh"
!insertmacro VersionCompare
!insertmacro WordFind
!insertmacro un.WordFind

!include "TextFunc.nsh"

;--------------------------------
;Defines

!define PIDGIN_NSIS_INCLUDE_PATH		"."

; Remove these and the stuff that uses them at some point
!define OLD_GAIM_REG_KEY			"SOFTWARE\gaim"
!define OLD_GAIM_UNINSTALL_KEY			"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Gaim"
!define OLD_GAIM_UNINST_EXE			"gaim-uninst.exe"

!define PIDGIN_REG_KEY				"SOFTWARE\Pidgin++"
!define PIDGIN_UNINSTALL_KEY			"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Pidgin++"

!define HKLM_APP_PATHS_KEY			"SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\pidgin.exe"
!define STARTUP_RUN_KEY				"SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
!define PIDGIN_UNINST_EXE			"pidgin-uninst.exe"

!define GTK_MIN_VERSION				"${GTK_INSTALL_VERSION}"
!define PERL_REG_KEY				"SOFTWARE\Perl"
!define PERL_DLL				"perl522.dll"

!define DOWNLOADER_URL				"https://pidgin.im/win32/download_redir.php?version=${UPSTREAM_VERSION}"

!define MEMENTO_REGISTRY_ROOT			HKLM
!define MEMENTO_REGISTRY_KEY			"${PIDGIN_UNINSTALL_KEY}"

;--------------------------------
;Version resource
VIProductVersion "${PRODUCT_VERSION}"
VIAddVersionKey "ProductName" "${APPLICATION_NAME} (${APPLICATION_BITNESS}-bit)"
VIAddVersionKey "FileVersion" "${APPLICATION_VERSION}"
VIAddVersionKey "ProductVersion" "${DISPLAY_VERSION_FULL}.${BUILD_DATE}"
VIAddVersionKey "LegalCopyright" "Copyright (C) 1998-2015 The ${APPLICATION_NAME} developer community"
!ifdef OFFLINE_INSTALLER
VIAddVersionKey "FileDescription" "Pidgin++ Offline Installer"
!else
VIAddVersionKey "FileDescription" "Pidgin++ Installer"
!endif

;--------------------------------
;Reserve files used in .onInit
;for faster start-up
ReserveFile "${NSISDIR}\Plugins\System.dll"
ReserveFile "${NSISDIR}\Plugins\UserInfo.dll"
!insertmacro MUI_RESERVEFILE_INSTALLOPTIONS
!insertmacro MUI_RESERVEFILE_LANGDLL

;--------------------------------
;Modern UI Configuration

  !define MUI_ICON				".\pixmaps\pidgin-install.ico"
  !define MUI_UNICON				".\pixmaps\pidgin-install.ico"
  !define MUI_WELCOMEFINISHPAGE_BITMAP		".\pixmaps\pidgin-intro.bmp"
  !define MUI_HEADERIMAGE
  !define MUI_HEADERIMAGE_BITMAP		".\pixmaps\pidgin-header.bmp"

  ; Alter License section
  !define MUI_LICENSEPAGE_BUTTON		$(PIDGINLICENSEBUTTON)
  !define MUI_LICENSEPAGE_TEXT_BOTTOM		$(PIDGINLICENSEBOTTOMTEXT)

  !define MUI_LANGDLL_REGISTRY_ROOT "HKCU"
  !define MUI_LANGDLL_REGISTRY_KEY ${PIDGIN_REG_KEY}
  !define MUI_LANGDLL_REGISTRY_VALUENAME "Installer Language"

  !define MUI_COMPONENTSPAGE_SMALLDESC
  !define MUI_ABORTWARNING

  ;Finish Page config
  !define MUI_FINISHPAGE_NOAUTOCLOSE
  ;!define MUI_FINISHPAGE_RUN			"$INSTDIR\pidgin.exe"
  ;!define MUI_FINISHPAGE_RUN_NOTCHECKED
  !define MUI_FINISHPAGE_LINK			$(PIDGINFINISHVISITWEBSITE)
  !define MUI_FINISHPAGE_LINK_LOCATION		"${APPLICATION_WEBSITE}"
  !define MUI_FINISHPAGE_SHOWREADME
  !define MUI_FINISHPAGE_SHOWREADME_FUNCTION	"ShowChanges"
  !define MUI_FINISHPAGE_SHOWREADME_TEXT	$(PIDGINREADCHANGES)
  !define MUI_FINISHPAGE_SHOWREADME_CHECKED
  !define CHANGELOG				"$INSTDIR\documents\CHANGELOG.html"

  ;Uninstall warning
  !define MUI_UNCONFIRMPAGE_TEXT_TOP		$(PIDGINUNINSTALLWARNING)

;--------------------------------
;Pages

  !define MUI_PAGE_CUSTOMFUNCTION_PRE		preWelcomePage
  !define MUI_WELCOMEPAGE_TITLE_3LINES
  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_LICENSE			"../../../COPYING"
  !insertmacro MUI_PAGE_COMPONENTS

  ; Pidgin install dir page
  !insertmacro MUI_PAGE_DIRECTORY

  !insertmacro MUI_PAGE_INSTFILES
  !define MUI_FINISHPAGE_TITLE_3LINES
  !insertmacro MUI_PAGE_FINISH

  !define MUI_WELCOMEPAGE_TITLE_3LINES
  !insertmacro MUI_UNPAGE_WELCOME
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  !define MUI_FINISHPAGE_TITLE_3LINES
  !insertmacro MUI_UNPAGE_FINISH

;--------------------------------
;Languages

  !include "${PIDGIN_NSIS_INCLUDE_PATH}\langmacros.nsh"

;--------------------------------

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start Install Sections ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;--------------------------------
;Uninstall any old version of Pidgin (or Gaim)

Section -SecUninstallOldPidgin
  !ifdef X64_APPLICATION
  SetRegView 64
  !endif

  ; Check install rights..
  Call CheckUserInstallRights
  Pop $R0

  ;First try to uninstall Pidgin
  StrCpy $R4 ${PIDGIN_REG_KEY}
  StrCpy $R5 ${PIDGIN_UNINSTALL_KEY}
  StrCpy $R6 ${PIDGIN_UNINST_EXE}
  StrCpy $R7 ${APPLICATION_NAME}

  start_comparison:
  ;If pidgin is currently set to run on startup,
  ;  save the section of the Registry where the setting is before uninstalling,
  ;  so we can put it back after installing the new version
  ClearErrors
  ReadRegStr $STARTUP_RUN_KEY HKCU "${STARTUP_RUN_KEY}" $R7
  IfErrors +3
  StrCpy $STARTUP_RUN_KEY "HKCU"
  Goto +5
  ClearErrors
  ReadRegStr $STARTUP_RUN_KEY HKLM "${STARTUP_RUN_KEY}" $R7
  IfErrors +2
  StrCpy $STARTUP_RUN_KEY "HKLM"

  StrCmp $R0 "HKLM" compare_hklm
  StrCmp $R0 "HKCU" compare_hkcu done

  compare_hkcu:
      ReadRegStr $R1 HKCU $R4 ""
      ReadRegStr $R2 HKCU $R4 "Version"
      ReadRegStr $R3 HKCU "$R5" "UninstallString"
      Goto try_uninstall

  compare_hklm:
      ReadRegStr $R1 HKLM $R4 ""
      ReadRegStr $R2 HKLM $R4 "Version"
      ReadRegStr $R3 HKLM "$R5" "UninstallString"

  ; If a previous version exists, remove it
  try_uninstall:
    StrCmp $R1 "" no_version_found
      ; Version key started with 0.60a3. Prior versions can't be
      ; automatically uninstalled.
      StrCmp $R2 "" uninstall_problem
        ; Check if we have uninstall string..
        IfFileExists $R3 0 uninstall_problem
          ; Have uninstall string, go ahead and uninstall.
          SetOverwrite on
          ; Need to copy uninstaller outside of the install dir
          ClearErrors
          CopyFiles /SILENT $R3 "$TEMP\$R6"
          SetOverwrite off
          IfErrors uninstall_problem
            ; Ready to uninstall..
            ClearErrors
            ExecWait '"$TEMP\$R6" /S /UPGRADE=1 _?=$R1'
            IfErrors exec_error
              Delete "$TEMP\$R6"
            Goto done

            exec_error:
              Delete "$TEMP\$R6"
              Goto uninstall_problem

        no_version_found:
          ;We've already tried to fallback to an old gaim instance
          StrCmp $R7 "Gaim" done
          ; If we couldn't uninstall Pidgin, try to uninstall Gaim
          StrCpy $STARTUP_RUN_KEY "NONE"
          StrCpy $R4 ${OLD_GAIM_REG_KEY}
          StrCpy $R5 ${OLD_GAIM_UNINSTALL_KEY}
          StrCpy $R6 ${OLD_GAIM_UNINST_EXE}
          StrCpy $R7 "Gaim"
          Goto start_comparison

        uninstall_problem:
          ; We can't uninstall.  Either the user must manually uninstall or we ignore and reinstall over it.
          MessageBox MB_OKCANCEL $(PIDGINPROMPTCONTINUEWITHOUTUNINSTALL) /SD IDOK IDOK done
          Quit
  done:
SectionEnd


;--------------------------------
;GTK+ Runtime Install Section

Section $(GTKSECTIONTITLE) SecGtk
  RMDir /r "$INSTDIR\Gtk"
  SetOutPath "$INSTDIR"
  File /r /x locale ".\Gtk"
SectionEnd

;--------------------------------
;Pidgin Install Section

Section $(PIDGINSECTIONTITLE) SecPidgin
  SectionIn 1 RO
  !ifdef X64_APPLICATION
  SetRegView 64
  !endif

  ; Check install rights..
  Call CheckUserInstallRights
  Pop $R0

  StrCmp $R0 "NONE" pidgin_install_files
  StrCmp $R0 "HKLM" pidgin_hklm pidgin_hkcu

  pidgin_hklm:
    WriteRegStr HKLM "${HKLM_APP_PATHS_KEY}" "" "$INSTDIR\pidgin.exe"
    WriteRegStr HKLM "${HKLM_APP_PATHS_KEY}" "Path" "$INSTDIR\Gtk\bin"
    WriteRegStr HKLM ${PIDGIN_REG_KEY} "" "$INSTDIR"
    WriteRegStr HKLM ${PIDGIN_REG_KEY} "Version" "${APPLICATION_VERSION}"
    WriteRegStr HKLM "${PIDGIN_UNINSTALL_KEY}" "DisplayIcon" "$INSTDIR\pidgin.exe"
    WriteRegStr HKLM "${PIDGIN_UNINSTALL_KEY}" "DisplayName" "${APPLICATION_NAME} (${APPLICATION_BITNESS}-bit)"
    WriteRegStr HKLM "${PIDGIN_UNINSTALL_KEY}" "DisplayVersion" "${DISPLAY_VERSION}"
    WriteRegStr HKLM "${PIDGIN_UNINSTALL_KEY}" "HelpLink" "http://developer.pidgin.im/wiki/Using Pidgin"
    WriteRegDWORD HKLM "${PIDGIN_UNINSTALL_KEY}" "NoModify" 1
    WriteRegDWORD HKLM "${PIDGIN_UNINSTALL_KEY}" "NoRepair" 1
    WriteRegStr HKLM "${PIDGIN_UNINSTALL_KEY}" "UninstallString" "$INSTDIR\${PIDGIN_UNINST_EXE}"
    ; Sets scope of the desktop and Start Menu entries for all users.
    SetShellVarContext "all"
    Goto pidgin_install_files

  pidgin_hkcu:
    WriteRegStr HKCU ${PIDGIN_REG_KEY} "" "$INSTDIR"
    WriteRegStr HKCU ${PIDGIN_REG_KEY} "Version" "${APPLICATION_VERSION}"
    WriteRegStr HKCU "${PIDGIN_UNINSTALL_KEY}" "DisplayIcon" "$INSTDIR\pidgin.exe"
    WriteRegStr HKCU "${PIDGIN_UNINSTALL_KEY}" "DisplayName" "${APPLICATION_NAME} (${APPLICATION_BITNESS}-bit)"
    WriteRegStr HKCU "${PIDGIN_UNINSTALL_KEY}" "DisplayVersion" "${DISPLAY_VERSION}"
    WriteRegStr HKCU "${PIDGIN_UNINSTALL_KEY}" "HelpLink" "http://developer.pidgin.im/wiki/Using Pidgin"
    WriteRegDWORD HKCU "${PIDGIN_UNINSTALL_KEY}" "NoModify" 1
    WriteRegDWORD HKCU "${PIDGIN_UNINSTALL_KEY}" "NoRepair" 1
    WriteRegStr HKCU "${PIDGIN_UNINSTALL_KEY}" "UninstallString" "$INSTDIR\${PIDGIN_UNINST_EXE}"
    Goto pidgin_install_files

  pidgin_install_files:
    SetOutPath "$INSTDIR"
    ; Pidgin files
    SetOverwrite on

    ;Delete old liboscar and libjabber since they tend to be problematic
    Delete "$INSTDIR\plugins\liboscar.dll"
    Delete "$INSTDIR\plugins\libjabber.dll"
    ;Delete misnamed nss-prefs plugin from 2.10.11
    Delete "$INSTDIR\plugins\.dll"

    File /r /x locale /x Gtk ..\..\..\${PIDGIN_INSTALL_DIR}\*.*

    ; Check if Perl is installed, if so add it to the AppPaths
    ReadRegStr $R2 HKLM ${PERL_REG_KEY} ""
    StrCmp $R2 "" 0 perl_exists
      ReadRegStr $R2 HKCU ${PERL_REG_KEY} ""
      StrCmp $R2 "" perl_done perl_exists

      perl_exists:
        IfFileExists "$R2\bin\${PERL_DLL}" 0 perl_done
        StrCmp $R0 "HKLM" 0 perl_done
          ReadRegStr $R3 HKLM "${HKLM_APP_PATHS_KEY}" "Path"
          WriteRegStr HKLM "${HKLM_APP_PATHS_KEY}" "Path" "$R3;$R2\bin"

    perl_done:

    SetOutPath "$INSTDIR"

    ; If we don't have install rights we're done
    StrCmp $R0 "NONE" done
    SetOverwrite off

    ; write out uninstaller
    SetOverwrite on
    WriteUninstaller "$INSTDIR\${PIDGIN_UNINST_EXE}"
    SetOverwrite off

    ; If we previously had pidgin set up to run on startup, make it do so again
    StrCmp $STARTUP_RUN_KEY "HKCU" +1 +2
    WriteRegStr HKCU "${STARTUP_RUN_KEY}" "${APPLICATION_NAME}" "$INSTDIR\pidgin.exe"
    StrCmp $STARTUP_RUN_KEY "HKLM" +1 +2
    WriteRegStr HKLM "${STARTUP_RUN_KEY}" "${APPLICATION_NAME}" "$INSTDIR\pidgin.exe"

  done:
SectionEnd ; end of default Pidgin section

;--------------------------------
;Shortcuts

SectionGroup /e $(PIDGINSHORTCUTSSECTIONTITLE) SecShortcuts
  Section /o $(PIDGINDESKTOPSHORTCUTSECTIONTITLE) SecDesktopShortcut
    SetOverwrite on
    CreateShortCut "$DESKTOP\Pidgin++.lnk" "$INSTDIR\pidgin.exe"
    SetOverwrite off
  SectionEnd
  Section $(PIDGINSTARTMENUSHORTCUTSECTIONTITLE) SecStartMenuShortcut
    SetOverwrite on
    CreateShortCut "$SMPROGRAMS\Pidgin++.lnk" "$INSTDIR\pidgin.exe"
    SetOverwrite off
  SectionEnd
SectionGroupEnd

;--------------------------------
;URI Handling

!macro URI_SECTION proto proto_name
  Section /o "${proto_name}" SecURI_${proto}
    Push "${proto}"
    Call RegisterURIHandler
  SectionEnd
!macroend
SectionGroup /e $(URIHANDLERSSECTIONTITLE) SecURIHandlers
  !insertmacro URI_SECTION "aim" "AIM"
  !insertmacro URI_SECTION "msnim" "MSN"
  !insertmacro URI_SECTION "myim" "MySpaceIM"
  !insertmacro URI_SECTION "ymsgr" "Yahoo"
  !insertmacro URI_SECTION "xmpp" "XMPP"
  !insertmacro URI_SECTION "irc" "IRC"
  !insertmacro URI_SECTION "ircs" "IRCS"
SectionGroupEnd

;--------------------------------
;Translations

!macro LANG_SECTION lang_code lang_name
  ${MementoUnselectedSection} "${lang_name}" SecLang_${lang_code}
    SetOutPath "$INSTDIR\locale\${lang_code}\LC_MESSAGES"
    File "..\..\..\${PIDGIN_INSTALL_DIR}\locale\${lang_code}\LC_MESSAGES\*.mo"

    ; Install the GTK+ translation for the language
    SetOutPath "$INSTDIR\Gtk\share\locale\${lang_code}\LC_MESSAGES"
    File /nonfatal ".\Gtk\share\locale\${lang_code}\LC_MESSAGES\atk10.mo"
    File /nonfatal ".\Gtk\share\locale\${lang_code}\LC_MESSAGES\gdk-pixbuf.mo"
    File /nonfatal ".\Gtk\share\locale\${lang_code}\LC_MESSAGES\gettext-runtime.mo"
    File /nonfatal ".\Gtk\share\locale\${lang_code}\LC_MESSAGES\gettext-tools.mo"
    File /nonfatal ".\Gtk\share\locale\${lang_code}\LC_MESSAGES\glib20.mo"
    File /nonfatal ".\Gtk\share\locale\${lang_code}\LC_MESSAGES\gtk20.mo"
    File /nonfatal ".\Gtk\share\locale\${lang_code}\LC_MESSAGES\gtk20-properties.mo"
    File /nonfatal ".\Gtk\share\locale\${lang_code}\LC_MESSAGES\libiconv.mo"
    File /nonfatal ".\Gtk\share\locale\${lang_code}\LC_MESSAGES\shared-mime-info.mo"

    ; Remove language if missing
    SetOutPath "$INSTDIR"
    RmDir "$INSTDIR\Gtk\share\locale\${lang_code}\LC_MESSAGES"
    RmDir "$INSTDIR\Gtk\share\locale\${lang_code}"
  ${MementoSectionEnd}
!macroend
SectionGroup $(TRANSLATIONSSECTIONTITLE) SecTranslations
  # pidgin-translations is generated based on the contents of the locale directory
  !include "pidgin-translations.nsh"
SectionGroupEnd
${MementoSectionDone}

;--------------------------------
;Spell Checking

!macro SPELLCHECK_SECTION lang lang_name lang_file
  Section /o "${lang_name}" SecSpell_${lang}
    Push ${lang_file}
    Push ${lang}
    !ifdef OFFLINE_INSTALLER
      SetOutPath "$INSTDIR\spellcheck\share\enchant\myspell"
      File "dictionaries\unpacked\${lang}\*"
    !else
      Call InstallDict
    !endif
  SectionEnd
!macroend
SectionGroup $(PIDGINSPELLCHECKSECTIONTITLE) SecSpellCheck
  !include "pidgin-spellcheck.nsh"
SectionGroupEnd

!ifdef OFFLINE_INSTALLER
Section /o $(DEBUGSYMBOLSSECTIONTITLE) SecDebugSymbols
  SetOutPath $INSTDIR
  File /r "..\..\..\${DEBUG_SYMBOLS_DIR}\*.*"
SectionEnd
!endif

;--------------------------------
;Uninstaller Section


Section Uninstall
  !ifdef X64_APPLICATION
  SetRegView 64
  !endif

  Call un.CheckUserInstallRights
  Pop $R0
  StrCmp $R0 "NONE" no_rights
  StrCmp $R0 "HKCU" try_hkcu try_hklm

  try_hkcu:
    ReadRegStr $R0 HKCU ${PIDGIN_REG_KEY} ""
    StrCmp $R0 $INSTDIR 0 cant_uninstall
      ; HKCU install path matches our INSTDIR so uninstall
      DeleteRegKey HKCU ${PIDGIN_REG_KEY}
      DeleteRegKey HKCU "${PIDGIN_UNINSTALL_KEY}"
      Goto cont_uninstall

  try_hklm:
    ReadRegStr $R0 HKLM ${PIDGIN_REG_KEY} ""
    StrCmp $R0 $INSTDIR 0 try_hkcu
      ; HKLM install path matches our INSTDIR so uninstall
      DeleteRegKey HKLM ${PIDGIN_REG_KEY}
      DeleteRegKey HKLM "${PIDGIN_UNINSTALL_KEY}"
      DeleteRegKey HKLM "${HKLM_APP_PATHS_KEY}"
      ; Sets start menu and desktop scope to all users..
      SetShellVarContext "all"

  cont_uninstall:
    ; The WinPrefs plugin may have left this behind..
    DeleteRegValue HKCU "${STARTUP_RUN_KEY}" "${APPLICATION_NAME}"
    DeleteRegValue HKLM "${STARTUP_RUN_KEY}" "${APPLICATION_NAME}"
    ; Remove Language preference info
    DeleteRegValue HKCU "${PIDGIN_REG_KEY}" "${MUI_LANGDLL_REGISTRY_VALUENAME}"

    ; Remove any URI handlers
    ; I can't think of an easy way to maintain a list in a single place
    Push "aim"
    Call un.UnregisterURIHandler
    Push "msnim"
    Call un.UnregisterURIHandler
    Push "myim"
    Call un.UnregisterURIHandler
    Push "ymsgr"
    Call un.UnregisterURIHandler
    Push "xmpp"
    Call un.UnregisterURIHandler
    Push "irc"
    Call un.UnregisterURIHandler
    Push "ircs"
    Call un.UnregisterURIHandler

    RMDir /r "$INSTDIR\ca-certs"
    RMDir /r "$INSTDIR\documents"
    RMDir /r "$INSTDIR\locale"
    RMDir /r "$INSTDIR\pixmaps"
    RMDir /r "$INSTDIR\plugins"
    RMDir /r "$INSTDIR\sasl2"
    RMDir /r "$INSTDIR\sounds"
    RMDir /r "$INSTDIR\spellcheck"
    Delete "$INSTDIR\freebl3.dll"
    Delete "$INSTDIR\intl.dll"
    Delete "$INSTDIR\libgcc_s_dw2-1.dll"
    Delete "$INSTDIR\libgcc_s_seh-1.dll"
    Delete "$INSTDIR\libjabber.dll"
    Delete "$INSTDIR\libnspr4.dll"
    Delete "$INSTDIR\libmeanwhile-1.dll"
    Delete "$INSTDIR\liboscar.dll"
    Delete "$INSTDIR\libplc4.dll"
    Delete "$INSTDIR\libplds4.dll"
    Delete "$INSTDIR\libpurple.dll"
    Delete "$INSTDIR\libsasl2-3.dll"
    Delete "$INSTDIR\libsilc-1-1-4.dll"
    Delete "$INSTDIR\libsilcclient-1-1-4.dll"
    Delete "$INSTDIR\libsystre-0.dll"
    Delete "$INSTDIR\libtre-5.dll"
    Delete "$INSTDIR\libsqlite3-0.dll"
    Delete "$INSTDIR\libssp-0.dll"
    Delete "$INSTDIR\libwinpthread-1.dll"
    Delete "$INSTDIR\libxml2-2.dll"
    Delete "$INSTDIR\libymsg.dll"
    Delete "$INSTDIR\nss3.dll"
    Delete "$INSTDIR\nssutil3.dll"
    Delete "$INSTDIR\pidgin.dll"
    Delete "$INSTDIR\pidgin.exe"
    Delete "$INSTDIR\smime3.dll"
    Delete "$INSTDIR\softokn3.dll"
    Delete "$INSTDIR\ssl3.dll"
    Delete "$INSTDIR\libwinsparkle.dll"
    Delete "$INSTDIR\libjpeg-8.dll"
    Delete "$INSTDIR\libtiff-5.dll"
    Delete "$INSTDIR\liblzma-5.dll"
    Delete "$INSTDIR\libstdc++-6.dll"
    Delete "$INSTDIR\wxbase30u_gcc_custom.dll"
    Delete "$INSTDIR\wxmsw30u_core_gcc_custom.dll"
    Delete "$INSTDIR\${PIDGIN_UNINST_EXE}"
    Delete "$INSTDIR\exchndl.dll"
    Delete "$INSTDIR\mgwhelp.dll"
    Delete "$INSTDIR\install.log"
    Delete "$INSTDIR\*.debug"

    ; Remove the local GTK+ copy (if we're not just upgrading)
    ${GetParameters} $R0
    ClearErrors
    ${GetOptions} "$R0" "/UPGRADE=" $R1
    IfErrors +2
    StrCmp $R1 "1" upgrade_done
    RMDir /r "$INSTDIR\Gtk"
    ; Remove the downloaded spellcheck dictionaries (if we're not just upgrading)
    RMDir /r "$INSTDIR\spellcheck"
    upgrade_done:

    ;Try to remove Pidgin install dir (only if empty)
    RMDir "$INSTDIR"

    ; Shortcuts..
    Delete "$DESKTOP\Pidgin++.lnk"
    Delete "$SMPROGRAMS\Pidgin++.lnk"

    Goto done

  cant_uninstall:
    MessageBox MB_OK $(PIDGINUNINSTALLERROR1) /SD IDOK
    Quit

  no_rights:
    MessageBox MB_OK $(PIDGINUNINSTALLERROR2) /SD IDOK
    Quit

  done:
SectionEnd ; end of uninstall section

;--------------------------------
;Descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecPidgin} \
        $(PIDGINSECTIONDESCRIPTION)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecGtk} \
        $(GTKSECTIONDESCRIPTION)

  !insertmacro MUI_DESCRIPTION_TEXT ${SecShortcuts} \
        $(PIDGINSHORTCUTSSECTIONDESCRIPTION)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecDesktopShortcut} \
        $(PIDGINDESKTOPSHORTCUTDESC)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecStartMenuShortcut} \
        $(PIDGINSTARTMENUSHORTCUTDESC)

  !insertmacro MUI_DESCRIPTION_TEXT ${SecSpellCheck} \
        $(PIDGINSPELLCHECKSECTIONDESCRIPTION)

!insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
;Functions

; Default the URI handler checkboxes if Pidgin is the current handler or if there is no handler
Function SelectURIHandlerSelections
  !ifdef X64_APPLICATION
  SetRegView 64
  !endif

  Push $R0
  Push $R1
  Push $R2
  Push $R3

  ; Start with the first URI handler
  IntOp $R0 ${SecURIHandlers} + 1

  start:
  ; If it is the end of the section group, stop
  SectionGetFlags $R0 $R1
  IntOp $R2 $R1 & ${SF_SECGRPEND}
  IntCmp $R2 ${SF_SECGRPEND} done

  SectionGetText $R0 $R2
  ;Strip the trailing ':'
  StrLen $R3 $R2
  IntOp $R3 $R3 - 1
  StrCpy $R2 $R2 $R3

  ClearErrors
  ReadRegStr $R3 HKCR "$R2" ""
  IfErrors default_on ;there is no current handler

  Push $R2
  Call CheckIfPidginIsCurrentURIHandler
  Pop $R3

  ; If Pidgin isn't the current handler, we don't steal it automatically
  IntCmp $R3 0 end_loop

  ;We default the URI handler checkbox on
  default_on:
  IntOp $R1 $R1 | ${SF_SELECTED} ; Select
  SectionSetFlags $R0 $R1

  end_loop:
  IntOp $R0 $R0 + 1 ;Advance to the next section
  Goto start

  done:
  Pop $R3
  Pop $R2
  Pop $R1
  Pop $R0
FunctionEnd ;SelectURIHandlerSections

; Check if Pidgin is the current handler
; Returns a boolean on the stack
!macro CheckIfPidginIsCurrentURIHandlerMacro UN
Function ${UN}CheckIfPidginIsCurrentURIHandler
  !ifdef X64_APPLICATION
  SetRegView 64
  !endif

  Exch $R0
  ClearErrors

  ReadRegStr $R0 HKCR "$R0\shell\Open\command" ""
  IfErrors 0 +3
    IntOp $R0 0 + 0
    Goto done

  !ifdef __UNINSTALL__
  ${un.WordFind} "$R0" "pidgin.exe" "E+1{" $R0
  !else
  ${WordFind} "$R0" "pidgin.exe" "E+1{" $R0
  !endif
  IntOp $R0 0 + 1
  IfErrors 0 +2
    IntOp $R0 0 + 0

  done:
  Exch $R0
FunctionEnd
!macroend
!insertmacro CheckIfPidginIsCurrentURIHandlerMacro ""
!insertmacro CheckIfPidginIsCurrentURIHandlerMacro "un."

; If Pidgin is the current URI handler for the specified protocol, remove it.
Function un.UnregisterURIHandler
  !ifdef X64_APPLICATION
  SetRegView 64
  !endif

  Exch $R0
  Push $R1

  Push $R0
  Call un.CheckIfPidginIsCurrentURIHandler
  Pop $R1

  ; If Pidgin isn't the current handler, leave it as-is
  IntCmp $R1 0 done

  ;Unregister the URI handler
  DetailPrint "Unregistering $R0 URI Handler"
  DeleteRegKey HKCR "$R0"

  done:
  Pop $R1
  Pop $R0
FunctionEnd

Function RegisterURIHandler
  !ifdef X64_APPLICATION
  SetRegView 64
  !endif

  Exch $R0
  DetailPrint "Registering $R0 URI Handler"
  DeleteRegKey HKCR "$R0"
  WriteRegStr HKCR "$R0" "" "URL:$R0"
  WriteRegStr HKCR "$R0" "URL Protocol" ""
  WriteRegStr HKCR "$R0\DefaultIcon" "" "$INSTDIR\pidgin.exe"
  WriteRegStr HKCR "$R0\shell" "" ""
  WriteRegStr HKCR "$R0\shell\Open" "" ""
  WriteRegStr HKCR "$R0\shell\Open\command" "" "$INSTDIR\pidgin.exe --protocolhandler=%1"
  Pop $R0
FunctionEnd


!macro CheckUserInstallRightsMacro UN
Function ${UN}CheckUserInstallRights
  Push $0
  Push $1
  ClearErrors
  UserInfo::GetName
  IfErrors Win9x
  Pop $0
  UserInfo::GetAccountType
  Pop $1

  StrCmp $1 "Admin" 0 +3
    StrCpy $1 "HKLM"
    Goto done
  StrCmp $1 "Power" 0 +3
    StrCpy $1 "HKLM"
    Goto done
  StrCmp $1 "User" 0 +3
    StrCpy $1 "HKCU"
    Goto done
  StrCmp $1 "Guest" 0 +3
    StrCpy $1 "NONE"
    Goto done
  ; Unknown error
  StrCpy $1 "NONE"
  Goto done

  Win9x:
    StrCpy $1 "HKLM"

  done:
    Exch $1
    Exch
    Pop $0
FunctionEnd
!macroend
!insertmacro CheckUserInstallRightsMacro ""
!insertmacro CheckUserInstallRightsMacro "un."

;
; Usage:
;   Push $0 ; Path string
;   Call VerifyDir
;   Pop $0 ; 0 - Bad path  1 - Good path
;
Function VerifyDir
  Exch $0
  Push $1
  Push $2
  Loop:
    IfFileExists $0 dir_exists
    StrCpy $1 $0 ; save last
    ${GetParent} $0 $0
    StrLen $2 $0
    ; IfFileExists "C:" on xp returns true and on win2k returns false
    ; So we're done in such a case..
    IntCmp $2 2 loop_done
    ; GetParent of "C:" returns ""
    IntCmp $2 0 loop_done
    Goto Loop

  loop_done:
    StrCpy $1 "$0\GaImFooB"
    ; Check if we can create dir on this drive..
    ClearErrors
    CreateDirectory $1
    IfErrors DirBad DirGood

  dir_exists:
    ClearErrors
    FileOpen $1 "$0\pidginfoo.bar" w
    IfErrors PathBad PathGood

    DirGood:
      RMDir $1
      Goto PathGood1

    DirBad:
      RMDir $1
      Goto PathBad1

    PathBad:
      FileClose $1
      Delete "$0\pidginfoo.bar"
      PathBad1:
      StrCpy $0 "0"
      Push $0
      Goto done

    PathGood:
      FileClose $1
      Delete "$0\pidginfoo.bar"
      PathGood1:
      StrCpy $0 "1"
      Push $0

  done:
  Exch 3 ; The top of the stack contains the output variable
  Pop $0
  Pop $2
  Pop $1
FunctionEnd

Function .onVerifyInstDir
  Push $0
  Push $INSTDIR
  Call VerifyDir
  Pop $0
  StrCmp $0 "0" 0 dir_good
  Pop $0
  Abort

  dir_good:
  Pop $0
FunctionEnd

;
; Usage:
; Call DoWeNeedGtk
; First Pop:
;   0 - We have the correct version
;   1 - We have an old version that should work, prompt user for optional upgrade
;   2 - We have an old version that needs to be upgraded
;   3 - We don't have Gtk+ at all
;
Function DoWeNeedGtk
  Push $0
  Push $1

  IfFileExists "$INSTDIR\Gtk\CONTENTS" +3
  Push "3"
  Goto done

  ClearErrors
  ${ConfigRead} "$INSTDIR\Gtk\CONTENTS" "Bundle Version " $0
  IfErrors 0 +3
  Push "3"
  Goto done

  ${VersionCompare} ${GTK_INSTALL_VERSION} $0 $1
  IntCmp $1 1 +3
  Push "0" ; Have a good version
  Goto done

  ${VersionCompare} ${GTK_MIN_VERSION} $0 $1
  IntCmp $1 1 +3
  Push "1" ; Optional Upgrade
  Goto done
  Push "2" ; Mandatory Upgrade
  Goto done

  done:
  ; The item on the stack is what we want to return
  Exch
  Pop $1
  Exch
  Pop $0
FunctionEnd


!macro RunCheckMacro UN
Function ${UN}RunCheck
  Push $R0
  Push $R1

  IntOp $R1 0 + 0
  retry_runcheck:
  ; Close the Handle (needed if we're retrying)
  IntCmp $R1 0 +2
    System::Call 'kernel32::CloseHandle(i $R1) i .R1'
  System::Call 'kernel32::CreateMutexA(i 0, i 0, t "pidgin++_is_running") i .R1 ?e'
  Pop $R0
  IntCmp $R0 0 +3 ;This could check for ERROR_ALREADY_EXISTS(183), but lets just assume
    MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION $(PIDGINISRUNNING) /SD IDCANCEL IDRETRY retry_runcheck
    Abort

  ; Close the Handle (If we don't do this, the uninstaller called from within will fail)
  ; This is not optimal because there is a (small) window of time when a new process could start
  System::Call 'kernel32::CloseHandle(i $R1) i .R1'

  Pop $R1
  Pop $R0
FunctionEnd
!macroend
!insertmacro RunCheckMacro ""
!insertmacro RunCheckMacro "un."

Function .onInit
  !ifdef X64_APPLICATION
  SetRegView 64
  !endif

  Push $R0
  Push $R1
  Push $R2
  Push $R3 ; This is only used for the Parameters throughout the function

  ${GetParameters} $R3

  IntOp $R1 0 + 0
  retry_runcheck:
  ; Close the Handle (needed if we're retrying)
  IntCmp $R1 0 +2
    System::Call 'kernel32::CloseHandle(i $R1) i .R1'
  System::Call 'kernel32::CreateMutexA(i 0, i 0, t "pidgin_installer_running") i .R1 ?e'
  Pop $R0
  IntCmp $R0 0 +3 ;This could check for ERROR_ALREADY_EXISTS(183), but lets just assume
    MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION $(INSTALLERISRUNNING) /SD IDCANCEL IDRETRY retry_runcheck
    Abort

  !ifdef X64_APPLICATION
    ${IfNot} ${RunningX64}
      MessageBox MB_OK|MB_ICONSTOP $(NOTWINDOWS64BIT) /SD IDOK
      Abort
    ${EndIf}
  !endif

  ; Allow installer to run even if pidgin is running via "/NOPIDGINRUNCHECK=1"
  ; This is useful for testing
  ClearErrors
  ${GetOptions} "$R3" "/NOPIDGINRUNCHECK=" $R1
  IfErrors 0 +2
  Call RunCheck

  StrCpy $name "Pidgin++ ${DISPLAY_VERSION} (${APPLICATION_BITNESS}-bit)"

  ;Try to copy the old Gaim installer Lang Reg. key
  ;(remove it after we're done to prevent this being done more than once)
  ClearErrors
  ReadRegStr $R0 HKCU "${PIDGIN_REG_KEY}" "${MUI_LANGDLL_REGISTRY_VALUENAME}"
  IfErrors 0 +5
  ClearErrors
  ReadRegStr $R0 HKCU "${OLD_GAIM_REG_KEY}" "${MUI_LANGDLL_REGISTRY_VALUENAME}"
  IfErrors +3
  DeleteRegValue HKCU "${OLD_GAIM_REG_KEY}" "${MUI_LANGDLL_REGISTRY_VALUENAME}"
  WriteRegStr HKCU "${PIDGIN_REG_KEY}" "${MUI_LANGDLL_REGISTRY_VALUENAME}" "$R0"

  ${MementoSectionRestore}

  ;Preselect the URI handlers as appropriate
  Call SelectURIHandlerSelections

  ;Preselect the "shortcuts" checkboxes according to the previous installation
  ClearErrors
  ;Make sure that there was a previous installation
  ReadRegStr $R0 HKCU "${PIDGIN_REG_KEY}" "${MUI_LANGDLL_REGISTRY_VALUENAME}"
  IfErrors done_preselecting_shortcuts
    ;Does the Desktop shortcut exist?
    GetFileTime "$DESKTOP\Pidgin++.lnk" $R0 $R0
    IfErrors +1 +5
    ClearErrors
    SetShellVarContext "all"
    GetFileTime "$DESKTOP\Pidgin++.lnk" $R0 $R0
    IfErrors preselect_startmenu_shortcut ;Desktop Shortcut if off by default
    !insertmacro SelectSection ${SecDesktopShortcut}
  preselect_startmenu_shortcut:
    ;Reset ShellVarContext because we may have changed it
    SetShellVarContext "current"
    ClearErrors
    ;Does the StartMenu shortcut exist?
    GetFileTime "$SMPROGRAMS\Pidgin++.lnk" $R0 $R0
    IfErrors +1 done_preselecting_shortcuts ;StartMenu Shortcut is on by default
    ClearErrors
    SetShellVarContext "all"
    GetFileTime "$SMPROGRAMS\Pidgin++.lnk" $R0 $R0
    IfErrors +1 done_preselecting_shortcuts ;StartMenu Shortcut is on by default
    !insertmacro UnselectSection ${SecStartMenuShortcut}
  done_preselecting_shortcuts:
  ;Reset ShellVarContext because we may have changed it
  SetShellVarContext "current"

  ClearErrors
  ${GetOptions} "$R3" "/L=" $R1
  IfErrors +3
  StrCpy $LANGUAGE $R1
  Goto skip_lang

  ; Select Language
    ; Display Language selection dialog
    !define MUI_LANGDLL_ALWAYSSHOW
    !insertmacro MUI_LANGDLL_DISPLAY
    skip_lang:

  ClearErrors
  ${GetOptions} "$R3" "/DS=" $R1
  IfErrors +8
  SectionGetFlags ${SecDesktopShortcut} $R2
  StrCmp "1" $R1 0 +2
  IntOp $R2 $R2 | ${SF_SELECTED}
  StrCmp "0" $R1 0 +3
  IntOp $R1 ${SF_SELECTED} ~
  IntOp $R2 $R2 & $R1
  SectionSetFlags ${SecDesktopShortcut} $R2

  ClearErrors
  ${GetOptions} "$R3" "/SMS=" $R1
  IfErrors +8
  SectionGetFlags ${SecStartMenuShortcut} $R2
  StrCmp "1" $R1 0 +2
  IntOp $R2 $R2 | ${SF_SELECTED}
  StrCmp "0" $R1 0 +3
  IntOp $R1 ${SF_SELECTED} ~
  IntOp $R2 $R2 & $R1
  SectionSetFlags ${SecStartMenuShortcut} $R2

  ; If install path was set on the command, use it.
  StrCmp $INSTDIR "" 0 instdir_done

  ;  If pidgin or gaim is currently installed, we should default to where it is currently installed
  ClearErrors
  ReadRegStr $INSTDIR HKCU "${PIDGIN_REG_KEY}" ""
  IfErrors +2
  StrCmp $INSTDIR "" 0 instdir_done
  ClearErrors
  ReadRegStr $INSTDIR HKLM "${PIDGIN_REG_KEY}" ""
  IfErrors +2
  StrCmp $INSTDIR "" 0 instdir_done

  Call CheckUserInstallRights
  Pop $R0

  StrCmp $R0 "HKLM" 0 user_dir
    !ifdef X64_APPLICATION
      StrCpy $INSTDIR "$PROGRAMFILES64\Pidgin++"
    !else
      StrCpy $INSTDIR "$PROGRAMFILES32\Pidgin++"
    !endif
    Goto instdir_done
  user_dir:
    Push $SMPROGRAMS
    ${GetParent} $SMPROGRAMS $R2
    ${GetParent} $R2 $R2
    StrCpy $INSTDIR "$R2\Pidgin++"

  instdir_done:
;LogSet on

  ; Try to select a translation and a dictionary for the currently selected Language
  Call SelectTranslationForCurrentLanguage

  ;Mark the dictionaries that are already installed as readonly
  Call SelectAndDisableInstalledDictionaries

  Pop $R3
  Pop $R2
  Pop $R1
  Pop $R0
FunctionEnd

Function .onInstSuccess

  ${MementoSectionSave}

FunctionEnd


Function un.onInit

  Call un.RunCheck
  StrCpy $name "Pidgin++ ${DISPLAY_VERSION} (${APPLICATION_BITNESS}-bit)"
;LogSet on

  ; Get stored language preference
  !insertmacro MUI_UNGETLANGUAGE

FunctionEnd

; Page enter and exit functions..

Function preWelcomePage
  Push $R0
  Push $R1

!ifdef OFFLINE_INSTALLER
    !insertmacro SelectSection ${SecDebugSymbols}
!endif

  Call DoWeNeedGtk
  Pop $CURRENT_GTK_STATE
  StrCpy $WARNED_GTK_STATE "0"
  IntCmp $CURRENT_GTK_STATE 1 done gtk_not_mandatory
    ; Make the GTK+ Section RO if it is required. (it is required only if you have an existing version that is too old)
    StrCmp $CURRENT_GTK_STATE "2" 0 done
    !insertmacro SetSectionFlag ${SecGtk} ${SF_RO}
    Goto done
  gtk_not_mandatory:
    ; Don't select the GTK+ section if we already have this version or newer installed
    !insertmacro UnselectSection ${SecGtk}

  done:
  Pop $R1
  Pop $R0
FunctionEnd

; If the GTK+ Section has been unselected and there isn't a compatible GTK+ already, confirm
Function .onSelChange
  Push $R0

  SectionGetFlags ${SecGtk} $R0
  IntOp $R0 $R0 & ${SF_SELECTED}
  ; If the Gtk Section is currently selected, reset the "Warned" flag
  StrCmp $R0 "${SF_SELECTED}" 0 +3
  StrCpy $WARNED_GTK_STATE "0"
  Goto done

  ; If we've already warned the user, don't warn them again
  StrCmp $WARNED_GTK_STATE "1" done
  IntCmp $CURRENT_GTK_STATE 1 done done 0
  StrCpy $WARNED_GTK_STATE "1"
  MessageBox MB_YESNO $(PIDGINPROMPTFORCENOGTK) /SD IDNO IDYES done
  !insertmacro SelectSection ${SecGtk}

  done:
  Pop $R0
FunctionEnd

Function SelectTranslationForCurrentLanguage
!insertmacro SELECT_TRANSLATION_FUNCTION
FunctionEnd

; SpellChecker Related Functions
;-------------------------------

; Select and Disable any Sections that have currently installed dictionaries
!macro CHECK_SPELLCHECK_SECTION lang
  ;Advance to the next (correct) section index
  IntOp $R0 $R0 + 1
  IfFileExists "$INSTDIR\spellcheck\share\enchant\myspell\${lang}.dic" 0 done_${lang}
  SectionGetFlags $R0 $R1
  IntOp $R1 $R1 | ${SF_RO} ; Mark Readonly
  IntOp $R1 $R1 | ${SF_SELECTED} ; Select
  SectionSetFlags $R0 $R1
  done_${lang}:
!macroend
Function SelectAndDisableInstalledDictionaries
  Push $R0
  Push $R1

  !insertmacro SetSectionFlag ${SecSpellCheck} ${SF_RO}
  !insertmacro UnselectSection ${SecSpellCheck}

  IntOp $R0 ${SecSpellCheck} + 0
  !include "pidgin-spellcheck-preselect.nsh"

  Pop $R1
  Pop $R0
FunctionEnd

!ifndef OFFLINE_INSTALLER
Function InstallDict
  Push $R0
  Exch
  Pop $R0 ;This is the language code
  Push $R1
  Exch 2
  Pop $R1 ;This is the language file
  Push $R2
  Push $R3
  Push $R4

  ClearErrors
  IfFileExists "$INSTDIR\spellcheck\share\enchant\myspell\$R0.dic" installed

  InitPluginsDir

  ; We need to download and install dictionary
  StrCpy $R2 "$PLUGINSDIR\$R1"
  StrCpy $R3 "${DOWNLOADER_URL}&dl_pkg=oo_dict&lang=$R1&lang_file=$R1"
  DetailPrint "Downloading the $R0 Dictionary... ($R3)"
  retry:
  NSISdl::download /TIMEOUT=10000 "$R3" "$R2"
  Pop $R4
  StrCmp $R4 "cancel" done
  StrCmp $R4 "success" +3
    MessageBox MB_RETRYCANCEL "$(PIDGINSPELLCHECKERROR)" /SD IDCANCEL IDRETRY retry IDCANCEL done
    Goto done
  SetOutPath "$INSTDIR\spellcheck\share\enchant\myspell"
  nsisunz::UnzipToLog "$R2" "$OUTDIR"
  SetOutPath "$INSTDIR"
  Pop $R3
  StrCmp $R3 "success" installed
    DetailPrint "$R3" ;print error message to log
    Goto done

  installed: ;The dictionary is currently installed, no error message
    DetailPrint "$R0 Dictionary is installed"

  done:
  Pop $R4
  Pop $R3
  Pop $R2
  Pop $R0
  Exch $R1
FunctionEnd
!endif

Function ShowChanges
  System::Call "Shell32::FindExecutable(t '${CHANGELOG}', i 0, t .r1) i .r2"
  ${If} $2 > 32
    !define LOCALE_SISO639LANGNAME "0x59"
    !define LOCALE_SISO3166CTRYNAME "0x5A"
    System::Call "kernel32::GetLocaleInfoA(i $LANGUAGE, i ${LOCALE_SISO639LANGNAME},  t .R0, i ${NSIS_MAX_STRLEN})"
    System::Call "kernel32::GetLocaleInfoA(i $LANGUAGE, i ${LOCALE_SISO3166CTRYNAME}, t .R1,  i ${NSIS_MAX_STRLEN})"
    Exec '"$1" "file:///${CHANGELOG}?full=true&lang=$R0_$R1"'
  ${Else}
    ExecShell "open" "${CHANGELOG}"
  ${EndIf}
FunctionEnd
