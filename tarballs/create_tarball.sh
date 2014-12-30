#!/usr/bin/env bash

PKG="lua_cliargs"
MAJOR=$1
MINOR=$2
FQN="${PKG}-${MAJOR}.${MINOR}"

if [ -d "$FQN" ]; then
  echo -en "Will not overwrite existing directory '$FQN'. "
  echo -en "\e[00;31m[ FAILED ]\e[00m\n"
  exit 1
fi

if [ -f "$FQN.tar.gz" ]; then
  echo -en "Overwriting tar archive '$FQN.tar.gz'. "
  echo -en "\e[00;33m[ WARNING ]\e[00m\n"

  rm "$FQN.tar.gz"
fi

ln -s ../ "$FQN"
tar --exclude=".git" --exclude=tarballs -hzvcf "$FQN.tar.gz" "$FQN"
rm "$FQN"

echo -en "Archive created: '$FQN'. "
echo -en "\e[00;32m[ SUCCESS ]\e[00m\n"
exit 0
