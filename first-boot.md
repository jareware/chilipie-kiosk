# Welcome to chilipie-kiosk

**Looks like this is your first boot!**

This document lists some things you can do to customize your kiosk. You'll need to plug in a keyboard for this initial setup, but after that, it's perfectly fine to leave the kiosk running without any peripherals plugged in.

## Setting the URL

Press `F11` to exit the full screen mode, and `Ctrl + L` to focus the location bar. Navigate away! Once done, press `F11` again to re-enter full screen mode.

Chromium is configured to remember the URL where you left off (and all logins, etc), so this might be all the configuration you need to do!

## Getting to a terminal

You can get to a virtual terminal by pressing `Ctrl + Alt + F2`, and logging in with username `pi` and password `raspberry`. Use `Ctrl + Alt + F1` to switch back to Chromium.

## System configuration

Use `sudo raspi-config` in the terminal to do things like:

* Join a WiFi network
* Change the system timezone
* Change your keyboard layout
* Enable SSH access (it's disabled by default for security reasons)

## Automating things

There's a few commonly useful snippets already on the crontab, such as:

* **Rebooting the Pi every night at 3 AM**. If you run resource intensive pages on your dashboard, the Pi can eventually start to slow down. A nightly reboot keeps it rested and refreshed! This is enabled by default.
* **Turning the display off for the night**. This helps save energy when there's no-one there to look at your dashboard. Sometimes also useful for reasons of vanity, when bright displays in the middle of a dark office would look ridiculous. Do make sure your display/television comes back on, however: especially older TV's sometimes won't know to automatically turn back on when the HDMI signal comes back on. In those cases, you may have luck with [CEC signals](https://timleland.com/raspberry-pi-turn-tv-onoff-cec/), but also you may not. If nothing else works, you can always just [blank the display](https://askubuntu.com/a/7299).
* **Automatically reloading the active page every hour**. If the page you're displaying doesn't automatically update itself, this is effectively the same as hitting `Ctrl + R` every hour. Very crude. Very effective.
* **Cycling between open tabs every 5 minutes**. Same as above, but for `Ctrl + Tab`. Note that if you use both at the same time, you can combine them, to send the reload command *just before* sending the tab cycle command. This causes the pages to reload while they're in the background, so the user never sees it happening.

Use `crontab -e` to check these out, enable the ones you want, or customize them to your heart's content.

## Customizing Chromium

Because you're running a fully-featured Chromium, you can customize it further by [installing browser extensions](https://chrome.google.com/webstore/category/extensions). For instance, [Tampermonkey](https://chrome.google.com/webstore/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo) can be useful for injecting custom JS or CSS to a page you're displaying.

## Adjusting your resolution

If the display auto-detection fails and chooses a funky default resolution for you, [there's a few things you can do](https://www.opentechguides.com/how-to/article/raspberry-pi/28/raspi-display-setting.html) to try and fix that.

## Replacing the boot graphics

The image that's displayed while the kiosk is starting can be changed by just replacing `~/background.png`.

To change the default chilipie-kiosk boot graphics to a nice doge, for example, try `wget -O background.png https://bit.ly/2w1P4Il`.

## Increasing boot show delay

By default, the browser window is hidden for a few seconds after boot, to give the page time to load. You can increase (or decrease) this delay in `~/.xsession`.
