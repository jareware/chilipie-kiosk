# Welcome to chilipie-kiosk

**Looks like this might be your first boot!**

This document lists some things you can do to customize your kiosk. You'll want to plug in a keyboard at this point.

## Setting the URL

Press `F11` to exit the full screen mode, and `Ctrl + L` to focus the location bar. Navigate away! Once done, press `F11` again to re-enter full screen mode.

Chromium is configured to remember the URL where you left off (and all logins etc), so this might be all the configuration you need to do!

## What to show

Whatever, the Internet is your oyster! If you need simple auto-refresh, or timed cycling through several URL's, [`sideshow`](https://github.com/mieky/sideshow) is a great option.

## Getting a terminal

You can get to a virtual terminal by pressing e.g. `Ctrl + Alt + F5`, and logging in with `pi:raspberry`. Use `Ctrl + Alt + F8` to switch back to the window manager.

## Enabling WiFi

Set the SSID and password of the network you're connecting to, with:

    $ sudo vim ~/wlan.conf

Reboot to make sure your Pi joins the network automatically.

## Enabling SSH

The default credentials of `pi:raspberry` aren't terribly secure, so remote access is disabled by default. To enable SSH until next reboot:

    $ sudo systemctl start ssh.service

Or, to enable it permanently:

    $ sudo systemctl enable ssh.service

Use `ifconfig` to figure out your IP address, and `ssh` in.

## Controlling the display

The scripts `~/display-on.sh` and `~/display-off.sh` control the HDMI output of the Raspberry Pi.

There's a sample configuration in the crontab for turning the display off outside of office hours - use `crontab -e` to uncomment it.
