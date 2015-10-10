#!/usr/bin/env bash
#
# Watches spec files and re-runs the busted suite when a spec or source file
# changes.
#
# Requires inotify-tools[1].
#
# [1] http://linux.die.net/man/1/inotifywait

if [ -z $1 ]; then
  echo "Usage: $0"
  exit 1
fi

if [ ! -d spec ]; then
  echo "Must be run from lua_cliargs root."
  exit 1
fi

LAST_FILE="spec/"

inotifywait -rm --format '%w %f' -e close_write -e create src/ spec/ | while read dir file; do
  FILEPATH="${dir}${file}"

  if [[ $FILEPATH =~ src\/ ]]; then
    busted "${LAST_FILE}"
  else
    LAST_FILE=$FILEPATH
    busted "${FILEPATH}"
  fi
done