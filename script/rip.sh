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
    mapfile -t _devs < <(lsblk -d -o NAME,RM --noheadings 2>/dev/null | awk '$2 == 1 {print $1}')
    if [ ${#_devs[@]} -eq 0 ]; then
        errr "No removable block devices found. Insert your SD card or use --device /dev/sdX."
        exit 1
    fi
    title "Available removable devices:"
    for i in "${!_devs[@]}"; do
        _info=$(lsblk -d -o SIZE,MODEL --noheadings "/dev/${_devs[$i]}" 2>/dev/null | xargs)
        msg "  $((i+1)))  /dev/${_devs[$i]}  $_info"
    done
    echo ""
    echo -en "# Enter number [1-${#_devs[@]}] or device path: "
    read -r _pick
    if [[ "$_pick" =~ ^[0-9]+$ ]] && [ "$_pick" -ge 1 ] && [ "$_pick" -le "${#_devs[@]}" ]; then
        source_disk="/dev/${_devs[$((_pick - 1))]}"
    else
        source_disk="$_pick"
    fi
fi

if [ ! -b "$source_disk" ]; then
    errr "$source_disk is not a block device."
    exit 1
fi

# Confirm before reading
_info=$(lsblk -d -o SIZE,MODEL --noheadings "$source_disk" 2>/dev/null | xargs)
echo ""
title "Confirm read"
msg "  source:  $source_disk  $_info"
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
