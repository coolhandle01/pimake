#!/bin/bash
source script/common/version.sh

header "$0"

msg "creating workspace"
mkdir -p $workspace_dir/build
mkdir -p $workspace_dir/img
mkdir -p $workspace_dir/mnt
mkdir -p $workspace_dir/package

msg "creating local configuration file"
cp conf/pimake.conf conf/pimake.local

exit 0
