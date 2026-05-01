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
    # shellcheck disable=SC2317
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

if [ "$user_configure_enabled" -eq 1 ]; then
    title "configure first-boot user ($userconf_mechanism)"
    case "$userconf_mechanism" in
        userconf_txt)
            hashed=$(openssl passwd -6 "$user_password")
            echo "$user_name:$hashed" > "$target_boot/userconf.txt"
            msg "wrote userconf.txt for $user_name"
            ;;
        cloud_init)
            hashed=$(openssl passwd -6 "$user_password")
            {
                echo "#cloud-config"
                echo "users:"
                echo "  - name: $user_name"
                echo "    sudo: ALL=(ALL) NOPASSWD:ALL"
                echo "    groups: sudo,adm"
                echo "    lock_passwd: false"
                echo "    passwd: $hashed"
                if [ -n "$user_ssh_public_key" ]; then
                    echo "    ssh_authorized_keys:"
                    echo "      - $user_ssh_public_key"
                fi
            } > "$target_boot/user-data"
            msg "wrote cloud-init user-data for $user_name"
            ;;
        none)
            warn "$source_image_distro does not support build-time user provisioning"
            ;;
        *)
            warn "unknown userconf_mechanism '$userconf_mechanism'"
            ;;
    esac
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

if [ "$user_configure_enabled" -eq 1 ] && [ "$userconf_mechanism" = "userconf_txt" ] && [ -n "$user_ssh_public_key" ]; then
    title "inject SSH public key"
    ssh_dir="$target_root/home/$user_name/.ssh"
    mkdir -p "$ssh_dir"
    echo "$user_ssh_public_key" > "$ssh_dir/authorized_keys"
    chmod 700 "$ssh_dir"
    chmod 600 "$ssh_dir/authorized_keys"
    # user created on first boot; RPi OS assigns UID/GID 1000 to the first user
    chown -R 1000:1000 "$target_root/home/$user_name"
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' \
        "$target_root/etc/ssh/sshd_config"
    msg "injected SSH public key, disabled password authentication"
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
