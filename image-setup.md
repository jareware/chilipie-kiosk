# Image setup

## Baseline setup

Replace `$TAG` with whatever version is being built, e.g. `v1.2`.

1. Flash your SD card (assuming OS X):
    1. Get [Ubuntu MATE 16.04](https://ubuntu-mate.org/raspberry-pi/) and decompress into an `.img` file
    1. `$ diskutil list` to check correct device
    1. `$ diskutil unmountDisk /dev/disk2` to prepare it for imaging
    1. `$ sudo dd bs=1m if=ubuntu-mate-16.04-desktop-armhf-raspberry-pi.img of=/dev/rdisk2` (will take a while)
1. Boot your Raspberry Pi using the SD card (the setup should be done on a Pi 3, but the resulting image will work on Pi 2 as well)
1. Answer basic questions (timezone, keyboard layout, default user, etc)
    1. Set hostname to `chilipie-kiosk`
    1. Set username/password to `pi:raspberry` (or whatever you want)
    1. Log in automatically after boot
1. At this point you can already SSH onto the Pi and do the rest of the setup remotely
1. `$ sudo visudo` and add `pi ALL=(ALL) NOPASSWD: ALL` to allow sudo without password prompt
1. Disable MATE's default desktop with `$ sudo graphical disable` (though later nodm will boot directly to matchbox anyway)
1. Clean up MATE's desktop cruft with `$ rm -rf ~/*`
1. Remove some packages we don't need: `$ sudo apt-get purge -y $(dpkg --get-selections 'sonic*' 'thunderbird*' 'libreoffice*' 'minecraft*' 'scratch*' 'shotwell*' 'simple-scan*' 'hexchat*' 'pidgin*' 'transmission*' 'youtube-dl*' 'atril*' 'idle*' 'brasero*' 'omxplayer*' 'rhythmbox*' 'supercollider*' 'vlc*' | cut -f 1 | tr '\n' ' ')`
1. Install some packages we'll need: `$ sudo apt-get update && sudo apt-get install -y vim nodm matchbox-window-manager unclutter mailutils nitrogen jq chromium-browser=45.0.2454.101-0ubuntu1.1201 chromium-codecs-ffmpeg=45.0.2454.101-0ubuntu1.1201`
    * When mailutils prompts about its setup, "local only" is fine (we install mailutils so that you can check `mail` for cronjob output)
1. Make sure [automatic software updates are disabled](http://ask.xmodulo.com/disable-automatic-updates-ubuntu.html), in `/etc/apt/apt.conf.d/10periodic`:

        APT::Periodic::Unattended-Upgrade "0";
        APT::Periodic::Update-Package-Lists "0";
        APT::Periodic::Download-Upgradeable-Packages "0";
        APT::Periodic::AutocleanInterval "0";

1. In `/etc/default/nodm`, set:

        NODM_ENABLED=true
        NODM_USER=pi
        NODM_FIRST_VT=8

1. Check that the version in `.chilipie-kiosk-version` matches `$TAG`, and it's on GitHub
1. Get default scripts with `$ wget "https://github.com/futurice/chilipie-kiosk/archive/master.zip" && unzip master.zip && cp -v $(find chilipie-kiosk-master/home/ -type f) . && rm -rf chilipie-kiosk-master/ master.zip`
1. Put in the example crontab with `$ crontab -e`:

        # m h  dom mon dow   command
        
        # 0  7 * * 1-5 ~/display-on.sh  # turn display on weekdays at 7 AM
        # 0 19 * * 1-5 ~/display-off.sh # turn display off weekdays at 7 PM

1. Set up WiFi (for Raspberry Pi 3 only):
    1. Check the interface name with `$ ifconfig`, e.g. `wlan0`
    1. Append to `/etc/network/interfaces`:

        # Internal WiFi adapter
        allow-hotplug wlan0
        iface wlan0 inet dhcp
        wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
        iface default inet dhcp

    1. In `/etc/wpa_supplicant/wpa_supplicant.conf`:

        network={
            ssid="networkname"
            psk="secretpassword"
        }

    1. Symlink the file, for convenience: `$ ln -s /etc/wpa_supplicant/wpa_supplicant.conf wlan.conf`

1. Disable SSH access (because the default credentials aren't very secure): `$ sudo systemctl disable ssh.service`
1. Reboot (should land you in Chromium)
1. Configure Chromium to start from "where you left off", and navigate to https://github.com/futurice/chilipie-kiosk/blob/$TAG/first-boot.md
1. Unpower the Pi

## Dumping the image

Assuming OS X:

1. `$ diskutil list` to check correct device
1. `$ diskutil unmountDisk /dev/disk2` to prepare it for imaging
1. `$ sudo dd bs=1m count=7680 if=/dev/disk2 of=chilipie-kiosk-$TAG.img` (only dump the relevant first ~8 GB, matching the original `ubuntu-mate` image size)
1. `$ openssl sha1 chilipie-kiosk-$TAG.img` and include hash in release notes
1. `$ zip chilipie-kiosk-$TAG.img.zip chilipie-kiosk-$TAG.img`
