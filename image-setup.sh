#!/bin/bash

MOUNTED_BOOT_VOLUME="boot" # i.e. under which name is the SD card mounted under /Volumes on macOS
SD_SIZE_REAL=2500 # this is in MB
SD_SIZE_SAFE=2800 # this is in MB
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

question "Enter version being built (e.g. \"1.2.3\")"
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

question "Safely unmount the card, boot the Pi from it, run \"sudo raspi-config\", and:"
echo "* Under \"Boot Options\", select \"Console Autologin\""
echo "(press enter when ready)"
read

question "Enter the IP address of the Pi (use \"ifconfig\" if in doubt)"
read IP
SSH="ssh -o LogLevel=ERROR -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null pi@$IP"

working "Installing temporary SSH pubkey"
echo -e "Password hint: \"raspberry\""
ssh "mkdir .ssh && echo '$PUBKEY' > .ssh/authorized_keys"

working "Figuring out partition start"
enter='\\n'
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

working "Rebooting the Pi"
ssh "sudo reboot"

question "Wait until the Pi has rebooted, press enter to continue"
read

working "Finishing the root partition resize"
ssh "df -h . && sudo resize2fs /dev/mmcblk0p2 && df -h ."

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
ssh "rm -rf /home/pi/*"
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

working "Removing temporary SSH pubkey, disabling SSH & shutting down"
ssh "(echo > .ssh/authorized_keys) && sudo systemctl disable ssh && sudo shutdown -h now"
