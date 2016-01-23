1. Flash your SD card (assuming OS X):
    1. Get [Ubuntu MATE 15.10.1](https://ubuntu-mate.org/raspberry-pi/) and decompress into an `.img` file
    1. `$ diskutil list` to check correct device
    1. `$ diskutil unmountDisk /dev/disk2` to prepare it for imaging
    1. `$ sudo dd bs=1m if=ubuntu-mate-15.10.1-desktop-armhf-raspberry-pi-2.img of=/dev/disk2` (may take up to an hour)
1. Boot your Raspberry Pi using the SD card
1. Answer basic questions (timezone, keyboard layout, default user, etc)
    1. Set hostname to `chilipie-kiosk`
    1. Set username/password to `pi:raspberry` (or whatever you want)
    1. Log in automatically after boot
1. At this point you can already SSH onto the Pi and do the rest of the setup remotely
1. `$ sudo visudo` and add `pi ALL=(ALL) NOPASSWD: ALL` to allow sudo without password prompt
1. Disable MATE's default desktop with `$ sudo graphical disable` (though later nodm will boot directly to matchbox anyway)
1. [Re-size the SD card file system](https://ubuntu-mate.org/raspberry-pi/):
    1. `$ sudo fdisk /dev/mmcblk0`
    1. Delete the second partition (d, 2), then re-create it using the defaults (n, p, 2, enter, enter), then write and exit (w)
    1. Reboot
    1. `$ sudo resize2fs /dev/mmcblk0p2`
    1. Reboot
1. Clean up MATE's desktop cruft with `$ rm -rf ~/*`
1. Install some packages we'll need:
    1. `$ sudo apt-get update && sudo apt-get install -y vim nodm matchbox-window-manager unclutter chromium-browser mailutils nitrogen`
    1. When mailutils prompts about its setup, "local only" is fine
1. Make sure [automatic software updates are disabled](http://ask.xmodulo.com/disable-automatic-updates-ubuntu.html), in `/etc/apt/apt.conf.d/10periodic`:

        APT::Periodic::Unattended-Upgrade "0";
        APT::Periodic::Update-Package-Lists "0";
        APT::Periodic::Download-Upgradeable-Packages "0";
        APT::Periodic::AutocleanInterval "0";

1. In `/etc/default/nodm`, set:

        NODM_ENABLED=true
        NODM_USER=pi

1. Get default scripts with `$ wget https://github.com/futurice/chilipie-kiosk/archive/master.zip && cp chilipie-kiosk-master/dist/{*,.*} . && rm -rf chilipie-kiosk-master/ master.zip`
