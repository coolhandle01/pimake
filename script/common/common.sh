#!/bin/bash

# shellcheck disable=SC2034
version=v0.1.0

# shellcheck disable=SC2034
RED='\033[0;31m'
# shellcheck disable=SC2034
GREEN='\033[0;32m'
# shellcheck disable=SC2034
YELLOW='\033[0;33m'
# shellcheck disable=SC2034
BLUE='\033[0;34m'
# shellcheck disable=SC2034
PINK='\033[0;35m'
# shellcheck disable=SC2034
CYAN='\033[0;36m'
# shellcheck disable=SC2034
WHITE='\033[0;37m'
# shellcheck disable=SC2034
NC='\033[0m'
BOLD=$(tput bold 2>/dev/null)
NORM=$(tput sgr0 2>/dev/null)

function header() {
    local filename; filename=$(basename -- "$1")
    echo -e "# ${CYAN}${BOLD}${filename%%.*}${NC}${NORM}"
}
function title() {
    echo -e "# ${WHITE}${BOLD}$1${NC}${NORM}"
}
function errr() {
    echo -e "# ${RED}${BOLD}$1${NC}${NORM}"
}
function warn() {
    echo -e "# ${YELLOW}${BOLD}$1${NC}${NORM}"
}
function msg() {
    echo -e "# ${WHITE}$1${NC}"
}
function okmsg() {
    echo -e "# ${GREEN}${BOLD}$1${NC}${NORM}"
}

function check_user() {
    if [ "$(whoami)" = "$1" ]; then
        return 1
    else
        warn "but $USER, you're not $1?"
        exit 1
    fi
}

function check_error() {
    if [ $? -gt 0 ]; then
        errr "exiting"
        exit 1
    fi
}

# Load local config, falling back to the template for first-time init
# shellcheck source=conf/pimake.conf
if [ -f conf/pimake.local ]; then
    source conf/pimake.local
else
    source conf/pimake.conf
fi

# shellcheck source=conf/distro/raspbian-lite/index.conf
source "conf/distro/$source_image_distro/index.conf"

# Derived paths
# shellcheck disable=SC2034
package=$workspace_dir/package/$source_image_archive
# shellcheck disable=SC2034
package_checksum=$workspace_dir/package/$source_image_hash
# shellcheck disable=SC2034
build=$workspace_dir/build/$source_image_archive
# shellcheck disable=SC2034
build_checksum=$workspace_dir/build/$source_image_hash
# shellcheck disable=SC2034
image=$workspace_dir/img/$source_image_name.img
# shellcheck disable=SC2034
mount=$workspace_dir/mnt/$source_image_name
# shellcheck disable=SC2034
target_root=$mount/ext4
# shellcheck disable=SC2034
target_conf=$mount/vfat/config.txt
# shellcheck disable=SC2034
target_ssh=$mount/vfat/ssh
