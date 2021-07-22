#!/bin/bash

#
# deploy the $deploy user
# - https://plusbryan.com/my-first-5-minutes-on-a-server-or-essential-security-for-linux-servers
# - https://github.com/mr-r3b00t/kali_p05t_1n5ta11/blob/master/post.sh
# - https://chmod-calculator.com

if [ "$(whoami)" != "root" ]; then
	echo \# Sorry, you are not root.
	exit 1
fi

deploy=$1
if [ -z $deploy ]; then
	echo \# Sorry, no username provided.
	exit 1
fi

echo \# configure apt for HTTPS
cp /etc/apt/sources.list sources.bak
apt -y install apt-transport-https
sed -i 's/http:\/\//https:\/\//g' /etc/apt/sources.list
sed -i 's/http:\/\//https:\/\//g' /etc/apt/sources.list.d/raspi.list

echo \# Freshening up system..
apt -y update
apt -y full-upgrade
apt -y autoclean
apt -y autoremove

echo \# configure root user
echo \# - generate randomish password for root
newrootpassword=$(date +%s | sha256sum | base64 | head -c 12 ; echo)
echo "root:$newrootpassword" | chpasswd

echo \# configure $deploy user
useradd $deploy

echo \# - add $deploy user to sudoers group
usermod -aG sudo $deploy

echo \# - generate randomish password for $deploy
newpassword=$(date +%s | sha256sum | base64 | head -c 12 ; echo)
echo "$deploy:$newpassword" | chpasswd

echo \# - generate user environment for $deploy
mkdir -p /home/$deploy/.ssh
touch /home/$deploy/.ssh/authorized_keys
chmod 700 /home/$deploy/.ssh
chmod 600 /home/$deploy/.ssh/authorized_keys
chmod -R go= /home/$deploy
chown $deploy:$deploy /home/$deploy -R

echo \#
echo \# THIS IS YOUR USER PASSWORD, DO NOT LOSE IT:
echo \# $newpassword
echo \#	- you will need to remember it, just store it somewhere
echo \#   secure until you change it later - this password will 
echo \#   only be needed for the ability to log in or use sudo.
echo \#
echo \# THIS IS YOUR ROOT PASSWORD, DO NOT LOSE IT:
echo \# $newrootpassword
echo \#	- you won’t need to remember it, just store it somewhere
echo \#   secure - this password will only be needed if you lose
echo \#   the ability to log in over ssh or lose your sudo password.
echo \#
echo \# TO PROVISION SSH ACCESS:
echo \# ssh-keygen -f \~/.ssh/keys/$HOSTNAME/$deploy -t rsa -b 4096
echo \# ssh-copy-id -i \~/.ssh/keys/$HOSTNAME/$deploy $deploy@$HOSTNAME
echo \#
echo \# you should shutdown -r now

exit 0
