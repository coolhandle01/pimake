#!/bin/bash
source script/common/version.sh

#
# handle ext4 partition mounting
#
## need to get offsets from index.conf

function mount_ext4() {
    msg "mount $mount/ext4"
    mkdir -p $mount/ext4 272629760
    mount -o loop,offset=272629760 -t ext4 $image $mount/ext4
}

function unmount_ext4() {
    msg "unmount $mount/ext4"
    umount -l $mount/ext4
    sleep 2
    rm -rf $mount/ext4
}
