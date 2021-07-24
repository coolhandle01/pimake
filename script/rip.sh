#!/bin/bash
source script/common/version.sh

header "$0"

# check_user root

source_disk=$1
if [ -z $1 ]; then
	errr "no source disk was specified."
	exit 1
fi

#
# read the burned raspbian image
# 
msg "reading $image from $source_disk"
dd if=$source_disk of=$image bs=4M conv=fsync status=progress

exit 0
