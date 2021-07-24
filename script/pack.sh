#!/bin/bash
source script/common/version.sh

header "$0"

#
# pack the raspbian image
#

msg "compressing $image to $build"
zip -j $build $workspace_dir/img/*

msg "generating SHA256 for $build"
sha256sum $build > $build_checksum
checksum=$(cat $build_checksum)

exit 0
