#!/bin/bash
source script/common/common.sh

header "$0"

#
# unpack the raspbian image
#

msg "decompressing $package"
case "$package" in
    *.zip) unzip "$package" -d "$workspace_dir/img" ;;
    *.xz)  xz -dc "$package" > "$image" ;;
    *)     errr "unsupported archive format: $package"; exit 1 ;;
esac

exit 0
