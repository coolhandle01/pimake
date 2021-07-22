#!/bin/bash
echo \# PiMake: Testing..
{
    rm -rf workspace
    cp conf/pimake.conf.test conf/pimake.local

    ./pimake init
    ./pimake clean --fresh
    ./pimake fetch
    ./pimake unpack
    sudo ./pimake build
    ./pimake pack

    # TODO
    #./pimake init --ssh --opengl --touchscreen --wifi-locale gb --wifi-ssid ssid --wifi-pass secret!
    #./pimake init --opengl --gsm-provider provider --gsm-user user --gsm-pass secret! --gsm-baud 460800
    #./pimake fetch --source-url https://example.tld/images/raspberrypi/.. --source-sha256
    #./pimake rip --source-img ~/Downloads/images/..
    #./pimake burn --target-disk /dev/mmcblk0

} > test.log

exit 0