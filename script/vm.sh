#!/bin/bash
source script/common/common.sh
source script/common/qemu.sh

vm_usage() {
    echo "Usage: pimake vm <subcommand> [args]"
    echo ""
    echo "Subcommands:"
    echo "  start    Launch image in QEMU (--desktop for GUI window)"
    echo "  stop     Stop a running QEMU instance [name]"
    echo "  list     List all QEMU instances and their status"
    echo "  show     Show details of a QEMU instance [name]"
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

    if qemu_is_running; then
        warn "$source_image_name is already running"
        msg  "  use: pimake vm stop  or  pimake vm show"
        exit 1
    fi

    local _ssh_port="${qemu_ssh_port:-5022}"
    local dir; dir="$(qemu_dir)"

    qemu_extract_boot || exit 1

    title "starting QEMU ($qemu_machine, ${qemu_memory}M, SSH -> localhost:${_ssh_port})"

    qemu-system-arm \
        -M      "$qemu_machine" \
        -m      "${qemu_memory}" \
        -sd     "$image" \
        -kernel "$dir/kernel.img" \
        -dtb    "$dir/board.dtb" \
        -append "rw earlyprintk loglevel=8 console=ttyAMA0,115200 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait" \
        -net    nic \
        -net    "user,hostfwd=tcp::${_ssh_port}-:22" \
        -serial stdio \
        "${display_opts[@]}" \
        &>/dev/null &

    local _qemu_pid=$!
    qemu_write_state "$_qemu_pid" "$_ssh_port"

    sleep 1
    if ! kill -0 "$_qemu_pid" 2>/dev/null; then
        errr "QEMU exited immediately — check image and config"
        rm -f "$dir/run.state"
        exit 1
    fi

    okmsg "started (pid $_qemu_pid)"
    msg   "  connect: ssh -p $_ssh_port pi@localhost"
    msg   "  stop:    pimake vm stop"
}

vm_stop() {
    header "vm stop"

    local name="${1:-$source_image_name}"
    local state_file="$workspace_dir/qemu/$name/run.state"

    if [ ! -f "$state_file" ]; then
        warn "$name is not running"
        exit 0
    fi

    qemu_pid=""
    # shellcheck source=/dev/null
    source "$state_file"

    if ! kill -0 "$qemu_pid" 2>/dev/null; then
        warn "$name is not running (stale state removed)"
        rm -f "$state_file"
        exit 0
    fi

    title "stopping QEMU (pid $qemu_pid)"
    kill "$qemu_pid"
    wait "$qemu_pid" 2>/dev/null
    rm -f "$state_file"
    okmsg "stopped"
}

vm_list() {
    header "vm list"

    local qemu_base="$workspace_dir/qemu"

    if [ ! -d "$qemu_base" ]; then
        msg "no instances found"
        return 0
    fi

    local found=0
    printf "%-40s  %-8s  %s\n" "NAME" "STATUS" "SSH PORT"

    for state_file in "$qemu_base"/*/run.state; do
        [ -f "$state_file" ] || continue
        found=1
        # shellcheck source=/dev/null
        (
            source "$state_file"
            if kill -0 "$qemu_pid" 2>/dev/null; then
                _status="running"
            else
                _status="stopped"
            fi
            printf "%-40s  %-8s  %s\n" "$source_image_name" "$_status" "$qemu_ssh_port"
        )
    done

    if [ "$found" -eq 0 ]; then
        msg "no instances found"
    fi
}

vm_show() {
    header "vm show"

    local name="${1:-$source_image_name}"
    local state_file="$workspace_dir/qemu/$name/run.state"

    if [ ! -f "$state_file" ]; then
        warn "no state found for $name"
        msg  "  run: pimake vm start"
        exit 1
    fi

    qemu_pid="" qemu_machine="" qemu_memory="" qemu_ssh_port="" started_at=""
    # shellcheck source=/dev/null
    source "$state_file"

    local _status="stopped"
    if kill -0 "$qemu_pid" 2>/dev/null; then
        _status="running"
    fi

    title "$source_image_name"
    msg "  distro:   $source_image_distro"
    msg "  machine:  $qemu_machine"
    msg "  memory:   ${qemu_memory}M"
    msg "  ssh:      ssh -p $qemu_ssh_port pi@localhost"
    msg "  pid:      $qemu_pid"
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
