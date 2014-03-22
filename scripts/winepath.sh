#!/bin/dash
#
# POSIX Shell script replacement for winepath
#
# Copyright (c) 2011 Christian Dannie Storgaard
# Released under the GNU Lesser General Public License version 2.1 or later
#
################################################################################
#
# Note that this script varies slightly from winepath in that it will not output
# Windows paths containing characters that are illegal on a Windows filesystem.
# Any such character will be replaced by the character tilde (~).
#
# You can also use Windows environment variables in a path as well as wildcards.
# winepath supports neither for some reason.
# E.g. '%ProgramFiles%/foobar~/~.exe'
#
################################################################################
#
# Notes about string manipulation to clear things up a bit:
#
# Every character but first:
#   ${var#?}
#
# Every character but last:
#   ${var%?}
#
# First character (string up until every-character-but-first):
#   ${var%"${var#?}"}
#
# Last character (string after every-character-but-last):
#   ${var#"${var%?}"}
#
# Replace substring:
# (string up until $search_str + $replacement_str + string after $search_str)
#   ${var%%$search_str*}$replacement_str${var#*$search_str}


w_get_reg_env()
{
    grep -i  "\"$1\"=\"" ${WINEPREFIX:-~/.wine}/*.reg | head -n 1 | \
    cut -d\" -f4- | cut -d\" -f1
}

w_path_wintounix()
{
    case "$1" in
    *':\'*|*%*)
        case "$1" in
        *':\'*)
            # Get drive letter in lower and upper case
            drive="${1%"${1#?}"}"
            drive_lower="`echo $drive | tr [:upper:] [:lower:]`"
            drive_upper="`echo $drive | tr [:lower:] [:upper:]`"
            # Get the real location of the drive
            # NOTE: I prefer this output (the actual location), but winepath
            #       returns just the link location so we do the same
            #drive_path="`readlink -mn ${WINEPREFIX:-~/.wine}/dosdevices/[$drive_lower,$drive_upper]:`"
            if test -x ${WINEPREFIX:-~/.wine}/dosdevices/$drive_lower:
            then
                drive_path="${WINEPREFIX:-$HOME/.wine}/dosdevices/$drive_lower:"
            elif test -x ${WINEPREFIX:-~/.wine}/dosdevices/$drive_upper:
            then
                drive_path="${WINEPREFIX:-$HOME/.wine}/dosdevices/$drive_upper:"
            # If the drive isn't linked properly, return the same as winepath
            else
                echo ""
                return 0
            fi
            ;;
        *)
            drive_path=""
        esac
        # Replace backslashes with slashes, and remove duplicates
        path="`echo "$1" | sed -re 's,\\\+,/,g'`"
        # Get the rest of the path, without the drive
        path="`echo $path | sed -re 's,[a-zA-Z]:/+,,g'`"
        # Check if there are any {} characters, since that means a reg variable
        if test "`echo $path | tr -d '[%]'`" != "$path"
        then
            reg_key="`echo "$path" | grep -o '%.*%' | cut -d% -f2- | cut -d% -f1`"
            reg_value="`w_get_reg_env "$reg_key"`"
            reg_value="`w_path_wintounix "$reg_value"`"
            # Replace key name with converted value
            path="${path%%\%$reg_key*}$reg_value${path#*$reg_key\%}"
        fi
        # If a simple translation on \ to / will locate the location, return that
        if test -x "$drive_path/$path"
        then
            echo "$drive_path/$path"
        else
        # Didn't work, we'll have to look for the location
            dir_so_far="$drive_path"
            IFS="/"
            for dir_part in $path
            do
                test -z "$dir_part" && continue # skip empty parts
                found=false
                if test -x "$dir_so_far/$dir_part"
                then
                    dir_so_far="$dir_so_far/$dir_part"
                    found=true
                else
                    match_start=false
                    match_end=false
                    # There's a wildcard at the end, use wildcard matching
                    if test ${dir_part#"${dir_part%?}"} = '~'
                    then
                        search_part=${dir_part%%\~}
                        match_start=true
                    # There's a wildcard at the start, use wildcard matching
                    elif test ${dir_part%"${dir_part#?}"} = '~'
                    then
                        search_part=${dir_part#*\~}
                        match_end=true
                    fi

                    # Go through the directory looking for matches
                    for dir_name in "$dir_so_far"/* "$dir_so_far"/.*
                    do
                        dir_name="`basename "$dir_name"`"
                        # Match filename by its start
                        if $match_start
                        then
                            if printf '%s\n' "$dir_name" | grep -qi "^$search_part"
                            then
                                # Use it
                                dir_so_far="$dir_so_far/$dir_name"
                                found=true
                                break
                            fi
                        # Match filename by its ending
                        elif $match_end
                        then
                            if printf '%s\n' "$dir_name" | grep -qi "$search_part$"
                            then
                                # Use it
                                dir_so_far="$dir_so_far/$dir_name"
                                found=true
                                break
                            fi
                        # Match full filename
                        else
                            # If this dirname matches either exactly
                            # or case insensitively
                            if test \
                            "$dir_part" = "$dir_name" -o \
                            "`echo "$dir_part" | tr [:upper:] [:lower:]`" = \
                            "`echo "$dir_name" | tr [:upper:] [:lower:]`"
                            then
                                # Use it
                                dir_so_far="$dir_so_far/$dir_name"
                                found=true
                                break
                            fi
                        fi
                    done
                fi
                if ! $found
                then
                    # This part wasn't found, return a simple conversion
                    dir_so_far="$drive_path/$path"
                    break
                fi
            done
            # Remove double slashes (can happen if the drive maps to /)
            printf '%s\n' "`echo "$dir_so_far" | sed -re 's,[/]+,/,g'`"
        fi
        ;;
    *) printf '%s/dosdevices/z:%s\n' "${WINEPREFIX:-$HOME/.wine}" "$1" ;;
    esac
}

w_path_unixtowin()
{
    # Go through the mappings for the drives
    use_drive=''
    for drive_link in ${WINEPREFIX:-$HOME/.wine}/dosdevices/*:
    do
        case $drive_link in
        *::) continue ;;
        esac

        drive_in_case=${drive_link#*"dosdevices/"}
        drive_in_case=${drive_in_case%":"}
        drive="`echo $drive_in_case | tr [:upper:] [:lower:]`"
        mapping="`readlink -mn "$drive_link"`"
        # Check if the mapping uses the same format as the path
        same_mapping=false
        case "$mapping" in
        */drive_*)
            case "$1" in
            */.wine/drive_*)
                # Both drives are using the same format, we're good
                same_mapping=true
                ;;
            esac
            ;;
        esac
        if ! $same_mapping
        then
            prefix=${mapping%%"/drive_"*}
            new_mapping="$prefix/dosdevices/$drive:"
            if test -x $new_mapping
            then
                mapping=$new_mapping
            fi
        fi
        # If path starts with mapping, use this drive
        if test "$1" != "${1%%$mapping*}"
        then
            use_drive="`echo "$drive" | tr [:lower:] [:upper:]`"
            break
        fi
    done
    if test "$use_drive"x != ""x
    then
        # Strip mapping from beginning of path
        path=${1#*$mapping}
    else
        # Give a simple conversion of the path using Z as root
        use_drive="Z"
        case "$1" in
        /*)
            path="${1#?}" ;;
        *)
            dir_name="`dirname "$1"`"
            path="`cd "$dir_name"; pwd`/$1"
            path="${path#?}"
            ;;
        esac
    fi
    # Replace backslashes with tildes
    path="`echo "$path" | sed -re 's,\\\,~,g'`"
    # Replace illegal characters with a tilde
    path=`echo $path | sed -re 's,[<>:\"|?*],~,g'`
    # Convert separators to Windows separators
    path="`echo "$path" | sed -re 's,/+,\\\,g'`"
    printf '%s:\\%s\n' "$use_drive" "$path"
}


w_pathconv()
{
    case "$1" in
    -u) w_path_wintounix "$2" ;;
    -w) w_path_unixtowin "$2" ;;
    esac
}


w_pathconv "$@"

