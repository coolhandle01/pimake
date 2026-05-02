#!/bin/bash
source script/common/common.sh

header "$0"

# check_user root

# Resolve target device: --device flag, positional arg, or interactive picker
target_disk=""
if [ "$1" = "--device" ] && [ -n "$2" ]; then
    target_disk=$2
elif [ -n "$1" ] && [ "$1" != "--device" ]; then
    target_disk=$1
fi

if [ -z "$target_disk" ]; then
    pick_removable_device || exit 1
    target_disk=$selected_device
fi

if [ ! -b "$target_disk" ]; then
    errr "$target_disk is not a block device."
    exit 1
fi

# Confirm before writing
echo ""
title "Confirm write"
msg "  image:   $build"
msg "  device:  $target_disk  $(device_info "$target_disk")"
echo ""
warn "All data on $target_disk will be permanently erased."
echo -en "# Type 'yes' to continue: "
read -r _confirm
if [ "$_confirm" != "yes" ]; then
    msg "Aborted."
    exit 0
fi

#
# burn the packed raspbian image
#
msg "writing $build to $target_disk"
dd if="$build" of="$target_disk" bs=4M conv=fsync status=progress

exit 0
