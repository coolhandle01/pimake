#!/bin/bash

# PiMake version
version=v0.1.0

source script/common/config.sh
source script/common/util.sh

#
# define some general terminology
#

function header() {
    local filename=$(basename -- "$1")
    echo -e "# ${CYAN}${BOLD}$source_image_distro: ${filename%%.*}${NC}${NORM}"
}
function title () {
    echo -e "#${RED}${BOLD}$source_image_distro: $1${NC}${NORM}"
}
function errr () {
    echo -e "#${RED}${BOLD}$source_image_distro: ERROR $?${NC}${NORM}"
}
function warn() {
    echo -e "# ${YELLOW}${BOLD}$source_image_distro: $1${NC}${NORM}"
}
function msg() {
    echo -e "# ${WHITE}$source_image_distro: $1${NC}"
}
function okmsg() {
    echo -e "# ${GREEN}${BOLD}$source_image_distro: $1${NC}${NORM}"
}


#
# check a user is $1
#
function check_user () {
    if [ "$(whoami)" = "$1" ]; then
        return 1
    else
        warn "but $USER, you\'re not $1?"
        exit 1
    fi
}

#
# check $? is 0
#
function check_error () {
    if [ $? -gt 0 ]; then
        errr "exiting"
        exit $?
    else
        return 0
    fi
}


#
# raspian-version.conf
#

source_image_distro=$(cfg_read conf/pimake.local source_image_distro)
source_image_conf=conf/distro/$source_image_distro/index.conf

source_image_user=$(cfg_read conf/pimake.local source_image_user)

# the release of the raspbian image
source_image_url=$(cfg_read $source_image_conf source_image_url)

# the name of the raspbian image
source_image_name=$(cfg_read $source_image_conf source_image_name)
source_image_archive=$(cfg_read $source_image_conf source_image_archive)

# the sha256sum of the image as found at image_url
source_image_hash=$(cfg_read $source_image_conf source_image_hash)
source_image_hash_expected=$(cfg_read $source_image_conf source_image_hash_expected)
source_image_algo=$(cfg_read $source_image_conf source_image_algo)

#
#
#

workspace_dir=$(cfg_read conf/pimake.local workspace_dir)

# the name of the zip file downloaded


# the source package from image_url
package=$workspace_dir/package/$source_image_archive
package_checksum=$workspace_dir/package/$source_image_hash

# the output .zip for flashing to your SD
build=$workspace_dir/build/$source_image_archive
build_checksum=$workspace_dir/build/$source_image_hash

# the image in the package
image=$workspace_dir/img/$source_image_name.img

# the mount point root for the mounted image
mount=$workspace_dir/mnt/$source_image_name

# commonly used paths in the build
target_root=$mount/ext4
target_conf=$mount/vfat/config.txt
target_ssh=$mount/vfat/ssh

