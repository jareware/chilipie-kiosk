# Welcome to chilipie-kiosk

Looks like this might be your first boot! This document lists some things you can do to customize your kiosk. You'll want to plug in a keyboard at this point.

## Setting the URL

Press `F11` to exit the full screen mode, and `Ctrl + L` to focus the location bar. Navigate away! Once done, press `F11` again to re-enter full screen mode.

Chromium is configured to remember the URL where you left off (and all logins etc), so this might be all the configuration you need to do!

## Getting a terminal

You can get a virtual terminal by pressing e.g. `Ctrl + Alt + F5`, and logging in with `pi:raspberry`. Use `Ctrl + Alt + F8` to switch back to the window manager.

## Enabling SSH

The default credentials of `pi:raspberry` aren't terribly secure, so remote access is disabled by default. To enable SSH until next reboot:

    $ systemctl start ssh.service

Or, to enable it permanently:

    $ systemctl enable ssh.service

Use `ifconfig` to figure out your IP address, and `ssh` in.
