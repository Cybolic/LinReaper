#!/bin/bash

# Convert relative to absolute path
appdir="$(cd "`dirname "$0"`"; pwd)"

WINEPREFIX="$appdir/.wine"
export WINEPREFIX

WINEDEBUG="fixme-all"
export WINEDEBUG

######################################################################
###  Make sure that the VST installer gets the right VST directory ###

# Get the Windows paths from registry since they are different according to locale
eval ProgramFiles="$(less "$appdir/.wine/system.reg" | grep '"ProgramFiles"=' | cut -d= -f2-)"
UnixProgramFiles="$(winepath -u "$ProgramFiles")"

UnixVSTPath="$(cd "$appdir/.wine/drive_c/windows/profiles/$USER/My Documents/.config/reaper/vst/"; pwd -P)"

# Create registry keys for the correct VST install path
registryfile="$(tempfile -s .reg)"

echo "Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\\Software\\VST]
\"VSTPluginsPath\"=\"C:\\\\windows\\\\profiles\\\\$USER\\\\My Documents\\\\.config\\\\reaper\\\\vst\"
[HKEY_LOCAL_MACHINE\\Software\\VST]
\"VSTPluginsPath\"=\"C:\\\\windows\\\\profiles\\\\$USER\\\\My Documents\\\\.config\\\\reaper\\\\vst\"" > "$registryfile"


regedit "$registryfile"
VST_PATH="C:\\windows\\profiles\\$USER\\My Documents\\.config\\reaper\\vst"
export VST_PATH

# Make Shell Pattern Matching case-insensitive, so we are sure to find the Steinberg path
shopt -s nocaseglob
# If there is no Steinberg VST path, then we link to LinReapers
#   The "[s]" causes bash to use Pattern Matching, and so, be case-insensitive.
if [ ! -e "$UnixProgramFiles/Steinberg/VstPlugin"[s] ]; then
	if [ ! -e "$UnixProgramFiles/Steinber"[g] ]; then
		mkdir -p "$UnixProgramFiles/Steinberg"
	fi
	ln -s "$UnixVSTPath" "$UnixProgramFiles/Steinberg/VstPlugins"
fi

###  Made sure that the VST installer gets the right VST directory ###
######################################################################


# Run the VST installer
if [ "$(echo ${1/*./} | tr [:upper:] [:lower:])" == "msi" ]; then
	wine start /Unix "$1"
else
	wine "$1"
fi
