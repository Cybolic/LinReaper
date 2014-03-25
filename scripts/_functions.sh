# Function to get a value from the system registry and convert it to a UNIX path
pathfromreg() {
  # Grep for value key, pick first or last one and strip the key part of the line
  if [ -z "$2" ]; then
    WinPath="$(grep "\"$1\"=" "$appdir/.wine/system.reg" | tail -n1 | cut -d= -f2-)"
  else
    WinPath="$(grep "\"$1\"=" "$appdir/.wine/system.reg" | head -n1 | cut -d= -f2-)"
  fi
  # Remove quotes, if any
  test "${WinPath:0:1}" = '"' && WinPath="$(echo ${WinPath:1:${#WinPath}-2})"

  # Check for likely variable reference, look for first occurance instead if so
  if test "${WinPath:0:3}" = 'str'; then
    echo "$(pathfromreg "$1" first)"
  else
    # Convert to UNIX path
    # echo "$WinPath"
    winepath -u "$WinPath"
  fi
}


getProgramFiles() {
  ProgramFiles="$(pathfromreg "ProgramFiles")"
  # If ProgramFiles isn't set, try ProgramFilesDir
  test -z "$ProgramFiles" && ProgramFiles="$(pathfromreg "ProgramFilesDir")"
  echo $ProgramFiles
}
getWinSysDir() {
  winsysdir="$(pathfromreg "winsysdir")"
  echo $winsysdir
}
getAppData() {
  APPDATA="$(pathfromreg "APPDATA")"
  test -z "$APPDATA" && APPDATA="$(pathfromreg 'Common AppData')"
  echo $APPDATA
}
getProfilesDir() {
  test -z "$APPDATA" && APPDATA="$(getAppData)"
  PROFILESDIR="$(dirname "`dirname "$APPDATA"`")"
  echo $PROFILESDIR
}
getUserProfile() {
  test -z "$PROFILESDIR" && PROFILESDIR="$(getProfilesDir)"
  USERPROFILE="$PROFILESDIR/$USER"
  echo $USERPROFILE
}