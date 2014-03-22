LinReaper
=========

Reaper installer for Linux

LinReaper will do the following for you:

* Automatically downloads and installs the newest Reaper version available from the website, or installs from a previously downloaded Reaper installation exe.
* Installs Reaper in a bottled Wine directory (does not mess with the rest of your system)
* Sets up a local installation of WineAsio (again does not mess with the rest of your system)
* Registers file types of .rpp, rpp.bak and .reapeak files (with custom icons), so you can simply double click Reaper files
* Sets up a wrapper script around Reaper enabling it to accept normal UNIX command-line options and paths
* Sets up a wrapper script around Reaper to transform Reaper's configuration files to follow Unix/Freedesktop guidelines and allow automatic multi-user configurations
* Minimally configures the Reaper preferences for better Linux operation
* Optionally creates menu shortcuts
* Includes a tool (LinReaper Options) for installing and managing your Windows VSTs, JS effects, using Reapers more esoteric options and for advanced configuration of Wine
* Intelligently links the Wine folders "Desktop", "My Documents", "My Music", "My Pictures" and "My Videos" to their Linux counterparts

In many regards, LinReaper is similar to Google's Picassa Linux port.

Requirements
============

LinReaper requires Wine, Python, PyGTK (most distributions have these) and likes to also have the full 7Zip (p7zip-full in Ubuntu/Kubuntu/Xubuntu/Mint)

Use
===

To use, double click the downloaded file and select "Run" if asked - you might also need to make the file executable by right clicking it and selecting Properties then the Permissions tab and checking "Allow executing file as a program".

Installation Overview
=====================

LinReaper installs the following in the selected install directory:

Custom files and folders:

Path                  | Description
----------------------|------------
.wine/                | standard wine configuration folder, same as would normally appear in $HOME/.wine
.winelib/             | added wine dlls, currently only wineasio.dll.so lives here
$HOME/.config/reaper  | a symbolic link to C:\Windows\Profiles\$USER\Application Data\REAPER (or C:\Users\$USER\Application Data\REAPER depending on the version of Wine)
icon.png              | the Reaper icon
reaper.sh             | the Reaper launch script

Files and folders added by Wine on install

Path           | Description
---------------|------------
.config        | directory added by Wine on initial install to sandbox it from $HOME
.local         | directory added by Wine on initial install to sandbox it from $HOME
REAPER.desktop | added by Wine on initial install to sandbox it from $HOME