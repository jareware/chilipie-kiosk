# Image setup

## Baseline setup

Replace `$TAG` with whatever version is being built, e.g. `v2.0.0`.

1.  Check that the version in `.chilipie-kiosk-version` matches `$TAG`
1.  Run `./md-to-html.sh`
1.  Check that all changes have been pushed to GitHub
1.  Get Raspbian Lite (`2018-06-27-raspbian-stretch-lite.zip`)
1.  Flash it onto an SD card (use [Etcher](https://etcher.io) or `dd`)
1.  Re-mount the card
1.  Update the file `/Volumes/boot/cmdline.txt` on the card:
    ```diff
    -dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=PARTUUID=4d3ee428-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait quiet init=/usr/lib/raspi-config/init_resize.sh
    +dwc_otg.lpm_enable=0 console=serial0,115200 console=tty3 root=PARTUUID=4d3ee428-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait quiet splash quiet plymouth.ignore-serial-consoles logo.nologo vt.global_cursor_default=0
    ```
    The removal of `init=/usr/lib/raspi-config/init_resize.sh` disables the automatic expansion of the root FS to cover the whole SD card on first boot; the rest is for [customizing the Plymouth boot theme](https://scribles.net/customizing-boot-up-screen-on-raspberry-pi/)
1.  Disable overscan (as it's rarely needed on modern displays) in `/Volumes/boot/config.txt` with:
    ```diff
    -#disable_overscan=1
    +disable_overscan=1
    ```
1.  In the same file, append `disable_splash=1`
1.  Safely unmount the card
1.  Boot your Pi from the SD card
1.  Run `sudo raspi-config` and:
    1.  Set localization options
    1.  Set hostname to `chilipie-kiosk`
    1.  Join a WiFi (if wired network isn't available for setup)
    1.  Enable SSH
    1.  Set automatic CLI login after boot
1.  At this point you can already SSH onto the Pi and do the rest of the setup remotely
1.  [Resize the root partition](https://elinux.org/RPi_Resize_Flash_Partitions#Manually_resizing_the_SD_card_on_Raspberry_Pi) to make space for additional software
    1.  `sudo fdisk /dev/mmcblk0`
    1.  `p`
    1.  Make note of the "Start" value of the 2nd partition (e.g. `98304`)
    1.  `d`
    1.  `2`
    1.  `n`
    1.  `p`
    1.  `2`
    1.  For "First sector", enter the "Start" value from above (e.g. `98304`)
    1.  For "Last sector", enter `+2500M` (we only need about ~2.5G of space; any extra just makes dumping the image more tedious)
    1.  If asked if you want to remove the existing "ext4" signature, say `y`
    1.  `w`
    1.  If you get an error about "Re-reading the partition table failed.: Device or resource busy", it's fine
    1.  `sudo reboot`
    1.  `sudo resize2fs /dev/mmcblk0p2`
    1.  `df -h`
1.  Install some packages we'll need: `sudo apt-get update && sudo apt-get install -y vim matchbox-window-manager unclutter mailutils nitrogen jq chromium-browser xserver-xorg xinit rpd-plym-splash xdotool`
    -   We install mailutils so that you can check `mail` for cronjob output
1.  Get default scripts with `wget "https://github.com/futurice/chilipie-kiosk/archive/master.zip" && unzip master.zip && cp -v $(find chilipie-kiosk-master/home/ -type f) . && rm -rf chilipie-kiosk-master/ master.zip`
1.  [Customize Plymouth boot theme graphics](https://scribles.net/customizing-boot-up-screen-on-raspberry-pi/) with `sudo rm /usr/share/plymouth/themes/pix/splash.png && sudo ln -s /home/pi/background.png /usr/share/plymouth/themes/pix/splash.png`
1.  Put in the example crontab with `crontab crontab.example`
1.  Disable SSH access again (because the default credentials aren't very secure) with `sudo raspi-config`
1.  Reboot (should land you in Chromium)
1.  Tell Chromium we don't want to sign in
1.  Configure Chromium to start from "where you left off", and navigate to `file:///home/pi/first-boot.html`
1.  Gracefully shut down the Pi

## Dumping the image

Assuming OS X:

1.  `diskutil list` to check correct device
1.  `diskutil unmountDisk /dev/disk3` to prepare it for imaging
1.  `TAG=2.0.0-dev` (or whatever the current version is)
1.  `sudo dd bs=1m count=3000 if=/dev/disk3 of=chilipie-kiosk-$TAG.img` (only dump the relevant first 3 GB)
1.  `COPYFILE_DISABLE=1 tar -zcvf chilipie-kiosk-$TAG.img.tar.gz chilipie-kiosk-$TAG.img`
1.  `openssl sha1 chilipie-kiosk-$TAG.img*` and include hash in release notes
