#!/bin/bash

#
# deploy the $deploy user
# - https://plusbryan.com/my-first-5-minutes-on-a-server-or-essential-security-for-linux-servers
# - https://github.com/mr-r3b00t/kali_p05t_1n5ta11/blob/master/post.sh
# - https://chmod-calculator.com

msg()  { echo -e "# \033[0;37m$*\033[0m"; }
note() { echo -e "# \033[0;36m$*\033[0m"; }
errr() { echo -e "# \033[1;31m$*\033[0m"; }
ok()   { echo -e "# \033[1;32m$*\033[0m"; }

if [ "$(whoami)" != "root" ]; then
    errr "you are not root."
    exit 1
fi

deploy=$1
if [ -z "$deploy" ]; then
    errr "no username provided."
    exit 1
fi

msg "configure apt for HTTPS"
cp /etc/apt/sources.list sources.bak
apt -y install apt-transport-https
sed -i 's/http:\/\//https:\/\//g' /etc/apt/sources.list
sed -i 's/http:\/\//https:\/\//g' /etc/apt/sources.list.d/raspi.list

msg "freshening up system"
apt -y update
apt -y full-upgrade
apt -y autoclean
apt -y autoremove

msg "configure root user"
newrootpassword=$(date +%s | sha256sum | base64 | head -c 12 ; echo)
echo "root:$newrootpassword" | chpasswd

msg "configure $deploy user"
useradd "$deploy"
usermod -aG sudo "$deploy"
newpassword=$(date +%s | sha256sum | base64 | head -c 12 ; echo)
echo "$deploy:$newpassword" | chpasswd

msg "generate user environment for $deploy"
mkdir -p "/home/$deploy/.ssh"
touch "/home/$deploy/.ssh/authorized_keys"
chmod 700 "/home/$deploy/.ssh"
chmod 600 "/home/$deploy/.ssh/authorized_keys"
chmod -R go= "/home/$deploy"
chown "$deploy":"$deploy" "/home/$deploy" -R

ok "done."
echo "#"
note "USER PASSWORD (do not lose this):"
note "  $newpassword"
note "  needed to log in and use sudo."
echo "#"
note "ROOT PASSWORD (do not lose this):"
note "  $newrootpassword"
note "  only needed if you lose SSH access or your sudo password."
echo "#"
note "TO PROVISION SSH ACCESS:"
note "  ssh-keygen -f ~/.ssh/keys/\$HOSTNAME/$deploy -t rsa -b 4096"
note "  ssh-copy-id -i ~/.ssh/keys/\$HOSTNAME/$deploy $deploy@\$HOSTNAME"
echo "#"
note "you should: shutdown -r now"

exit 0
