#!/bin/bash
source script/common/version.sh

#
# handle vfat partition mounting
#

function mount_vfat() {
    msg "mount $mount/vfat"
    mkdir -p $mount/vfat
    mount -o loop,offset=4194304 -t vfat $image $mount/vfat
}

function unmount_vfat() {
    msg "unmount $mount/vfat"
    umount -l $mount/vfat
    sleep 2
    rm -rf $mount/vfat
}
