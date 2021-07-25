# pimake

pimake is a set of bash scripts designed to semi-automate raspberry-pi image f*ckery on debian systems, making it easy to fetch, unpack, modify, and repack a Raspbian image, and flash it to an SD card, with tools on-board to simplify setting up a new user with ssh enabled.

### Commands
Once the repo is cloned, there is a `pimake` at the root. This script is how pimake commands are executed. `<repo>/pimake` can:
- `init` - create working directories
- `clean --fresh` - clean working directories, including any downloaded image files and backups and conf/pimake.local
- `fetch` - get a new Raspbian
- `rip` - rip an image from a disk
- `unpack` - unpack the .img or re-verify existing
- `build` - requires sudo to mount the image partitions and alter/add files
- `pack` - packs the image to a zip file ready for flashing to your Raspberry Pi
- `burn` - burns the image to a disk

### Image Configuration

The following modifications to the Raspbian image are all disabled by default in `<repo>/conf/pimake.local` and actioned by the `build` command.

- Configure source of HTTPS download of the base Raspbian image
- Configure HDMI/touchscreen
- Configure Enable OpenGL Driver
- Configure Enable SSH 
- Configure wpa_supplicant for WiFi connectivity 
- Configure WvDial for 3G/4G connectivity
    - WIP

`pimake.local` is setup to get the Official Raspbian Buster image by default, but values for the Official Raspbian Buster Lite image are present in the file. These could in theory point to anything.

### Deployment

Use the `burn` command, or something like Etcher to flash the .zip at `<repo>/workspace/build` to your SD card, boot the Pi with a display and keyboard connected, and log in as the default pi user.

Run the scripts in /opt/pimake ..
```bash
# ensure the scripts are executable
pi@raspberrypi: $ sudo chmod -R +x /opt/pimake ; ll /opt/pimake

# deploy the user and initialise services
# - copy your new root and users password from output
pi@raspberrypi: $ sudo ./opt/pimake/deploy.sh <username>

# optionally delete the pi user
pi@raspberrypi: $ sudo ./opt/pimake/final.sh

# ideally delete the pimake scripts
pi@raspberrypi: $ sudo rm -rf /opt/pimake
```

## Why?

[Tinker's blog post](https://www.tinker.sh/kde-plamo-rpi/) suggests some milestones along the journey to the goal of making a FOSSH smartphone concept. It also demonstrated how to get KDE Plasma working on a Raspberry Pi, giving a phone-like interface and touch input to Raspbian. 

This project was started inpired by that blog, as it was something I'd also considered, and I wanted to automate the steps outlined there. Since then, [Pine64](https://www.pine64.org/pinephone/) has been invented - and they make devices similar to the Raspberry-Pi too.
