![](https://i.imgur.com/Ki5bX0I.gif)

English

## About

MineOS is a GUI based operating system for the OpenComputers Minecraft mod. It has extensive customisation abilities as well as an app market to publish your creations among the OS community. For developers there is wonderful [illustrated wiki](https://github.com/IgorTimofeev/MineOS/wiki) with lots of code examples. List of main features:

-   Multitasking
-   Double buffered graphical user interface
-   Language packs and software localization
-   Multiple user profiles with password authentication
-   Own EEPROM firmware with boot volume choose/format/rename features and Internet Recovery mode
-   File sharing over the local network via modems
-   Client connections to real FTP servers
-   An internal IDE with syntax highlighting and debugger
-   Integrated application and library App Market with the ability to publish your own scripts and programs for every MineOS user
-   Error reporting system with the possibility to send information to developers
-   Animations, wallpapers, screensavers, color schemes and huge customization possibilities
-   Open source system API and detailed documentation

## How to install?

The easiest way is to use default **wget** script. Insert an OpenOS floppy disk to computer, insert an Internet Card, turn computer on and type the following to console to install MineOS:

	wget -f https://raw.githubusercontent.com/An-Unnamed-Developer/MineOS-Lite/master/Installer/BIOS.lua /tmp/bios.lua && flash -q /tmp/bios.lua && reboot

You can paste it to console using middle mouse button or insert key (by default). After a moment, a nice system installer will be shown. You will be prompted to select your preferred language, boot volume (can be formatted if needed), create a user profile and customize some settings

## How to create applications and work with API?

[Wiki](https://github.com/IgorTimofeev/MineOS/wiki)
