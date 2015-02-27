# Changelog for Pidgin++

This is the detailed changelog for Pidgin++. For a more general list of changes
targeted at end users, please see the XML changelog or its resulting formats.


## 15.1

Differences between the first release and Pidgin 2.10.11.

**All platforms**
* New text colors and formatting.
* Maximizable and larger log viewer.
* Formatted IRC channel URLs ([#15248][3]).
* Configurable IRC quit and part messages.
* Formatted timestamps in ZNC buffer playback.
* Typed message history browsing with just the arrow keys.
* New tray and status icons.
* Refined buddy list appearance.
* Wider non-ellipsized labels for side-aligned conversation tabs ([#15347][5]).
* Load account icon from config dir for relative paths ([#15348][4]).

**Windows**
* Support for 64-bit.
* GTK+ updated from 2.16.6 to 2.24.25.
* Several GTK+ dependencies also updated.
* Automated update checking with WinSparkle.
* New plugins irchelper and ircaway.
* Intelligent buddy list toggling on tray icon click ([#1458][1]).
* Really offline installer ([#14970][7]).
* GTK+ runtime included with the main installer.
* Debug symbols removed from the main installer.
* Unused GTK+ locales no longer get installed.
* Language and protocol names in the installer.
* Uninstaller now fully removes subdirectories.
* Build date in the installer and the about dialog.
* Copyright list and license text added to installation.
* Library manifest and licenses added to installation.
* Better Unicode support ([#604][2]).
* Refined GTK+ theme.
* Compiled with newer GCC 4.9.
* Improvements to the build process:
    - New Windows build script with flexible options.
    - Generation of full source code bundles ([#16502][8]).
    - Creation of the build environment (with Pidgin Windev).
    - Migration from MinGW to MSYS2.
    - Other general improvements.
* Code signed with Microsoft Authenticode:
    - Use the newer signtool instead of signcode.
    - Sign with PKCS #12 / PFX certificate instead of SPC/PVK pair.
    - Prompt only once for the certificate and GPG passwords.


[1]: https://developer.pidgin.im/ticket/1458
[2]: https://developer.pidgin.im/ticket/604
[3]: https://developer.pidgin.im/ticket/15248
[4]: https://developer.pidgin.im/ticket/15348
[5]: https://developer.pidgin.im/ticket/15347
[6]: https://developer.pidgin.im/ticket/16285
[7]: https://developer.pidgin.im/ticket/14970
[8]: https://developer.pidgin.im/ticket/16502
