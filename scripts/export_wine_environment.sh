#!/bin/bash

appdir="$1"

convert_path_to_unix() {
	path="$1"
	echo "$(winepath -u "$path")"
	# There's nothing wrong with the following code, except that it doesn't take into account
	# Wine drives other than C: and winepath does - this code, however, does not fail on a missing directory
	# which might or might not be a good thing
	#c="$(basename "$WineC")"
	#echo "$appdir/.wine/dosdevices/$(echo "$path" | tr '\\' '\/' | sed "s/C:/$c/i" | tr -s '/')"
}

get_path_from_registry() {
	path="$1"
	path="$(cat "$appdir/.wine/system.reg" | grep "\"$path\"=" | cut -d= -f2-)"
	echo "${path:1:`expr length "$path" - 2`}"
}
get_path_from_user_registry() {
	path="$1"
	path="$(cat "$appdir/.wine/user.reg" | sed -n '/\\Shell Folders/,/\[/p' | grep "\"$path\"=" | cut -d= -f2-)"
	echo "${path:1:`expr length "$path" - 2`}"
}

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

WINEDEBUG="fixme-all"
export WINEDEBUG

# Get the Windows paths from registry since they are different according to locale
WineC="$(winepath -u 'C:\')"
ProgramFiles="$(get_path_from_registry "ProgramFiles")"
ProgramFilesUnix="$(convert_path_to_unix "$ProgramFiles")"
SysDir="$(get_path_from_registry "winsysdir")"
SysDirUnix="$(convert_path_to_unix "$SysDir")"
AppData="$(get_path_from_registry "APPDATA")"
AppDataUnix="$(convert_path_to_unix "$AppData")"
WinDesktop="$(get_path_from_user_registry "Desktop")"
WinDesktopUnix="$(convert_path_to_unix "$WinDesktop")"
WinMyDocuments="$(get_path_from_user_registry "Personal")"
WinMyDocumentsUnix="$(convert_path_to_unix "$WinMyDocuments")"
WinMyMusic="$(get_path_from_user_registry "My Music")"
WinMyMusicUnix="$(convert_path_to_unix "$WinMyMusic")"
WinMyPictures="$(get_path_from_user_registry "My Pictures")"
WinMyPicturesUnix="$(convert_path_to_unix "$WinMyPictures")"
WinMyVideos="$(get_path_from_user_registry "My Videos")"
WinMyVideosUnix="$(convert_path_to_unix "$WinMyVideos")"

ProfilesDirUnix="$(dirname "`dirname "$AppDataUnix"`")"
AppDataBase="$(basename "$AppDataUnix")"

UserProfileUnix="$ProfilesDirUnix/$USER"
AppDataUnix="$UserProfileUnix/$AppDataBase"

export ProgramFiles ProgramFilesUnix
export SysDir SysDirUnix
export ProfilesDirUnix
export AppDataBase
export AppData AppDataUnix
export UserProfileUnix
export WinDesktop WinDesktopUnix
export WinMyDocuments WinMyDocumentsUnix
export WinMyMusic WinMyMusicUnix
export WinMyPictures WinMyPicturesUnix
export WinMyVideos WinMyVideosUnix
