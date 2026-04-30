#!/bin/bash

#
# remove the pi user
# - https://plusbryan.com/my-first-5-minutes-on-a-server-or-essential-security-for-linux-servers
#

msg()  { echo -e "# \033[0;37m$*\033[0m"; }
errr() { echo -e "# \033[1;31m$*\033[0m"; }
ok()   { echo -e "# \033[1;32m$*\033[0m"; }

if [ "$(whoami)" != "root" ]; then
    errr "you are not root."
    exit 1
fi

msg "deleting pi user"
userdel -r -f -z pi

ok "done."

exit 0
