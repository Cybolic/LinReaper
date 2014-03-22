#!/bin/bash

# Convert relative to absolute path
appdir="$(cd "`dirname "$0"`"; pwd)"

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
eval ProgramFiles="$(less "$appdir/.wine/system.reg" | grep '"ProgramFiles"=' | cut -d= -f2-)"
#ProgramFiles="$(winepath -u "$ProgramFiles")"
eval winsysdir="$(less "$appdir/.wine/system.reg" | grep '"winsysdir"=' | cut -d= -f2-)"
winsysdir="$(winepath -u "$winsysdir")"
eval APPDATA="$(less "$appdir/.wine/system.reg" | grep '"APPDATA"=' | cut -d= -f2-)"
APPDATA="$(winepath -u "$APPDATA")"

PROFILESDIR="$(dirname "`dirname "$APPDATA"`")"
APPDATANAME="$(basename "$APPDATA")"

USERPROFILE="$PROFILESDIR/$USER"
APPDATA="$USERPROFILE/$APPDATANAME"


args="$@"

convert_path_to_win() {
	filename="$1"
	if [ "${filename:1:2}" = ':\' ]; then
		echo -n "$filename"
	else
		echo -n "$(winepath -w "$filename")"
	fi
}

args=""

# If Reaper hasn't been set-up, do it
if [ ! -e "$HOME/.config/$(cat "$appdir/.configuration_dir")" ]; then
	if [ ! -e "$APPDATA/REAPER/REAPER.ini" ]; then
		"$appdata/.update_config.sh"
		
		test $# -eq 0 && args="'$ProgramFiles\REAPER\BradSucks_MakingMeNervous\BradSucks_MakingMeNervous.RPP'"
	fi
fi

while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help|-help)
			echo "Usage: `basename "$0"` [OPTION...] [FILE.rpp | FILE.wav]"
			echo -e "\nOptions:"
			echo -e "  -a, --audiocfg \t\t\t\tShow the audio configuration settings"
			echo -e "  -c, --cfgfile FILE \t\t\t\tLoad the specified config file"
			echo -e "  -n, --new \t\t\t\t\tOpen a new project, use FILE if specified"
			echo -e "  -r, --renderproject FILE \t\t\tRender the specified project"
			echo -e "  -t, --template FILE [-s, -saveas FILE]\tOpen a new project, using FILE as template"
			echo -e "  \t\t\t\t\t\t- optionally saving the new project as FILE"
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

eval "wine '$ProgramFiles\REAPER\Reaper.exe' $args"
