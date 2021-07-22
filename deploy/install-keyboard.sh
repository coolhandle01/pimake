#!/bin/bash

#
# install matchbox-keyboard
#

if [ "$(whoami)" != "root" ]; then
	echo \# Sorry, you are not root.
	exit 1
fi

echo \# update
apt -y update

echo \# install matchbox-keyboard
apt -y install matchbox-keyboard

echo \# you should shutdown -r now

exit 0
