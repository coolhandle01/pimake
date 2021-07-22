#!/bin/bash
source script/common/version.sh

header "$0"

# check_user root

target_disk=$1
if [ -z $1 ]; then
	echo \# Sorry, no target disk was specified.
	exit 1
fi

#
# burn the packed raspbian image
# 
echo \# writing $build to $target_disk
dd if=$build of=$target_disk bs=4M conv=fsync status=progress

exit 0
