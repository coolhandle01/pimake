#!/bin/bash
source script/common/version.sh

header "$0"

msg "clean up build directories"
rm -rf $workspace_dir/build/*
rm -rf $workspace_dir/img/*
rm -rf $workspace_dir/mnt/*

if [ "$1" = "-f" ] || [ "$1" = "--fresh" ]; then
  msg "clean up packages"
  rm -rf $workspace_dir/package/*

  msg "refreshing pimake.local"
  rm -f conf/pimake.local
  cp conf/pimake.conf conf/pimake.local
fi

exit 0
