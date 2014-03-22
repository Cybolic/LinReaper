#!/bin/bash

# Convert relative to absolute path
appdir="$(cd "`dirname "$0"`"; pwd)"

if [ ! -e "$HOME/.config/reaper/vst" ]; then
	mkdir "$HOME/.config/reaper/vst"
fi

if [ -z "$1" ]; then
	exit
elif [ "$1" == "__RENDER__" ]; then
	exec "$appdir/reaper.sh" --renderproject "$2"
elif [ "$1" == "__AUDIOCONF__" ]; then
	exec "$appdir/reaper.sh" --audiocfg
elif [ "$1" == "__CONF__" ]; then
	exec "$appdir/reaper.sh" --cfgfile "$2"
elif [ "$1" == "__VSTFOLDER__" ]; then
	exec xdg-open "$HOME/.config/reaper/vst/"
elif [ "$1" == "__JSFOLDER__" ]; then
	exec xdg-open "$appdir/Effects/"
elif [ "$1" == "__WINECFG__" ]; then
	exec env HOME="$appdir" winecfg
elif [ "$1" == "__REGEDIT__" ]; then
	exec env HOME="$appdir" regedit
else
	exec "$appdir/.vst_installer.sh" "$1"
fi
