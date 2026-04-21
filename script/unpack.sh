#!/bin/bash
source script/common/common.sh

header "$0"

#
# unpack the raspian image
#

msg "decompressing $package"
unzip "$package" -d "$workspace_dir/img"

exit 0
