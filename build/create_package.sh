#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIRNAME="$(basename "$(dirname "$(dirname "$(readlink -f "$0")")")")"

cd "$SCRIPT_DIR/../../"

test -x "$(which makeself)"         && MAKESELF="$(which makeself)"
test -x "$(which makeself.sh)"      && MAKESELF="$(which makeself.sh)"
test -x "makeself-2"*"/makeself.sh" && MAKESELF="makeself-2"*"/makeself.sh"
test -x "makeself.sh"               && MAKESELF="./makeself.sh"
test -x "$SCRIPT_DIR/makeself-2"*"/makeself.sh" && MAKESELF="$SCRIPT_DIR/makeself-2"*"/makeself.sh"

if [ -z "$MAKESELF" ]; then
  echo "Makeself not found; downloading new copy..."
  cd "$SCRIPT_DIR"
  wget -c "http://megastep.org/makeself/makeself.run"
  chmod +x ./makeself.run
  ./makeself.run
  MAKESELF="$SCRIPT_DIR/makeself-2*/makeself.sh"
  cd ../..
fi

if [ -z "$1" ]; then
  echo "No version given."
  echo "USAGE: $0 VERSION"
  exit 1
fi

shopt -s extglob
if [ -d "./$PROJECT_DIRNAME/build/distrib" ]; then
  rm -Rf "./$PROJECT_DIRNAME/build/distrib"
fi
mkdir -p "./$PROJECT_DIRNAME/build/distrib"
echo "Copying distribution files to build/distrib..."
cp -a "./$PROJECT_DIRNAME/"!(build) "./$PROJECT_DIRNAME/build/distrib/"
$MAKESELF "./$PROJECT_DIRNAME/build/distrib" "$SCRIPT_DIR/LinReaper$1.run" "LinReaper Reaper Installer For Linux" ./main.py
