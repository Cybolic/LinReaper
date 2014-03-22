#!/bin/bash

# If we were not given a URL, find it ourselves
if [ -z "$1" ]; then
	url="$(wget -qO - 'http://reaper.fm/download.php' | grep -ie '-install.exe">' | grep -iEoe '".*.exe"' | grep -v 'x64')"
	url="${url:1:$(expr ${#url}-2)}"
	# If http:// (or ftp:// or similar) is missing from url, add it
	if [ -z $(expr "$url" : '.*\(://\)') ]; then
		url="http://reaper.fm/$url"
	fi
else
	url="$1"
fi

if [ -z "$2" ]; then
	output="/tmp/linreaper-reaper-install.exe"
else
	output="$2"
fi


if [ ! -f "$2" ]; then
	wget --progress=bar:force "$url" -O "$output"
fi
