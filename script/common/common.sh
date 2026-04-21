#!/bin/bash

version=v0.1.0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PINK='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m'
BOLD=$(tput bold)
NORM=$(tput sgr0)

function header() {
    local filename=$(basename -- "$1")
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
if [ -f conf/pimake.local ]; then
    source conf/pimake.local
else
    source conf/pimake.conf
fi

source "conf/distro/$source_image_distro/index.conf"

# Derived paths
package=$workspace_dir/package/$source_image_archive
package_checksum=$workspace_dir/package/$source_image_hash
package_curl_log=$workspace_dir/package/$source_image_archive.log
package_checksum_curl_log=$workspace_dir/package/$source_image_archive_hash.log
build=$workspace_dir/build/$source_image_archive
build_checksum=$workspace_dir/build/$source_image_hash
image=$workspace_dir/img/$source_image_name.img
mount=$workspace_dir/mnt/$source_image_name
target_root=$mount/ext4
target_conf=$mount/vfat/config.txt
target_ssh=$mount/vfat/ssh
