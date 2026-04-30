#!/bin/bash

#
# install matchbox-keyboard
#

msg()  { echo -e "# \033[0;37m$*\033[0m"; }
errr() { echo -e "# \033[1;31m$*\033[0m"; }
ok()   { echo -e "# \033[1;32m$*\033[0m"; }
note() { echo -e "# \033[0;36m$*\033[0m"; }

if [ "$(whoami)" != "root" ]; then
    errr "you are not root."
    exit 1
fi

msg "update"
apt -y update

msg "install matchbox-keyboard"
apt -y install matchbox-keyboard

ok "done."
note "you should: shutdown -r now"

exit 0
