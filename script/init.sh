#!/bin/bash
source script/common/version.sh

header "$0"

echo \# - https://github.com/coolhandle01/pimake
echo \#
echo \# creating folder structure..
mkdir -p $workspace_dir/build
mkdir -p $workspace_dir/img
mkdir -p $workspace_dir/mnt
mkdir -p $workspace_dir/package

echo \# creating local pimake configuration file..
cp conf/pimake.conf conf/pimake.local
cp conf/pimake.conf conf/pimake.conf.test

exit 0
