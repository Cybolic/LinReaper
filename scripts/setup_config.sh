#!/bin/sh

# Convert relative to absolute paths
appdir="$(cd "$1"; pwd)"

WINEPREFIX="$appdir/.wine"
export WINEPREFIX

# Get the Windows paths from registry since they are different according to locale
eval ProgramFiles="$(less "$appdir/.wine/system.reg" | grep '"ProgramFiles"=' | cut -d= -f2-)"
ProgramFiles="$(winepath -u "$ProgramFiles")"
eval APPDATA="$(less "$appdir/.wine/system.reg" | grep '"APPDATA"=' | cut -d= -f2-)"
APPDATA="$(winepath -u "$APPDATA")"

if [ -d "$appdir/.wine" ]; then
	
	configpath="$APPDATA/REAPER"
	programpath="$ProgramFiles/REAPER"
	
	echo "Setting up Reaper installation directory."
	# if $appdir/reaper doesn't exist
	if [ ! -e "$appdir/reaper" ]; then
		# Link C:\Program Files\REAPER to $appdir/reaper
		ln -s "$programpath" "$appdir/reaper"
	fi
	for dir in "ColorThemes" "Data" "Effects" "KeyMaps" "Plugins"; do
		# if $appdir/$dir doesn't exist
		if [ ! -e "$appdir/$dir" ]; then
			# Link $appdir/reaper/$dir to $appdir/$dir
			ln -s "$appdir/reaper/$dir" "$appdir/$dir"
		fi
	done
else
	echo "ERROR: Installation is borked: No .wine directory."
	exit 1
fi
