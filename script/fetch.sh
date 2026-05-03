#!/bin/bash
source script/common/common.sh

header "$0"

#
# download the latest raspian image
# verify the checksum of the image
#

if [ ! -f "$package" ]; then
    msg "downloading $package"
    curl "$source_image_url/$source_image_archive" -L -o "$package"

    msg "downloading $package_checksum"
    curl "$source_image_url/$source_image_hash" -L -o "$package_checksum"
else
    msg "found existing $package"
fi

msg "verifying $package.."
actual=$(sha256sum "$package" | awk '{print $1}')
expected=$(awk 'NR==1{print $1}' "$package_checksum" 2>/dev/null)

if [ -z "$expected" ]; then
    warn "skipping hash verification (no checksum file)"
elif [ "$actual" = "$expected" ]; then
    okmsg "OK"
else
    errr "FAILED"
    msg "calculated: $actual"
    msg "expected:   $expected"
fi

exit 0
