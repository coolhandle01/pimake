#!/bin/bash
source script/common/version.sh

#
# handle ext4 partition mounting
#

function mount_ext4() {
    echo \# mount $mount/ext4
    mkdir -p $mount/ext4
    mount -o loop,offset=276824064 -t ext4 $image $mount/ext4
}

function unmount_ext4() {
    echo \# unmount $mount/ext4
    umount -l $mount/ext4
    sleep 2
    rm -rf $mount/ext4
}
