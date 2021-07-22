#!/bin/bash
source script/common/version.sh

header "$0"

#
# pack the raspbian image
#

echo \# compressing $image to $build
zip -j $build $workspace_dir/img/*

echo \# generating SHA256 for $build
sha256sum $build > $build_checksum
checksum=$(cat $build_checksum)

exit 0
