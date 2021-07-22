#!/bin/bash
source script/common/config.sh

#
# define some general terminology
#

# PiMake version
version=v0.1.0

#
# raspian-version.conf
#
workspace_dir=$(cfg_read conf/pimake.local workspace_dir)

source_image_user=$(cfg_read conf/pimake.local source_image_user)

# download domain for raspbian image
source_image_domain=$(cfg_read conf/pimake.local source_image_domain)

# the build of the raspbian image
source_image_build=$(cfg_read conf/pimake.local source_image_build)

# the release of the raspbian image
source_image_release=$(cfg_read conf/pimake.local source_image_release)

# the name of the raspbiam image
source_image_name=$(cfg_read conf/pimake.local source_image_name)
source_image_archive=$(cfg_read conf/pimake.local source_image_archive)

# the sha256sum of the image as found at image_url
source_image_sha=$(cfg_read conf/pimake.local source_image_sha)

#
#
#

# download url for raspbian image archive
source_image_url=https://$source_image_domain/$source_image_build/images/$source_image_build-$source_image_release

source_archive=$source_image_archive

# the name of the zip file downloaded
url=$source_image_url/$source_archive

# the source package from image_url
package=$workspace_dir/package/$source_archive
package_checksum=$workspace_dir/package/$source_archive.sha265

# the image in the package
image=$workspace_dir/img/$source_image_name.img

# the mount point root for the repo
mount=$workspace_dir/mnt/$source_image_name

# commonly used paths in the build
target_root=$mount/ext4
target_conf=$mount/vfat/config.txt
target_ssh=$mount/vfat/ssh

# the output .zip for flashing to your SD
build=$workspace_dir/build/$source_archive
build_checksum=$workspace_dir/build/$source_archive.sha256

#
# echo arg and image name
#

function header() {
    if [ -n $1 ]; then
        local filename=$(basename -- "$1")
        echo \# ${filename%%.*} $source_image_name
    fi
}

#
# check a user is $1
#
function check_user () {
    if [ "$(whoami)" = "$1" ]; then
        return 1
    else
        echo \# but $USER, you\'re not $1?
        exit 1
    fi
}

function check_error () {
    if [ $? -gt 0 ]; then
        echo \# detected an error - exiting code $?
        exit $?
    else
        return 0
    fi
}