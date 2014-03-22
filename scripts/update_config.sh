#!/bin/bash

# Convert relative to absolute path
appdir="$(cd "`dirname "$0"`"; pwd -P)"

source "$appdir/.export_wine_environment.sh" "$appdir"


# Name of the dir in $HOME/.config/
# Defaults to the basename of the installation dir (usually "reaper")
if [ -z "$configname" ]; then configname="$(basename $appdir)"; else configname="$1"; fi


check_home_config() {
	# If $HOME/.config/$configname does not exist, create it
	if [ ! -e "$HOME/.config/$configname" ]; then
		mkdir -p "$HOME/.config/$configname"
	
		# Create the default configuration file for Reaper in it
		"$appdir"/.REAPER.ini.default.sh > "$HOME/.config/$configname/REAPER.ini"
	
		# Create the default vst directory
		mkdir -p "$HOME/.config/$configname/vst"
		
		ln -sf "$HOME/.config/reaper" "$APPDATA/REAPER"
	fi
}

link_winedirs_to_user() {
	# Link Windows profile dirs to $HOME
	for x in "DESKTOP-$WinDesktopUnix" "DOCUMENTS-$WinMyDocumentsUnix" "MUSIC-$WinMyMusicUnix" "PICTURES-$WinMyPicturesUnix" "VIDEOS-$WinMyVideosUnix"; do
		dir="$(echo "$x" | cut -d- -f2-)"
		name="$(echo "$x" | cut -d- -f1)"
		# Get the matching XDG DIR for this dir
		xdgdir="$(cat ${XDG_CONFIG_HOME:-~/.config}/user-dirs.dirs | grep -i $name | cut -d= -f2-)"
		# Remove the quotes around it
		xdgdir="$(echo ${xdgdir:1:`expr length "$xdgdir" - 2`})"
		# Remove any trailing /
		xdgdir="${xdgdir/%\/}"
		name="$(basename "$dir")"
		# If fx. $HOME/My Documents exists, link to that
		if [ -e "$HOME/$name" ]; then
			lindir="$HOME/$name"
		# If instead fx. $HOME/Documents exists, link to that
		elif [ -e "$HOME/$(echo "$name" | cut -d\  -f2-)" ]; then
			lindir="$HOME/$(echo "$name" | cut -d\  -f2-)"
		# Else, link to XDG_DOCUMENTS_DIR (or similar XDG dir) or $HOME
		else
			if [ -z "$xdgdir" ]; then lindir=$HOME; else lindir="$(eval echo $xdgdir)"; fi
		fi
		echo "Linking \"$(basename "$dir")\" to \"$lindir\"."
		ln -sf "$lindir" "$dir"
		
		xdgdir=""
	done
}

check_home_config

link_winedirs_to_user

echo "$configname" > "$appdir/.configuration_dir"
