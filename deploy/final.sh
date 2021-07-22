#!/bin/bash

#
# remove the pi user
# - https://plusbryan.com/my-first-5-minutes-on-a-server-or-essential-security-for-linux-servers
#

if [ "$(whoami)" != "root" ]; then
	echo \# Sorry, you are not root.
	exit 1
fi

echo \# deleting pi user!
userdel -r -f -z pi

echo \# done.

exit 0