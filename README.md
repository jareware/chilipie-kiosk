# chilipie-kiosk

**Raspberry Pi 2** image for booting directly into **full-screen Chrome**.

Main features:

* **Boots directly to full-screen Chrome** - with all the features of a modern browser
* **No automatic updates** - no surprises due to Chrome (or other packages) suddenly updating
* **Automatic crash-recovery** - accidentally unplugging your kiosk won't result in a "Chrome did not shut down correctly" screen on next boot
* **Custom startup graphics** - displays [customizable graphics](home/background.png) while the browser is starting up
* **Lightweight window manager** - uses [Matchbox](https://www.yoctoproject.org/tools-resources/projects/matchbox) for minimal clutter and memory footprint
* **HDMI output control** - ready-made scripts for e.g. turning off the display outside of office hours
* **Cursor hiding** - if you leave a mouse plugged in, the cursor is hidden after a brief period of inactivity
* **Based on a recent Ubuntu** - if you want to add your own hacks, all the expected packages are one `apt-get` away
