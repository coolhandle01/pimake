#!/bin/bash
source script/common/version.sh

header "$0"

#
# download the latest raspian image
# verify the checksum of the image
#

image_chk="$source_image_hash_expected  $package"

if [ ! -f "$package" ]; then
    msg "downloading $package"
    curl $source_image_url/$source_image_archive -L -o $package

    msg "downloading $package_checksum"
    curl $source_image_url/$source_image_hash -L -o $package_checksum
else
    msg "found existing $package"
fi

msg "verifying $package.."
sha256sum $package > $package_checksum.test
checksum=$(cat $package_checksum.test)

if [ "$image_chk" = "$checksum" ]; then
    okmsg "OK"
else
    err "FAILED"
    msg "calculated: $checksum"
    msg "cached: $image_chk"
fi

exit 0
