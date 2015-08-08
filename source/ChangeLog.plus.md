# Changelog for Pidgin++

This is the detailed changelog for Pidgin++. For a more general list of changes
targeted at end users, please see the XML changelog or its resulting formats.


## 15.1

Differences between the first release and Pidgin 2.10.11.

**All platforms**
* New tray and status icons.
* Refined buddy list appearance.
* New text colors and formatting.
* Typed message history browsing with just the arrow keys.
* Maximizable and larger log viewer.
* URI handler for the IRC protocol ([#3692][8]).
* Configurable IRC quit and part messages.
* Highlighting of unknown IRC numerics as system messages.
* Formatted timestamps in ZNC buffer playback.
* Formatted IRC channel URLs ([#15248][1]).
* Wider non-ellipsized labels for side-aligned conversation tabs ([#15347][2]).
* Load account icon from config dir for relative paths ([#15348][3]).

**Windows**
* Support for 64-bit.
* Automated update checking with WinSparkle.
* GTK+ updated from 2.16 to 2.24.
* Several other dependencies also updated.
* Refined GTK+ theme.
* Better Unicode support ([#604][4]).
* Intelligent buddy list toggling on tray icon click ([#1458][5]).
* New plugins irchelper and ircaway.
* GTK+ runtime included with the main installer.
* Debug symbols removed from the main installer.
* Really offline installer ([#14970][6]).
* Unused GTK+ locales no longer get installed.
* Language and protocol names in the installer.
* Uninstaller now fully removes subdirectories.
* Build date in the installer and the about dialog.
* Copyright list and license text added to installation.
* Library manifest and licenses added to installation.
* Improvements to the build process:
    - New Windows build script with flexible options.
    - Generation of full source code bundles ([#16502][7]).
    - Preparation of the build environment.
    - Migration from MinGW to MSYS2.
    - Other general improvements.
* Code signed with Microsoft Authenticode:
    - Use the newer signtool instead of signcode.
    - Sign with PKCS #12 / PFX certificate instead of SPC/PVK pair.
    - Prompt only once for the certificate and GPG passwords.


[1]: https://developer.pidgin.im/ticket/15248
[2]: https://developer.pidgin.im/ticket/15347
[3]: https://developer.pidgin.im/ticket/15348
[4]: https://developer.pidgin.im/ticket/604
[5]: https://developer.pidgin.im/ticket/1458
[6]: https://developer.pidgin.im/ticket/14970
[7]: https://developer.pidgin.im/ticket/16502
[8]: https://developer.pidgin.im/ticket/3692
