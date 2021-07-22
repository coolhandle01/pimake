#!/bin/bash
source script/common/version.sh

header "$0"

#
# download the latest raspian image
# verify the checksum of the image
#

if [ "$1" = "--source-url" ]; then
    echo \# using $2
    url=$2
fi

image_chk="$source_image_sha $package"

if [ ! -f "$package" ]; then
    echo \# downloading $package
    echo \# from $url
    curl $url -L -o $package
    echo \#
else
    echo \# found existing $package
fi

echo \# verifying $package
sha256sum $package > $package_checksum
checksum=$(cat $package_checksum)

if [ "$image_chk" = "$checksum" ]; then
    echo \# - OK
else
    echo \# - FAILED
    echo \#   $checksum
    echo \#   $image_chk
fi

exit 0
