#!/bin/bash
source script/common/common.sh

header "$0"

# check_user root

# Resolve source device: --device flag, positional arg, or interactive picker
source_disk=""
if [ "$1" = "--device" ] && [ -n "$2" ]; then
    source_disk=$2
elif [ -n "$1" ] && [ "$1" != "--device" ]; then
    source_disk=$1
fi

if [ -z "$source_disk" ]; then
    pick_removable_device || exit 1
    source_disk=$selected_device
fi

if [ ! -b "$source_disk" ]; then
    errr "$source_disk is not a block device."
    exit 1
fi

# Confirm before reading
echo ""
title "Confirm read"
msg "  source:  $source_disk  $(device_info "$source_disk")"
msg "  image:   $image"
echo ""
echo -en "# Type 'yes' to continue: "
read -r _confirm
if [ "$_confirm" != "yes" ]; then
    msg "Aborted."
    exit 0
fi

#
# read the burned raspbian image
#
msg "reading $image from $source_disk"
dd if="$source_disk" of="$image" bs=4M conv=fsync status=progress

exit 0
