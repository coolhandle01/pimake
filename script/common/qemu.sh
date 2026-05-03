#!/bin/bash
source script/common/common.sh

# Path to state file for a given PID
qemu_state_file() {
    echo "$workspace_dir/qemu/$1.state"
}

# Write state file named by PID
qemu_write_state() {
    local pid=$1 port=$2
    {
        echo "qemu_pid=$pid"
        echo "qemu_machine=$qemu_machine"
        echo "qemu_memory=$qemu_memory"
        echo "qemu_ssh_port=$port"
        echo "source_image_distro=$source_image_distro"
        echo "source_image_name=$source_image_name"
        echo "started_at=$(date '+%Y-%m-%dT%H:%M:%S')"
    } > "$(qemu_state_file "$pid")"
}

# Find the lowest SSH port >= qemu_ssh_port not already claimed by a state file
qemu_find_free_port() {
    local port="${qemu_ssh_port:-5022}"
    local used
    used=$(grep -h '^qemu_ssh_port=' "$workspace_dir/qemu/"*.state 2>/dev/null \
           | cut -d= -f2 | sort -n)
    while echo "$used" | grep -qx "$port"; do
        port=$((port + 1))
    done
    echo "$port"
}

# Returns 0 if a QEMU process with the given PID is still alive
qemu_is_running() {
    kill -0 "$1" 2>/dev/null
}

# Extract kernel, DTB (and initrd for Ubuntu) from the image's boot partition
# into workspace/qemu/boot/ using mtools — no sudo required.
# Skips extraction if kernel.img is newer than the source image.
qemu_extract_boot() {
    local boot_dir="$workspace_dir/qemu/boot"
    mkdir -p "$boot_dir"

    local _need_initrd=0
    [ "$source_image_distro" = "ubuntu" ] && _need_initrd=1

    if [ "$boot_dir/kernel.img" -nt "$image" ] && [ -f "$boot_dir/board.dtb" ] \
       && { [ "$_need_initrd" -eq 0 ] || [ -f "$boot_dir/initrd.img" ]; }; then
        okmsg "kernel and DTB already extracted"
        return 0
    fi

    title "extracting kernel and DTB from boot partition"

    local boot_start
    boot_start=$(sfdisk --json "$image" \
        | grep -o '"start": *[0-9]*' \
        | head -1 \
        | grep -o '[0-9]*$')
    if [ -z "$boot_start" ]; then
        errr "could not determine boot partition offset from $image"
        return 1
    fi

    local offset=$(( boot_start * 512 ))

    if [ "$source_image_distro" = "ubuntu" ]; then
        # Ubuntu 24.04: kernel is vmlinuz, DTB is at FAT root, initrd is required
        MTOOLS_SKIP_CHECK=1 mcopy -i "${image}@@${offset}" ::vmlinuz "$boot_dir/kernel.img" || return 1
        MTOOLS_SKIP_CHECK=1 mcopy -i "${image}@@${offset}" ::bcm2710-rpi-3-b-plus.dtb "$boot_dir/board.dtb" || return 1
        MTOOLS_SKIP_CHECK=1 mcopy -i "${image}@@${offset}" ::initrd.img "$boot_dir/initrd.img" || return 1
    else
        MTOOLS_SKIP_CHECK=1 mcopy -i "${image}@@${offset}" ::kernel8.img "$boot_dir/kernel.img" || return 1
        MTOOLS_SKIP_CHECK=1 mcopy -i "${image}@@${offset}" ::bcm2710-rpi-3-b-plus.dtb "$boot_dir/board.dtb" || return 1
    fi

    okmsg "kernel and DTB extracted"
}

# Create a per-instance qcow2 overlay backed by $image, sized to the next
# power-of-2 GiB (raspi3b requires a power-of-2 SD card size).
# Sets the global $qemu_disk to the overlay path.
qemu_prepare_disk() {
    local port=$1
    local disk="$workspace_dir/qemu/disk-${port}.qcow2"

    local size_bytes; size_bytes=$(stat -c%s "$image")
    local gib=$(( (size_bytes + 1073741823) / 1073741824 ))
    local p=1
    while [ "$p" -lt "$gib" ]; do p=$(( p * 2 )); done

    qemu-img create -f qcow2 \
        -b "$(realpath "$image")" -F raw \
        "$disk" "${p}G" >/dev/null
    check_error

    # shellcheck disable=SC2034
    qemu_disk="$disk"
}
