#!/bin/bash
source script/common/version.sh
source script/common/vfat.sh
source script/common/ext4.sh

header "$0"

#
# build a pimake-pi raspbian image
#

check_user root

wpa_conf=$target_root/etc/wpa_supplicant/wpa_supplicant.conf
wvdial_conf=$target_root/etc/wvdial.conf

rpiconf=conf/pimake.local

# fdisk -l $image

mount_vfat
check_error

ssh_configure_enabled=$(cfg_read $rpiconf ssh_configure_enabled)
if [ $ssh_configure_enabled -eq 1 ]; then
    title "configure SSH"
    touch $target_ssh
fi

opengl_activate_enabled=$(cfg_read $rpiconf opengl_activate_enabled)
if [ $opengl_activate_enabled -eq 1 ]; then
    title "configure the GL driver"
    echo -e "\n# Activate the GL driver" >> $target_conf
    echo -e "dtoverlay=vc4-kms-v3d" >> $target_conf
fi

hdmi_install_enabled=$(cfg_read $rpiconf hdmi_install_enabled)
hdmi_cvt=$(cfg_read $rpiconf hdmi_cvt)
if [ $hdmi_install_enabled -eq 1 ]; then
    title "configure HDMI"
    echo -e "\n# Configure touchscreen" >> $target_conf
    echo -e "hdmi_group=2" >> $target_conf
    echo -e "hdmi_mode=1" >> $target_conf
    echo -e "hdmi_mode=87" >> $target_conf
    echo -e "hdmi_cvt $hdmi_cvt" >> $target_conf
fi

unmount_vfat

mount_ext4
check_error

msg "install pimake deploy scripts to /opt/pimake"
mkdir -p $target_root/opt/pimake
cp -r deploy/* $target_root/opt/pimake

serial_console_enabled=$(cfg_read $rpiconf serial_console_enabled)
if [ $serial_console_enabled -eq 1 ]; then
    title "configure serial console"
fi

wpa_network_enabled=$(cfg_read $rpiconf wpa_network_enabled)
if [ $wpa_network_enabled -eq 1 ]; then
    title "configure WiFi"

#    mkdir -p $target_root/etc/wpa_supplicant
#    echo "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev" >> $wpa_conf
#    echo "update_config=1" >> $wpa_conf
    echo "country=$(cfg_read $rpiconf wpa_network_locale)" >> $wpa_conf
    echo "network={" >> $wpa_conf
    echo "    scan_ssid=1" >> $wpa_conf
    echo "    "ssid="$(cfg_read $rpiconf wpa_network_ssid)" >> $wpa_conf
    echo "    "psk="$(cfg_read $rpiconf wpa_network_password)" >> $wpa_conf
    echo "}" >> $wpa_conf
fi

gsm_network_enabled=$(cfg_read $rpiconf gsm_network_enabled)
if [ $gsm_network_enabled -eq 1 ]; then  
    title "configure GSM"

    touch $wvdial_conf
    echo [Dialer $(cfg_read $rpiconf gsm_network_provider)] >> $wvdial_conf
    echo Init1 = ATZ >> $wvdial_conf
    echo Init2 = ATQ0 V1 E1 S0=0 &C1 &D2 +FCLASS=0 >> $wvdial_conf
    echo Init3 = AT+CGDCONT=1,"IP","internet" >> $wvdial_conf
    echo Stupid Mode = 1 >> $wvdial_conf
    echo Modem Type = Analog Modem >> $wvdial_conf
    echo ISDN = 0 >> $wvdial_conf
    echo Phone = *99# >> $wvdial_conf
    echo Modem = /dev/gsmmodem >> $wvdial_conf
    echo Username = $(cfg_read $rpiconf gsm_network_username) >> $wvdial_conf
    echo Password = $(cfg_read $rpiconf gsm_network_password) >> $wvdial_conf
    echo Baud = $(cfg_read $rpiconf gsm_network_baud) >> $wvdial_conf

fi

unmount_ext4

exit 0
