#!/usr/bin/env bash
#
# Watches spec files and re-runs the busted suite when a spec or source file
# changes.
#
# Usage:
#
#     $0 [--focus]
#
# If --focus is passed, only the last spec file that has changed will be run
# when a _source_ file changes. Otherwise, all specs will run on source changes.
#
# Requires inotify-tools[1].
#
# [1] http://linux.die.net/man/1/inotifywait

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
    if [[ $1 =~ "focus" ]]; then
      LAST_FILE=$FILEPATH
    fi

    busted "${FILEPATH}"
  fi
done