#!/bin/bash

# Convert relative to absolute path
tempdir="$(cd "`dirname "$0"`"; pwd)"
appdir="$(cd "$1"; pwd)"

if [ -n "$LD_LIBRARY_PATH" ]; then
	LD_LIBRARY_PATH="$appdir/.winelib:$LD_LIBRARY_PATH"
else
	LD_LIBRARY_PATH="$appdir/.winelib"
fi
export LD_LIBRARY_PATH

if [ -n "$WINEDLLPATH" ]; then
	WINEDLLPATH="$appdir/.winelib:$appdir/.winelib:$WINEDLLPATH"
else
	WINEDLLPATH="$appdir/.winelib:$appdir/.winelib"
fi
export WINEDLLPATH

if [ -d "$appdir" ]; then
	if [ -d "$appdir/.winelib" ]; then
		echo "Installing WineAsio to the Reaper installation dir."
		
		cp "$tempdir/wineasio-0.8.0.dll.so" "$appdir/.winelib/wineasio.dll.so"
		
		env HOME="$appdir" regsvr32 "$appdir/.winelib/wineasio.dll.so"
		# If it failed, ask permission to install WineAsio to /usr/lib/wine
		if [ $? != 0 ]; then
			echo -n "Asking permission to install WineAsio system-wide instead"
			if which zenity &> /dev/null; then
				echo "."
				if zenity --question --text="WineAsio failed to install to the local Reaper installation.\nWould you like to install WineAsio version 0.7.4 to /usr/lib/wine instead?\n\nNote that this will require your administrator password." --ok-label="Ok, install system wide" --cancel-label="No thanks"; then
					gksu --description "LinReaper WineAsio installation" cp "$tempdir/wineasio-0.7.4.dll.so" "/usr/lib/wine/wineasio.dll.so"
					regsvr32 wineasio.dll
				fi
			else
				echo -e "... failed.\nZenity isn't installed, can't ask.\n\nIf you want to install WineAsio system-wide, run the following commands from a terminal:\n\tsudo cp \"$appdir/.winelib/wineasio.dll.so\" /usr/lib/wine/\n\tregsvr32 wineasio.dll"
			fi
		fi
	fi
else
	echo "ERROR: The install directory is missing, can't continue."
	exit 1
fi
