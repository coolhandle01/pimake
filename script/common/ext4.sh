#!/bin/bash
source script/common/common.sh

#
# handle ext4 partition mounting
#
function mount_ext4() {
    msg "mount $mount/ext4"
    mkdir -p "$mount/ext4"
    mount -t ext4 "${LODEV}p2" "$mount/ext4"
}

function unmount_ext4() {
    msg "unmount $mount/ext4"
    umount -l "$mount/ext4"
    sleep 2
    rm -rf "$mount/ext4"
}
