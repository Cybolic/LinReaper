#!/bin/sh

if [ ! -f "$2" ]; then
	wget --progress=bar:force "$1" -O "$2"
fi
