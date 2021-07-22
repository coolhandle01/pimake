# PiMake usage

A quick How-To:

```bash
#!/bin/bash

mkdir -p ~/repos/pimake
cd ~/repos/pimake

git clone https://github.com/coolhandle01/pimake .
sudo chmod -R +x script/

# setup the workspace
./pimake init

# TODO
#./pimake init --deploy username --source-url https://raspian.org... --target-disk /dev/mmcblk0
#./pimake init --deploy username --source-img ~/images/... --target-disk /dev/mmcblk0

# remove the build and source .zip
# - omit --fresh to just delete the source zip
./pimake clean --fresh   

# get the source raspi image
./pimake fetch

# TODO or
# ./pimake rip --source-image /dev/mmcblk0

# unpack the .img
./pimake unpack

# modify the .img
sudo ./pimake build          

# repack the .img
./pimake pack                

# burn the image to the target disk
./pimake burn

exit 0
```

# Some related reading

Most articles on the web about doing this include use of usb_modeswitch because they often demonstrate how to get an RPi online with USB modem - which is what I'll be trying until I can afford something GPIO-ey. Here are some links to related work.

- Connecting to a 3G network using a USB Modem with wvdial
  https://www.thefanclub.co.za/how-to/how-setup-usb-3g-modem-raspberry-pi-using-usbmodeswitch-and-wvdial

- Same, with sakis3g (defunct?)
  https://lawrencematthew.wordpress.com/2013/08/07/connect-raspberry-pi-to-a-3g-network-automatically-during-its-boot/

In terms of Open Source Hardware, there seems to be some stuff for sale out there. I found Sixfab - [GitHub](https://github.com/sixfab/Sixfab_RPi_3G-4G-LTE_Base_Shield),
  [webstore](https://sixfab.com/product/raspberry-pi-4g-lte-shield-kit/), who seem to use some simple driver from a 3rd party model, and indeed sell an RPi 'hat' kit that comes with that modem. They bundle a .zip in their github :/

There is some [raspberrypi.org documentation](https://www.raspberrypi.org/documentation/configuration/wireless/wireless-cli.md) on configuring WiFi. I thought wpa_supplicant was supposed to be old hat but, cool.

There are products on the market that apparently run Linux on a dual boot with Android that use 4G and WiFi to connect, but, they are somewhat proprietary. Use your favourite search engine to take a look.

