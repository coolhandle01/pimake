#!/bin/bash
source script/common/common.sh

# Resolve state directory for the current image (requires common.sh vars)
qemu_dir() {
    echo "$workspace_dir/qemu/$source_image_name"
}

# Write run.state for a started instance
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
    } > "$(qemu_dir)/run.state"
}

# Source run.state into the current shell (sets qemu_pid, qemu_ssh_port, etc.)
qemu_read_state() {
    local state_file; state_file="$(qemu_dir)/run.state"
    [ -f "$state_file" ] || return 1
    # shellcheck source=/dev/null
    source "$state_file"
}

# Returns 0 if the QEMU process recorded in run.state is still alive
qemu_is_running() {
    local state_file; state_file="$(qemu_dir)/run.state"
    [ -f "$state_file" ] || return 1
    local pid; pid=$(grep '^qemu_pid=' "$state_file" | cut -d= -f2)
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

# Extract kernel7.img and bcm2709-rpi-2-b.dtb from the image's boot partition
# using mtools — no sudo required.
qemu_extract_boot() {
    local dir; dir="$(qemu_dir)"
    mkdir -p "$dir"

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

    MTOOLS_SKIP_CHECK=1 mcopy -i "${image}@@${offset}" ::kernel7.img  "$dir/kernel.img" || return 1
    MTOOLS_SKIP_CHECK=1 mcopy -i "${image}@@${offset}" ::bcm2709-rpi-2-b.dtb "$dir/board.dtb" || return 1

    okmsg "kernel and DTB extracted"
}
