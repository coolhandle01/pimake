#!/bin/bash
source script/common/common.sh
source script/common/qemu.sh

vm_usage() {
    echo "Usage: pimake vm <subcommand> [args]"
    echo ""
    echo "Subcommands:"
    echo "  start              Launch image in QEMU (--desktop for GUI window)"
    echo "  stop  --pid <pid>  Stop a running QEMU instance"
    echo "  list               List all QEMU instances and their status"
    echo "  show  --pid <pid>  Show details of a QEMU instance"
}

vm_start() {
    header "vm start"

    local display_opts=(-nographic)
    if [ "${1:-}" = "--desktop" ]; then
        display_opts=(-display gtk)
    fi

    for _cmd in qemu-system-arm mtools sfdisk; do
        if ! command -v "$_cmd" &>/dev/null; then
            errr "required command not found: $_cmd"
            msg  "  install with: sudo apt-get install -y qemu-system-arm mtools"
            exit 1
        fi
    done

    if [ ! -f "$image" ]; then
        errr "image not found: $image"
        msg  "  run: pimake fetch && pimake unpack (and optionally pimake build)"
        exit 1
    fi

    if [ "$source_image_distro" = "ubuntu" ]; then
        errr "ubuntu images are arm64 — needs qemu-system-aarch64 -M raspi3b (not yet supported)"
        exit 1
    fi

    local boot_dir="$workspace_dir/qemu/boot"

    qemu_extract_boot || exit 1

    local _port; _port=$(qemu_find_free_port)

    title "starting QEMU ($qemu_machine, ${qemu_memory}M, SSH -> localhost:${_port})"

    # Reserve the state file slot before forking so qemu_find_free_port
    # won't double-assign this port if vm start is called again immediately.
    local _pid_tmp="$$-pending"
    qemu_write_state "$_pid_tmp" "$_port"

    qemu-system-arm \
        -M        "$qemu_machine" \
        -m        "${qemu_memory}" \
        -sd       "$image" \
        -snapshot \
        -kernel   "$boot_dir/kernel.img" \
        -dtb      "$boot_dir/board.dtb" \
        -append   "rw earlyprintk loglevel=8 console=ttyAMA0,115200 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait" \
        -net      nic \
        -net      "user,hostfwd=tcp::${_port}-:22" \
        "${display_opts[@]}" \
        < /dev/null >> "$workspace_dir/qemu/qemu-${_port}.log" 2>&1 &

    local _pid=$!
    rm -f "$(qemu_state_file "$_pid_tmp")"
    qemu_write_state "$_pid" "$_port"

    sleep 2
    if ! qemu_is_running "$_pid"; then
        errr "QEMU exited immediately — log:"
        cat "$workspace_dir/qemu/qemu-${_port}.log" >&2
        rm -f "$(qemu_state_file "$_pid")" "$workspace_dir/qemu/qemu-${_port}.log"
        exit 1
    fi

    okmsg "started (pid $_pid)"
    msg   "  connect: ssh -p $_port pi@localhost"
    msg   "  stop:    pimake vm stop --pid $_pid"
}

vm_stop() {
    header "vm stop"

    local _pid=""
    if [ "${1:-}" = "--pid" ] && [ -n "${2:-}" ]; then
        _pid="$2"
    else
        errr "usage: pimake vm stop --pid <pid>"
        msg  "  run: pimake vm list  to see running instances"
        exit 1
    fi

    local state_file; state_file="$(qemu_state_file "$_pid")"

    if [ ! -f "$state_file" ]; then
        warn "no state found for pid $_pid"
        exit 1
    fi

    if ! qemu_is_running "$_pid"; then
        warn "pid $_pid is not running (removing stale state)"
        rm -f "$state_file"
        exit 0
    fi

    qemu_pid="" qemu_ssh_port=""
    # shellcheck source=/dev/null
    source "$state_file"

    title "stopping QEMU (pid $_pid)"
    kill "$_pid"
    wait "$_pid" 2>/dev/null
    rm -f "$state_file" "$workspace_dir/qemu/qemu-${qemu_ssh_port}.log"
    okmsg "stopped"
}

vm_list() {
    header "vm list"

    local found=0
    printf "%-7s  %-36s  %-8s  %s\n" "PID" "IMAGE" "STATUS" "SSH PORT"

    for state_file in "$workspace_dir/qemu/"*.state; do
        [ -f "$state_file" ] || continue
        found=1
        (
            qemu_pid="" qemu_ssh_port=""
            # shellcheck source=/dev/null
            source "$state_file"
            if qemu_is_running "$qemu_pid"; then
                _status="running"
            else
                _status="stopped"
            fi
            printf "%-7s  %-36s  %-8s  %s\n" "$qemu_pid" "$source_image_name" "$_status" "$qemu_ssh_port"
        )
    done

    if [ "$found" -eq 0 ]; then
        msg "no instances found"
    fi
}

vm_show() {
    header "vm show"

    local _pid=""
    if [ "${1:-}" = "--pid" ] && [ -n "${2:-}" ]; then
        _pid="$2"
    else
        errr "usage: pimake vm show --pid <pid>"
        msg  "  run: pimake vm list  to see available instances"
        exit 1
    fi

    local state_file; state_file="$(qemu_state_file "$_pid")"

    if [ ! -f "$state_file" ]; then
        warn "no state found for pid $_pid"
        exit 1
    fi

    qemu_pid="" qemu_machine="" qemu_memory="" qemu_ssh_port="" started_at="" source_image_name="" source_image_distro=""
    # shellcheck source=/dev/null
    source "$state_file"

    local _status="stopped"
    if qemu_is_running "$qemu_pid"; then
        _status="running"
    fi

    title "$source_image_name"
    msg "  pid:      $qemu_pid"
    msg "  distro:   $source_image_distro"
    msg "  machine:  $qemu_machine"
    msg "  memory:   ${qemu_memory}M"
    msg "  ssh:      ssh -p $qemu_ssh_port pi@localhost"
    msg "  status:   $_status"
    msg "  started:  $started_at"
}

# ── Dispatcher ────────────────────────────────────────────────────────────────
case "${1:-}" in
    start|stop|list|show)
        subcommand=$1
        shift
        "vm_${subcommand}" "$@"
        ;;
    -h|--help|"")
        vm_usage
        ;;
    *)
        echo "pimake vm: unknown subcommand '$1'" >&2
        echo "Run 'pimake vm --help' for usage." >&2
        exit 1
        ;;
esac
