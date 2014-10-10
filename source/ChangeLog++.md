# Pidgin++ changelog

This is the list of changes between Pidgin++ versions. For the differences
between Pidgin and Pidgin++, please see the XML changelog.


## RS243

**All platforms**
* New text colors and formatting.
* Maximizable and larger log viewer.
* Changed order of the help menu.
* Changed website URLs to:
    - http://pidgin.renatosilva.me
    - http://launchpad.net/pidgin++
* Changed a couple of language codes:
    - ms_MY is now ms.
    - my_MM is now my.

**Windows**
* GTK+ updated from 2.16.6 to 2.24.24.
* Several GTK+ dependencies also updated.
* Fixed debug symbols download.
* Really offline installer ([#14970][7]).
* Really open source ([#16285][6]).
* Unused GTK+ locales no longer get installed.
* Language and protocol names in the installer.
* Uninstaller now fully removes subdirectories.
* Compiled with GCC 4.9.0 instead of 4.7.2.
* Improvements to the build process:
    - Colored output.
    - Faster handling of the staging directory.
    - Generation of the source code bundle.
    - Creation of the build environment (with Pidgin Windev).
    - Fixed some macro redefinitions in MinGW-w64.
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
