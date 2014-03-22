#!/bin/bash

# Convert relative to absolute paths
tempdir="$(cd "`dirname "$0"`"; pwd)"
if [ -z "$2" ]; then
	installexe="/tmp/linreaper-reaper-install.exe"
else
	installexe="$2"
fi

if [ ! -d "$1" ]; then
	echo -n "Creating directory $1"

	mkdir "$1"
	echo "."
else
	echo "Install directory already exists."
fi
appdir="$(cd "$1"; pwd)"


if [ ! -d "$appdir/.winelib" ]; then mkdir "$appdir/.winelib"; fi
if [ ! -d "$appdir/.wine" ]; then mkdir "$appdir/.wine"; fi

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

WINEPREFIX="$appdir/.wine"
export WINEPREFIX

echo "Creating Wine directory"
#env HOME="$appdir" wineprefixcreate
env HOME="$appdir" regedit /E /tmp/.linreaper_prefix_created 'HKEY_CURRENT_USER\Software\Wine'

echo -n "Waiting for registry files to be created..."
while [ ! -f "$appdir/.wine/system.reg" ]; do
	sleep 0
done
echo " Done."

# Function to get a value from the system registry and convert it to a UNIX path
pathfromreg() {
	WinPath="$(less "$appdir/.wine/system.reg" | grep "\"$1\"=" | cut -d= -f2-)"
	test "${WinPath:0:1}" = '"' && WinPath="$(echo ${WinPath:1:${#WinPath}-2})"
	winepath -u "$WinPath"
}

# Get the Windows paths from registry since they are different according to locale
ProgramFiles="$(pathfromreg "ProgramFiles")"
winsysdir="$(pathfromreg "winsysdir")"
APPDATA="$(pathfromreg "APPDATA")"
PROFILESDIR="$(dirname "`dirname "$APPDATA"`")"
USERPROFILE="$PROFILESDIR/$USER"


runinstall=1
# If 7zip is installed, bypass the installer and install Reaper ourselves
if 7za --help &> /dev/null ; then
	echo "7zip installed, bypassing installer"
	echo "Installing Reaper into it"
	7z x -y -o"$ProgramFiles"/REAPER "$installexe"
	if [ "$?" != 0 ]; then
		echo "Extracting from exe failed, running installer instead"
	else
		runinstall=0
		mv "$ProgramFiles/REAPER/\$SYSDIR"/* "$winsysdir"/
		rmdir "$ProgramFiles/REAPER/\$SYSDIR"
		chmod +x "$ProgramFiles/REAPER"/*.exe
	fi
fi

if [ $runinstall == 1 ]; then
	echo "Running the installer"
	env HOME="$appdir" wine "$installexe"
	if [ "$?" != 0 ]; then
		echo "Running the installer failed. Cancelling install."
		exit 1
	fi
fi


if [ -d "$appdir/.wine" ]; then
	# Copy LinReaper tools to the install dir
	cp "$tempdir/run_reaper.sh" "$appdir/reaper.sh"
	chmod +x "$appdir/reaper.sh"
	cp "$tempdir/REAPER.ini.sh" "$appdir/.REAPER.ini.default.sh"

	cp "$tempdir/conftool.sh" "$appdir/.conftool.sh"
	cp "$tempdir/vst_installer.sh" "$appdir/.vst_installer.sh"
	cp "$tempdir/conf.glade" "$appdir/.conf.glade"
	cp "$tempdir/vst.svg" "$appdir/.vst.svg"
	cp "$tempdir/js.svg" "$appdir/.js.svg"
	cp "$tempdir/linreapercfg.py" "$appdir/linreapercfg.py"
	chmod +x "$appdir/.conftool.sh" "$appdir/.vst_installer.sh" "$appdir/linreapercfg.py"

	cp "$tempdir/export_wine_environment.sh" "$appdir/.export_wine_environment.sh"
	cp "$tempdir/update_config.sh" "$appdir/.update_config.sh"

	# Setup the Reaper installation for the current user
	# to save time on the first run (only if this is first time install)
	if [ -d "$tempdir/gnome" ]; then
		"$appdir/.update_config.sh"

		# Setup shortcuts and icons
		cp -R "$tempdir/gnome" "$HOME/.icons/"
		if [ ! -d "$HOME/.local/share/mime/packages" ]; then
			mkdir -p "$HOME/.local/share/mime/packages"
		fi
		if [ ! -d "$HOME/.local/share/applications" ]; then
			mkdir -p "$HOME/.local/share/applications"
		fi
		cp "$tempdir/mimetype.xml" "$HOME/.local/share/mime/packages/reaper.xml"
		update-mime-database "$HOME/.local/share/mime"
		update-desktop-database "$HOME/.local/share"
		update-desktop-database "$HOME/.local/share/applications"
		# Make C:\Windows\Profiles read/writable for everyone, so all users can save their settings.
		# Remember that the Profiles dir will not contain important directories, only symlinks to
		# users ~/.config/reaper dirs, so security should be fine.
		chmod a+rw "$PROFILESDIR"
	fi
else
	echo "ERROR: It seems Wine didn't get run. Are you sure you have Wine installed?"
	exit 1
fi

