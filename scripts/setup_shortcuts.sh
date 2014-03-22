#!/bin/sh

# Convert relative to absolute path
appdir="$(cd "$1"; pwd)"

if [ ! -d "$appdir/.wine" ]; then
	echo "ERROR: Reaper doesn't seem to be properly installed."
	exit 1
fi

reaperdesktopfile="[Desktop Entry]
Categories=AudioVideo
Encoding=UTF-8
Name=Reaper
GenericName=Digital Audio Workstation
Comment=Audio production without limits
Type=Application
Terminal=False
Exec=$appdir/reaper.sh
Icon=reaper
MimeType=application/x-reaper-project;application/x-reaper-project-backup;application/x-reaper-peakfile;"

vsttooldesktopfile="[Desktop Entry]
Categories=AudioVideo
Encoding=UTF-8
Name=LinReaper Options
Comment=Manage your LinReaper Reaper installation
Type=Application
Terminal=False
Exec=$appdir/linreapercfg.py
Icon=reaper"


echo "Installing menu shortcuts and file associations."

if [ ! -e "$HOME/.local/share/applications" ]; then
	mkdir -p "$HOME/.local/share/applications";
fi
echo "$reaperdesktopfile" > "$HOME/.local/share/applications/Reaper.desktop"
echo "$vsttooldesktopfile" > "$HOME/.local/share/applications/LinReaperCfg.desktop"

if [ -e "$HOME/.local/share/applications/VSTTool.desktop" ]; then
	rm "$HOME/.local/share/applications/VSTTool.desktop"
fi

update-desktop-database "$HOME/.local/share/applications"
