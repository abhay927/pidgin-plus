# Changelog for Pidgin++

This is the detailed changelog for Pidgin++. For a more general list of changes
targeted at end users, please see the XML changelog or its resulting formats.


## 15.1

**All platforms**
* Upstream version 2.10.11.
* New text colors and formatting.
* Maximizable and larger log viewer.
* Formatted IRC channel URLs ([#15248][3]).
* Configurable IRC quit and part messages.
* Formatted timestamps in ZNC buffer playback.
* Typed message history browsing with just the arrow keys.
* New about dialog.
* Application renamed from Pidgin to Pidgin++.
* Reply `CTCP VERSION` with Pidgin++.
* Version pattern changed from RSxxx to year.minor.micro.
* Changes to the build process:
    - New Markdown export for the XML changelog.
    - Changed a couple of language codes:
        - ms_MY is now ms.
        - my_MM is now my.

**Windows**
* Support for 64-bit.
* GTK+ updated from 2.16.6 to 2.24.25.
* Several GTK+ dependencies also updated.
* Automated update checking with WinSparkle.
* New plugins irchelper and ircaway.
* Toggle buddy list intelligently on tray icon click.
* Fixed debug symbols download.
* Really offline installer ([#14970][7]).
* GTK+ runtime included with the main installer.
* Debug symbols removed from the main installer.
* Unused GTK+ locales no longer get installed.
* Language and protocol names in the installer.
* Uninstaller now fully removes subdirectories.
* Build date in the installer and the about dialog.
* Copyright list and license text added to installation.
* Libraries manifest added to installation.
* New logos in the installer.
* Compiled with newer GCC 4.9.
* Improvements to the build process:
    - Colored output.
    - Faster handling of the staging directory.
    - Generation of full source code bundles ([#16502][8]).
    - Creation of the build environment (with Pidgin Windev).
    - Migration from MinGW to MSYS2:
        - The provided GTK+ and many other dependencies are now used.
        - The new option --pkgbuild now allows creating a pacman package.
    - Fixed some macro redefinitions in MinGW-w64.
    - Website added to code repository.
    - Other general improvements.
* Code signed with Microsoft Authenticode:
    - Use the newer signtool instead of signcode.
    - Sign with PKCS #12 / PFX certificate instead of SPC/PVK pair.
    - Prompt only once for the certificate and GPG passwords.


## RS137

Summarized differences between the first release and Pidgin 2.10.9.

**All platforms**
* New tray icons.
* New status icons.
* Refined buddy list appearance.
* Wider non-ellipsized labels for side-aligned conversation tabs ([#15347][5]).
* Load account icon from config dir for relative paths ([#15348][4]).
* Avoid printing IRC channel URLs ([#15248][3]).

**Windows**
* Better Unicode support ([#604][2]).
* Single click support on system tray ([#1458][1]).
* Refined GTK+ theme.


[1]: https://developer.pidgin.im/ticket/1458
[2]: https://developer.pidgin.im/ticket/604
[3]: https://developer.pidgin.im/ticket/15248
[4]: https://developer.pidgin.im/ticket/15348
[5]: https://developer.pidgin.im/ticket/15347
[6]: https://developer.pidgin.im/ticket/16285
[7]: https://developer.pidgin.im/ticket/14970
[8]: https://developer.pidgin.im/ticket/16502
