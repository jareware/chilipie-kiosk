#!/bin/bash

MOUNTED_BOOT_VOLUME="boot" # i.e. under which name is the SD card mounted under /Volumes on macOS
SD_SIZE_REAL=2500 # this is in MB
SD_SIZE_SAFE=2800 # this is in MB
SD_SIZE_ZERO=3200 # this is in MB
PUBKEY="$(cat ~/.ssh/id_rsa.pub)"
KEYBOARD="fi"
TIMEZONE="Europe/Helsinki"

function working {
  echo -e "\n✨  $1"
}
function question {
  echo -e "\n🛑  $1"
}
function ssh {
  /usr/bin/ssh -o LogLevel=ERROR -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "pi@$IP" "$1"
}
function scp {
  /usr/bin/scp -o LogLevel=ERROR -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$@" "pi@$IP:/home/pi"
}

question "Enter version (e.g. \"1.2.3\") being built:"
read TAG

working "Updating version file"
echo -e "$TAG\n\nhttps://github.com/futurice/chilipie-kiosk" > home/.chilipie-kiosk-version

working "Generating first-boot.html"
if [ ! -d "node_modules" ]; then
  npm install markdown-styles@3.1.10 html-inline@1.2.0
fi
rm -rf md-input md-output
mkdir md-input md-output
cp first-boot.md md-input
./node_modules/.bin/generate-md --layout github --input md-input/ --output md-output/
./node_modules/.bin/html-inline -i md-output/first-boot.html > home/first-boot.html
rm -rf md-input md-output

question "Mount the SD card (press enter when ready)"
read

working "Figuring out SD card device"
diskutil list
DISK="$(diskutil list | grep /dev/ | grep external | grep physical | cut -d ' ' -f 1 | head -n 1)"

question "Based on the above, SD card determined to be \"$DISK\" (should be e.g. \"/dev/disk2\"), press enter to continue"
read

working "Safely unmounting the card"
diskutil unmountDisk "$DISK"

working "Writing the card full of zeros (for security and compressibility reasons)"
echo "This may take a long time"
echo "You may be prompted for your password by sudo"
sudo dd bs=1m count="$SD_SIZE_ZERO" if=/dev/zero of="$DISK"

question "Flash Raspbian Lite (2018-06-27-raspbian-stretch-lite.zip) with Etcher, then re-mount the card (press enter when ready)"
read

working "Updating /boot/cmdline.txt"
# The removal of "init=/usr/lib/raspi-config/init_resize.sh" disables the automatic expansion of the root FS to cover the whole SD card on first boot; the rest is for [customizing the Plymouth boot theme](https://scribles.net/customizing-boot-up-screen-on-raspberry-pi/)
echo -e "dwc_otg.lpm_enable=0 console=serial0,115200 console=tty3 root=PARTUUID=4d3ee428-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait quiet splash quiet plymouth.ignore-serial-consoles logo.nologo vt.global_cursor_default=0" \
  > "/Volumes/$MOUNTED_BOOT_VOLUME/cmdline.txt"

working "Updating /boot/config.txt"
sed -i "" "s/#disable_overscan=1/disable_overscan=1/g" "/Volumes/$MOUNTED_BOOT_VOLUME/config.txt"
echo -e "\ndisable_splash=1" >> "/Volumes/$MOUNTED_BOOT_VOLUME/config.txt"

working "Enabling SSH for first boot"
# https://www.raspberrypi.org/documentation/remote-access/ssh/
touch "/Volumes/$MOUNTED_BOOT_VOLUME/ssh"

working "Safely unmounting the card"
diskutil unmountDisk "$DISK"

question "Do initial Pi setup:"
echo "* Eject the card"
echo "* Boot the Pi from it"
echo "* Log in with \"pi:raspberry\""
echo "* Use \"ifconfig\" to check the IP address of the Pi"
echo "Enter the IP address:"
read IP

working "Installing temporary SSH pubkey"
echo -e "Password hint: \"raspberry\""
ssh "mkdir .ssh && echo '$PUBKEY' > .ssh/authorized_keys"

working "Figuring out partition start"
ssh "echo -e 'p\nq\n' | sudo fdisk /dev/mmcblk0 | grep /dev/mmcblk0p2 | tr -s ' ' | cut -d ' ' -f 2" > temp
START="$(cat temp)"
rm temp

question "Partition start determined to be \"$START\" (should be e.g. \"98304\"), press enter to continue"
read

working "Resizing the root partition on the Pi"
ssh "echo -e 'd\n2\nn\np\n2\n$START\n+${SD_SIZE_REAL}M\ny\nw\n' | sudo fdisk /dev/mmcblk0"

working "Setting hostname"
# We want to do this right before reboot, so we don't get a lot of unnecessary complaints about "sudo: unable to resolve host chilipie-kiosk" (https://askubuntu.com/a/59517)
ssh "sudo hostnamectl set-hostname chilipie-kiosk"
ssh "sudo sed -i 's/raspberrypi/chilipie-kiosk/g' /etc/hosts"

working "Rebooting the Pi"
ssh "sudo reboot"

question "Wait until the Pi has rebooted, press enter to continue"
read

working "Finishing the root partition resize"
ssh "df -h . && sudo resize2fs /dev/mmcblk0p2 && df -h ."

working "Enabling auto-login to CLI"
# From: https://github.com/RPi-Distro/raspi-config/blob/985548d7ca00cab11eccbb734b63750761c1f08a/raspi-config#L955
SUDO_USER=pi
ssh "sudo systemctl set-default multi-user.target"
ssh "sudo sed /etc/systemd/system/autologin@.service -i -e \"s#^ExecStart=-/sbin/agetty --autologin [^[:space:]]*#ExecStart=-/sbin/agetty --autologin $SUDO_USER#\""
ssh "sudo ln -fs /etc/systemd/system/autologin@.service /etc/systemd/system/getty.target.wants/getty@tty1.service"

working "Setting timezone"
ssh "(echo '$TIMEZONE' | sudo tee /etc/timezone) && sudo dpkg-reconfigure --frontend noninteractive tzdata"

working "Setting keyboard layout"
ssh "(echo -e 'XKBMODEL="pc105"\nXKBLAYOUT="$KEYBOARD"\nXKBVARIANT=""\nXKBOPTIONS=""\nBACKSPACE="guess"\n' | sudo tee /etc/default/keyboard) && sudo dpkg-reconfigure --frontend noninteractive keyboard-configuration"

working "Shortening message-of-the-day for logins"
ssh "sudo rm /etc/profile.d/sshpwd.sh"
ssh "echo | sudo tee /etc/motd"

working "Installing packages"
ssh "sudo apt-get update && sudo apt-get install -y vim matchbox-window-manager unclutter mailutils nitrogen jq chromium-browser xserver-xorg xinit rpd-plym-splash xdotool"
# We install mailutils just so that you can check "mail" for cronjob output

working "Setting home directory default content"
ssh "rm -rfv /home/pi/*"
scp $(find home -type file)

working "Setting splash screen background"
ssh "sudo rm /usr/share/plymouth/themes/pix/splash.png && sudo ln -s /home/pi/background.png /usr/share/plymouth/themes/pix/splash.png"

working "Installing default crontab"
ssh "crontab /home/pi/crontab.example"

working "Rebooting the Pi"
ssh "sudo reboot"

question "Once the Pi has rebooted into Chromium:"
echo "* Tell Chromium we don't want to sign in"
echo "* Configure Chromium to start \"where you left off\""
echo "* Navigate to \"file:///home/pi/first-boot.html\""
echo "(press enter when ready)"
read

working "Figuring out software versions"
ssh "hostnamectl | grep 'Operating System:' | tr -s ' ' | cut -d ' ' -f 4-" > temp
VERSION_LINUX="$(cat temp)"
ssh "hostnamectl | grep 'Kernel:' | tr -s ' ' | cut -d ' ' -f 3-4" > temp
VERSION_KERNEL="$(cat temp)"
ssh "chromium-browser --version | cut -d ' ' -f 1-2" > temp
VERSION_CHROMIUM="$(cat temp)"
rm temp

working "Removing temporary SSH pubkey, disabling SSH & shutting down"
ssh "(echo > .ssh/authorized_keys) && sudo systemctl disable ssh && sudo shutdown -h now"

question "Eject the SD card from the Pi, and mount it back to this computer (press enter when ready)"
read

working "Figuring out SD card device"
# We do this again now just to be safe
diskutil list
DISK="$(diskutil list | grep /dev/ | grep external | grep physical | cut -d ' ' -f 1 | head -n 1)"

question "Based on the above, SD card determined to be \"$DISK\" (should be e.g. \"/dev/disk2\"), press enter to continue"
read

working "Safely unmounting the card"
diskutil unmountDisk "$DISK"

working "Dumping the image from the card"
echo "This may take a long time"
echo "You may be prompted for your password by sudo"
sudo dd bs=1m count="$SD_SIZE_SAFE" if="$DISK" of="chilipie-kiosk-$TAG.img"

working "Compressing image"
COPYFILE_DISABLE=1 tar -zcvf chilipie-kiosk-$TAG.img.tar.gz chilipie-kiosk-$TAG.img

working "Listing image sizes"
du -hs chilipie-kiosk-$TAG.img*

working "Calculating image hashes"
openssl sha1 chilipie-kiosk-$TAG.img*

working "Software versions are:"
echo "* Linux: \`$VERSION_LINUX\`"
echo "* Kernel: \`$VERSION_KERNEL\`"
echo "* Chromium: \`$VERSION_CHROMIUM\`"
