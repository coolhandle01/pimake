#!/bin/bash
source script/common/common.sh

#
# handle vfat partition mounting
#
function mount_vfat() {
    msg "mount $mount/vfat"
    mkdir -p "$mount/vfat"
    mount -t vfat "${LODEV}p1" "$mount/vfat"
}

function unmount_vfat() {
    msg "unmount $mount/vfat"
    umount -l "$mount/vfat"
    sleep 2
    rm -rf "$mount/vfat"
}
