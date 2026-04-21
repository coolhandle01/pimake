#!/bin/bash
source script/common/common.sh
source script/common/vfat.sh
source script/common/ext4.sh

header "$0"

#
# build a pimake-pi raspbian image
#

check_user root

cleanup() {
    [ -n "$LODEV" ] && losetup -d "$LODEV"
}
trap cleanup EXIT

wpa_conf=$target_root/etc/wpa_supplicant/wpa_supplicant.conf
wvdial_conf=$target_root/etc/wvdial.conf

LODEV=$(losetup -fP --show "$image")
check_error

mount_vfat
check_error

if [ "$ssh_configure_enabled" -eq 1 ]; then
    title "configure SSH"
    touch "$target_ssh"
fi

if [ "$opengl_activate_enabled" -eq 1 ]; then
    title "configure the GL driver"
    { echo -e "\n# Activate the GL driver"; echo "dtoverlay=vc4-kms-v3d"; } >> "$target_conf"
fi

if [ "$hdmi_install_enabled" -eq 1 ]; then
    title "configure HDMI"
    {
        echo -e "\n# Configure touchscreen"
        echo "hdmi_group=2"
        echo "hdmi_mode=1"
        echo "hdmi_mode=87"
        echo "hdmi_cvt $hdmi_cvt"
    } >> "$target_conf"
fi

unmount_vfat

mount_ext4
check_error

msg "install pimake deploy scripts to /opt/pimake"
mkdir -p "$target_root/opt/pimake"
cp -r deploy/* "$target_root/opt/pimake"

if [ "$serial_console_enabled" -eq 1 ]; then
    title "configure serial console"
fi

if [ "$wpa_network_enabled" -eq 1 ]; then
    title "configure WiFi"
#    mkdir -p $target_root/etc/wpa_supplicant
#    echo "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev" >> $wpa_conf
#    echo "update_config=1" >> $wpa_conf
    {
        echo "country=$wpa_network_locale"
        echo "network={"
        echo "    scan_ssid=1"
        echo "    ssid=$wpa_network_ssid"
        echo "    psk=$wpa_network_password"
        echo "}"
    } >> "$wpa_conf"
fi

if [ "$gsm_network_enabled" -eq 1 ]; then
    title "configure GSM"
    touch "$wvdial_conf"
    {
        echo "[Dialer $gsm_network_provider]"
        echo "Init1 = ATZ"
        echo "Init2 = ATQ0 V1 E1 S0=0 &C1 &D2 +FCLASS=0"
        echo "Init3 = AT+CGDCONT=1,\"IP\",\"internet\""
        echo "Stupid Mode = 1"
        echo "Modem Type = Analog Modem"
        echo "ISDN = 0"
        echo "Phone = *99#"
        echo "Modem = /dev/gsmmodem"
        echo "Username = $gsm_network_username"
        echo "Password = $gsm_network_password"
        echo "Baud = $gsm_network_baud"
    } >> "$wvdial_conf"
fi

unmount_ext4

exit 0
