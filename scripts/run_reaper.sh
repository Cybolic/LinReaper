#!/bin/bash

# Convert relative to absolute path
appdir="$(cd "`dirname "$0"`"; pwd)"

print_help() {
	echo "Usage: `basename "$0"` [OPTION...] [FILE.rpp | FILE.wav]"
	echo -e "\nOptions:"
	echo -e "  -v, --version \t\t\t\tPrint the installed version number"
	echo -e "  -a, --audiocfg \t\t\t\tShow the audio configuration settings"
	echo -e "  -c, --cfgfile FILE \t\t\t\tLoad the specified config file"
	echo -e "  -n, --new \t\t\t\t\tOpen a new project, use FILE if specified"
	echo -e "  -r, --renderproject FILE \t\t\tRender the specified project"
	echo -e "  -t, --template FILE [-s, -saveas FILE]\tOpen a new project, using FILE as template"
	echo -e "  \t\t\t\t\t\t- optionally saving the new project as FILE"
	exit 0
}

SELFTEST=0
case "$1" in
	-h|--help|-help)
		print_help
		;;
	-s|--selftest|-selftest)
		SELFTEST=1
		;;
esac

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

#
# Underscore prefixed variables are only used in this block to determine the non-underscored ones
#

ProgramFiles='C:\\Program Files'
_PROGRAMFILES="$WINEPREFIX/drive_c/Program Files"
_winsysdir="$WINEPREFIX/drive_c/windows/profiles/$USERNAME/Application Data"
_PROFILESDIR="$WINEPREFIX/drive_c/windows/profiles"
_APPDATA="$WINEPREFIX/drive_c/windows/profiles/$USERNAME/Application Data"

if [ -d "$_PROGRAMFILES" ] || \
   [ -d "$_winsysdir" ] || \
   [ -d "$_PROFILESDIR" ] || \
   [ -d "$_APPDATA" ]; then
	APPDATA=$_APPDATA
else
	# Get the Windows paths from registry since they are different according to locale
	ProgramFiles="$(grep '"ProgramFiles"=' "$appdir/.wine/system.reg" | cut -d\" -f4- | cut -d\" -f1)"
	if [[ -z $(echo $ProgramFiles) ]]; then
		ProgramFiles="$(grep '"ProgramFilesDir"=' "$appdir/.wine/system.reg" | cut -d\" -f4- | cut -d\" -f1)"
		if [[ -z $(echo $ProgramFiles) ]]; then
			ProgramFiles='C:\Program Files'
			echo "WARNING: The system registry didn't contain the path to ProgramFiles, defaulting to \""$ProgramFiles'".'
		fi
	fi
	_winsysdir="$(grep '"winsysdir"=' "$appdir/.wine/system.reg" | cut -d\" -f4- | cut -d\" -f1)"
	_winsysdir="$("$appdir"/.winepath.sh -u "$_winsysdir")"
	_APPDATA="$(grep '"APPDATA"=' "$appdir/.wine/system.reg" | cut -d\" -f4- | cut -d\" -f1)"
	_LOCALAPPDATA="$(grep '"LOCALAPPDATA"=' "$appdir/.wine/system.reg" | cut -d\" -f4- | cut -d\" -f1)"
	_APPDATA="$(winepath -u "$_APPDATA")"
	_LOCALAPPDATA="$(winepath -u "$_LOCALAPPDATA")"
	_winsysdir="$("$appdir"/.winepath.sh -u "$_APPDATA")"

	_PROFILESDIR="$(dirname "`dirname "$APPDATA"`")"
	if [[ "$_PROFILESDIR" == "." ]]; then
		_PROFILESDIR="$(dirname "$(dirname "`dirname "$_LOCALAPPDATA"`")")"
	fi
	_APPDATANAME="$(basename "$_APPDATA")"

	_USERPROFILE="$PROFILESDIR/$USER"
	APPDATA="$_USERPROFILE/$_APPDATANAME"
fi

if [[ $SELFTEST == 1 ]]; then
	echo "ProgramFiles: "$ProgramFiles
	echo "winsysdir: "$_winsysdir
	echo "PROFILESDIR: "$_PROFILESDIR
	echo "APPDATA: "$APPDATA
	exit
fi
args="$@"

convert_path_to_win() {
	filename="$1"
	if [ "${filename:1:2}" = ':\' ]; then
		echo -n "$filename"
	else
		echo -n "$(winepath -w "$filename")"
	fi
}

print_version() {
	cat "$(winepath -u "$ProgramFiles"'\\REAPER')/whatsnew.txt" | cut -s -d\  -f1 | head -n1 | cut -dv -f2-
}

print_latest_changelog() {
	wget -qO - 'http://reaper.fm/whatsnew.txt'
}

print_latest_version() {
	print_latest_changelog | cut -s -d\  -f1 | head -n1 | cut -dv -f2-
}

check_for_new_version() {
	check=true
	# If there's a config file
	if [ -e "$APPDATA/REAPER/REAPER.ini" ]; then
		echo "Config exists"
		# and it has the option for checking for new version
		setting="$(cat "$APPDATA/REAPER/REAPER.ini" | grep -oE '^verchk=([01])' | cut -d= -f2)"
		# and that options says "don't check", then don't
		test "x$setting" = "x0" && check=false
	fi

	if $check; then
		if [[ "$(print_latest_version)" > "$(print_version)" ]]; then
			echo "Update!"
		fi
	fi
}

args=""

# If Reaper hasn't been set-up, do it
if [ ! -e "$HOME/.config/$(cat "$appdir/.configuration_dir")" ]; then
	if [ ! -e "$APPDATA/REAPER/REAPER.ini" ]; then
		"$appdir/.update_config.sh"

		test $# -eq 0 && args="'$ProgramFiles\\REAPER\\BradSucks_MakingMeNervous\\BradSucks_MakingMeNervous.RPP'"
	fi
fi


while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help|-help)
			print_help
			;;
		-v|--version)
			print_version
			exit 0
			;;
		-l|--latest-version)
			print_latest_version
			exit 0
			;;
		--check-version)
			check_for_new_version
			exit 0
			;;
		-a|--audiocfg)
			args+="-audiocfg "
			;;
		-c|--cfgfile)
			filename="$2"
			if [ -n "$filename" -a "${filename:0:1}" != "-" ]; then
				filename="`convert_path_to_win "$filename"`"
				args+="-cfgfile $filename "
				shift
				shift
			else
				echo "Usage: `basename "$0"` --cfgfile FILE"
				exit
			fi
			;;
		-n|--new)
			args+="-new "
			filename="$2"
			if [ -n "$filename" -a "${filename:0:1}" != "-" ]; then
				args+="'`convert_path_to_win "$2"`'"
				shift
				shift
			fi
			;;
		-r|--renderproject)
			filename="$2"
			if [ -n "$filename" -a "${filename:0:1}" != "-" ]; then
				filename="`convert_path_to_win "$2"`"
				args+="-renderproject '$filename' "
				shift
				shift
			else
				echo "Usage: `basename "$0"` --renderproject FILE"
				exit
			fi
			;;
		-t|--template)
			filename="$2"
			if [ -n "$filename" -a "${filename:0:1}" != "-" ]; then
				filename="`convert_path_to_win "$2"`"
				args+="-renderproject '$filename' "
				shift
				shift
				if [ "$1" = "-s" -o "$1" = "--saveas" ]; then
					filename="$2"
					if [ -n "$filename" -a "${filename:0:1}" != "-" ]; then
						filename="`convert_path_to_win "$2"`"
						args+="-saveas '$filename' "
						shift
						shift
					else
						echo "Usage: `basename "$0"` --template FILE --saveas FILE"
						exit
					fi
				fi
			else
				echo "Usage: `basename "$0"` --renderproject FILE"
				exit
			fi
			;;
		-s|--saveas)
			echo "Usage: `basename "$0"` --template FILE --saveas FILE"
			exit
			;;
		*)
			args+="'`convert_path_to_win "$1"`' "
			;;
		esac
	shift # Check next set of parameters.
done

# Remove trailing space
#args="${args:0:`expr length "$args" - 1`}"

#if [ $("$appdir/.update_checker.py"; echo $?) == 255 ]; then

eval "wine '$ProgramFiles\REAPER\Reaper.exe' $args"

