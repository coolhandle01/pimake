#!/bin/bash
source script/common/version.sh

header "$0"

#
# unpack the raspian image
#

msg "decompressing $build"
unzip $package -d $workspace_dir/img

exit 0
