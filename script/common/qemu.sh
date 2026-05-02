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

# Extract kernel7.img and bcm2709-rpi-2-b.dtb from the image's boot partition
# into workspace/qemu/boot/ using mtools — no sudo required.
# Skips extraction if kernel.img is newer than the source image.
qemu_extract_boot() {
    local boot_dir="$workspace_dir/qemu/boot"
    mkdir -p "$boot_dir"

    if [ "$boot_dir/kernel.img" -nt "$image" ] && [ -f "$boot_dir/board.dtb" ]; then
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

    MTOOLS_SKIP_CHECK=1 mcopy -i "${image}@@${offset}" ::kernel7.img  "$boot_dir/kernel.img" || return 1
    MTOOLS_SKIP_CHECK=1 mcopy -i "${image}@@${offset}" ::bcm2709-rpi-2-b.dtb "$boot_dir/board.dtb" || return 1

    okmsg "kernel and DTB extracted"
}
