# Misc tweaks

This file lists some things you can do to customize the image.

## Expanding the file system

If you want to make full use of your SD card size:

1. `$ sudo fdisk /dev/mmcblk0`
1. Delete the second partition (d, 2), then re-create it using the defaults (n, p, 2, enter, enter), then write and exit (w)
1. Reboot
1. `$ sudo resize2fs /dev/mmcblk0p2`
1. Reboot
