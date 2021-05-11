# chilipie-kiosk

Easy-to-use **Raspberry Pi** image for booting directly into **full-screen Chrome**, with built-in convenience features for unattended operation. Perfect for **dashboards and build monitors**.

## Features

![Screenshots](https://github.com/futurice/chilipie-kiosk/blob/master/docs/screenshot.png)

```
▲ Customizable, full screen        ▲ Boots directly into a simple     ▲ WiFi & other system config
      startup graphics                  getting started -guide          is just one keypress away
```

- **Boots directly to full-screen Chrome** - with all the features of a modern browser
- **No automatic updates** - no surprises due to Chrome (or other packages) suddenly updating
- **Automatic crash-recovery** - accidental unpowering won't result in "Chrome did not shut down correctly :("
- **Custom startup graphics** - displays [customizable graphics](home/background.png) instead of console messages during startup
- **Lightweight window manager** - uses [Matchbox](https://www.yoctoproject.org/tools-resources/projects/matchbox) for minimal clutter and memory footprint
- **HDMI output control** - ready-made scripts for [turning off the display](home/crontab.example) outside of office hours, for example
- **Cursor hiding** - if you leave a mouse plugged in, the cursor is hidden after a brief period of inactivity
- **Automatic reboots** - reboots the Pi nightly, when nobody's watching, to keep it running smoothly
- **Based on a recent Debian** - if you want to add your own tweaks, all the expected packages are one `apt-get` away
- **Batteries included** - the most common how-to's and ProTips have been collected to the [first-boot document](docs/first-boot.md)

## Getting started

1. Check that you have [compatible hardware](#hardware).
2. Download the [latest image](https://github.com/futurice/chilipie-kiosk/releases).
3. Decompress it.
4. Flash the image onto your SD card. We recommend [Etcher](https://etcher.io/) for this: it's delightfully easy to use, cross platform, and will verify the result automatically. If you know what you're doing, you can of course also just `sudo dd bs=1m if=chilipie-kiosk-vX.Y.Z.img of=/dev/rdisk2`.
5. *Optional*: [Setup automatic WiFi](#automatic-wifi-setup)
6. Insert the SD card to your Pi and power it up.
7. You should land in the [first-boot document](docs/first-boot.md), for further instructions & ideas.

### Automatic WiFi setup

1. After flashing remount your SD card.
2. Create a wpa_supplicant.conf in your SD cards boot folder
3. Copy the [sample wpa_supplicant.conf](#sample-wpasupplicantconf) file into the boot folder on the SD card.
4. Replace `WiFi-SSID` and `WiFi-PASSWORD` with your WiFi configuration.
5. *Optional*: Set the country code to your country code e.g. DE.

#### Sample wpa_supplicant.conf
```
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

network={
    ssid="WiFi-SSID"
    psk="WiFi-PASSWORD"
    key_mgmt=WPA-PSK
}
```

## Hardware

Works with [Raspberry Pi versions 1, 2 & 3](https://www.raspberrypi.org/products/). The 3 series is recommended, as it's the most powerful, and comes with built-in WiFi (though both [official](https://www.raspberrypi.org/products/raspberry-pi-usb-wifi-dongle/) and [off-the-shelf](https://elinux.org/RPi_USB_Wi-Fi_Adapters) USB WiFi dongles can work equally well).

Make sure you have a [compatible 4+ GB SD card](http://elinux.org/RPi_SD_cards). In general, any Class 10 card will work, as they're fast enough and of high enough quality.

The Pi needs a [2.5 Amp power source](https://www.raspberrypi.org/documentation/hardware/raspberrypi/power/README.md). Most modern USB chargers you'll have laying around will work, but an older/cheaper one may not.

## Common issues

- **I get a kernel panic on boot, or the image keeps crashing.** The Raspberry Pi is somewhat picky about about its SD cards. It's also possible the SD card has a bad sector in a critical place, and `dd` wasn't be able to tell you. Double-check that you're using [a blessed SD card](http://elinux.org/RPi_SD_cards), and try flashing the image again.
- **I see a "rainbow square" or "yellow lightning" in the top right corner of the screen, and the device seems unstable.** This usually means the Pi isn't getting enough amps from your power supply. This is sometimes the case in more exotic setups (e.g. using the USB port of your display to power the Pi) or with cheap power supplies. Try another one.
- **The [display control scripts](home/display-on.sh) don't turn off the display device.** Normal PC displays will usually power down when you cut off the signal, but this is not the case for many TV's. Please check if your TV has an option in its settings for enabling this, as some do. If not, you can [try your luck with HDMI CEC signals](http://raspberrypi.stackexchange.com/questions/9142/commands-for-using-cec-client), but the TV implementations of the spec are notoriously spotty.
- **The MicroSD card isn't flashing correctly, I don't see the boot partition.** This commonly happens on Windows computers and can be fixed by extracting the `chilipie*.img` file from the `tar.gz`. You will need to use an extraction tool that supports both gzip and tar archive formats, such as 7zip. Extract the contents of the `img.tar.gz` file, then extract the contents of the resulting `img.tar` file again. You should be left with an `.img` file, which you can then use with Etcher to flash your SD card.

## Acknowledgements

This project is a grateful recipient of [Futurice Open Source sponsorship](http://futurice.com/blog/sponsoring-free-time-open-source-activities). Thank you. 🙇
