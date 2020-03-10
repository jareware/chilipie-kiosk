#!/bin/bash

# exit on error; treat unset variables as errors; exit on errors in piped commands
set -euo pipefail

# Ensure we operate from consistent pwd for the rest of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # Figure out the ABSOLUTE PATH of this script without relying on the realpath command, which may not always be available
cd "$DIR"

if [ "$OSTYPE" == "linux-gnu" ]; then
  MOUNTED_BOOT_VOLUME="/media/$(whoami)/boot" # i.e. under which name is the SD card mounted under /media in Linux (Ubuntu)
  SD_DD_BS="1M"
  SD_DD_PROGRESS="status=progress"
elif [ "$OSTYPE" == "darwin" ]; then
  MOUNTED_BOOT_VOLUME="/Volumes/boot" # i.e. under which name is the SD card mounted under /Volumes on macOS
  SD_DD_BS="1m"
  SD_DD_PROGRESS=""
else
  echo "Error: Unsupported platform $OSTYPE, sorry"
  exit 1
fi

BOOT_CMDLINE_TXT="$MOUNTED_BOOT_VOLUME/cmdline.txt"
BOOT_CONFIG_TXT="$MOUNTED_BOOT_VOLUME/config.txt"
SD_SIZE_REAL=2500 # this is in MB
SD_SIZE_SAFE=2800 # this is in MB
SD_SIZE_ZERO=3200 # this is in MB
SSH_PUBKEY="$(cat ~/.ssh/id_rsa.pub)"
SSH_CONNECT_TIMEOUT=30
LOCALE="en_US.UTF-8 UTF-8" # or e.g. "fi_FI.UTF-8 UTF-8" for Finland
LANGUAGE="en_US.UTF-8" # should match above
KEYBOARD="us" # or e.g. "fi" for Finnish
TIMEZONE="Etc/UTC" # or e.g. "Europe/Helsinki"; see https://en.wikipedia.org/wiki/List_of_tz_database_time_zones

function echo-bold {
  echo -e "$(tput -Txterm-256color bold)$1$(tput -Txterm-256color sgr 0)" # https://unix.stackexchange.com/a/269085; the -T arg accounts for $ENV not being set
}
function working {
  echo-bold "\n[WORKING] $1"
}
function question {
  echo-bold "\n[QUESTION] $1"
}
function ssh {
  /usr/bin/ssh -o LogLevel=ERROR -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout="$SSH_CONNECT_TIMEOUT" "pi@$IP" "$1"
}
function scp {
  /usr/bin/scp -o LogLevel=ERROR -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$@" "pi@$IP:/home/pi"
}
function figureOutSdCard {
  if [ "$OSTYPE" == "linux-gnu" ]; then
    lsblk --fs
    DISK="/dev/$(lsblk -l | grep "$MOUNTED_BOOT_VOLUME" | sed 's/[0-9].*//')"
    DISK_SAMPLE="/dev/sda"
  elif [ "$OSTYPE" == "darwin" ]; then
    diskutil list
    DISK="$(diskutil list | grep /dev/ | grep external | grep physical | cut -d ' ' -f 1 | head -n 1)"
    DISK_SAMPLE="/dev/disk2"
  else
    echo "Error: Unsupported platform $OSTYPE, sorry"
    exit 1
  fi
}
function unmountSdCard {
  if [ "$OSTYPE" == "linux-gnu" ]; then
    for part in $(lsblk --list "$DISK" | grep part | sed 's/ .*//'); do
      udisksctl unmount -b "/dev/$part"
    done
  elif [ "$OSTYPE" == "darwin" ]; then
    diskutil unmountDisk "$DISK"
  else
    echo "Error: Unsupported platform $OSTYPE, sorry"
    exit 1
  fi
}

question "Enter version (e.g. \"1.2.3\") being built"
echo "Omit the \"v\" prefix, it'll be added where needed"
echo "For alpha/beta builds, use a \"-betaN\" suffic"
echo "For RC builds, DO NOT use any suffix, as then the same image can't be promoted to stable without rebuilding"
echo "Enter version:"
read TAG

working "Updating version file"
echo -e "$TAG\n\nhttps://github.com/futurice/chilipie-kiosk" > ../home/.chilipie-kiosk-version

working "Generating first-boot.html"
if [ ! -d "node_modules" ]; then
  npm install markdown-styles@3.1.10 html-inline@1.2.0
fi
rm -rf md-input md-output
mkdir md-input md-output
cp ../docs/first-boot.md md-input
./node_modules/.bin/generate-md --layout github --input md-input/ --output md-output/
./node_modules/.bin/html-inline -i md-output/first-boot.html > ../home/first-boot.html
rm -rf md-input md-output

question "Physically mount the SD card to this machine "
echo "(press enter when ready)"
read

working "Figuring out SD card device"
figureOutSdCard

question "Based on the above, SD card determined to be \"$DISK\" (should be e.g. \"$DISK_SAMPLE\"), press enter to continue"
read

working "Safely unmounting the card"
unmountSdCard

working "Writing the card full of zeros (for security and compressibility reasons)"
echo "This may take a long time"
echo "You may be prompted for your password by sudo"
sudo dd bs="$SD_DD_BS" count="$SD_SIZE_ZERO" if=/dev/zero of="$DISK" "$SD_DD_PROGRESS"

question "Prepare baseline Raspbian:"
echo "* Flash Raspbian Lite with Etcher"
echo "* Eject the SD card"
echo "* Mount the card back"
echo "* Wait for your OS to mount it"
echo "(press enter when ready)"
read

working "Backing up original boot files"
cp -v "$BOOT_CMDLINE_TXT" "$BOOT_CMDLINE_TXT.backup"
cp -v "$BOOT_CONFIG_TXT" "$BOOT_CONFIG_TXT.backup"

working "Disabling automatic root filesystem expansion"
echo "Updating: $BOOT_CMDLINE_TXT"
cat "$BOOT_CMDLINE_TXT" | sed "s#init=/usr/lib/raspi-config/init_resize.sh##" > temp
mv temp "$BOOT_CMDLINE_TXT"

working "Enabling SSH for first boot"
# https://www.raspberrypi.org/documentation/remote-access/ssh/
touch "$MOUNTED_BOOT_VOLUME/ssh"

working "Safely unmounting the card"
unmountSdCard

question "Do initial Pi setup:"
echo "* Eject the card"
echo "* Connect your Pi to Ethernet"
echo "* Boot the Pi from your card"
echo "* Make note of the \"My IP address is\" message at the end of boot"
echo "Enter the IP address:"
read IP

working "Installing temporary SSH pubkey"
echo -e "Password hint: \"raspberry\""
ssh "mkdir .ssh && echo '$SSH_PUBKEY' > .ssh/authorized_keys"

working "Figuring out partition start"
ssh "echo -e 'p\nq\n' | sudo fdisk /dev/mmcblk0 | grep /dev/mmcblk0p2 | tr -s ' ' | cut -d ' ' -f 2" > temp
START="$(cat temp)"
rm temp

question "Partition start determined to be \"$START\" (should be e.g. \"98304\"), press enter to continue"
read

working "Resizing the root partition on the Pi"
ssh "echo -e 'd\n2\nn\np\n2\n$START\n+${SD_SIZE_REAL}M\ny\nw\n' | sudo fdisk /dev/mmcblk0"

working "Setting locale"
# We want to do this as early as possible, so perl et al won't complain about misconfigured locales for the rest of the image prep
ssh "echo $LOCALE | sudo tee /etc/locale.gen"
ssh "sudo locale-gen"
ssh "echo -e \"LANGUAGE=$LANGUAGE\nLC_ALL=$LANGUAGE\" | sudo tee /etc/environment"

working "Setting hostname"
# We want to do this right before reboot, so we don't get a lot of unnecessary complaints about "sudo: unable to resolve host chilipie-kiosk" (https://askubuntu.com/a/59517)
ssh "sudo hostnamectl set-hostname chilipie-kiosk"
ssh "sudo perl -i -p0e 's/raspberrypi/chilipie-kiosk/g' /etc/hosts" # "perl" is more cross-platform than "sed -i"

# From now on, some ssh commands will exit non-0, which should be fine
set +e

working "Rebooting the Pi"
ssh "sudo reboot"

echo "Waiting for host to come back up..."
until SSH_CONNECT_TIMEOUT=5 ssh "echo OK"
do
  sleep 1
done

working "Finishing the root partition resize"
ssh "df -h . && sudo resize2fs /dev/mmcblk0p2 && df -h ."

# From raspi-config: https://github.com/RPi-Distro/raspi-config/blob/c0ddae8a2e99ecf15759c7cb8f0681cb0e7ce63a/raspi-config#L1141
# See also: https://github.com/futurice/chilipie-kiosk/issues/61#issuecomment-524622522
working "Enabling auto-login to CLI"
ssh "sudo systemctl set-default multi-user.target"
ssh "sudo ln -fs /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@tty1.service"
ssh "sudo ln -fs /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@tty2.service"
ssh "sudo ln -fs /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@tty3.service"
ssh "sudo mkdir -p /etc/systemd/system/getty@tty1.service.d"
ssh "sudo mkdir -p /etc/systemd/system/getty@tty2.service.d"
ssh "sudo mkdir -p /etc/systemd/system/getty@tty3.service.d"
ssh "echo -e '[Service]\nExecStart=\nExecStart=-/sbin/agetty --autologin pi --noclear %I \$TERM\n' | sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf"
ssh "echo -e '[Service]\nExecStart=\nExecStart=-/sbin/agetty --autologin pi --noclear %I \$TERM\n' | sudo tee /etc/systemd/system/getty@tty2.service.d/autologin.conf"
ssh "echo -e '[Service]\nExecStart=\nExecStart=-/sbin/agetty --autologin pi --noclear %I \$TERM\n' | sudo tee /etc/systemd/system/getty@tty3.service.d/autologin.conf"

working "Setting timezone"
ssh "(echo '$TIMEZONE' | sudo tee /etc/timezone) && sudo dpkg-reconfigure --frontend noninteractive tzdata"

working "Setting keyboard layout"
ssh "(echo -e 'XKBMODEL="pc105"\nXKBLAYOUT="$KEYBOARD"\nXKBVARIANT=""\nXKBOPTIONS=""\nBACKSPACE="guess"\n' | sudo tee /etc/default/keyboard) && sudo dpkg-reconfigure --frontend noninteractive keyboard-configuration"

working "Silencing console logins" # this is to avoid a brief flash of the console login before X comes up
ssh "sudo rm /etc/profile.d/sshpwd.sh /etc/profile.d/wifi-check.sh" # remove warnings about default password and WiFi country (https://raspberrypi.stackexchange.com/a/105234)
ssh "touch .hushlogin" # https://scribles.net/silent-boot-on-raspbian-stretch-in-console-mode/
ssh "sudo perl -i -p0e 's#--autologin pi#--skip-login --noissue --login-options \"-f pi\"#g' /etc/systemd/system/getty@tty1.service.d/autologin.conf" # "perl" is more cross-platform than "sed -i"

working "Installing packages"
ssh "sudo apt-get update && DEBIAN_FRONTEND=noninteractive sudo apt-get install -y vim matchbox-window-manager unclutter mailutils nitrogen jq chromium-browser xserver-xorg xinit rpd-plym-splash xdotool rng-tools xinput-calibrator"
# We install mailutils just so that you can check "mail" for cronjob output

working "Setting home directory default content"
ssh "rm -rfv /home/pi/*"
scp $(find ../home -type f)

working "Setting splash screen background"
ssh "sudo rm /usr/share/plymouth/themes/pix/splash.png && sudo ln -s /home/pi/background.png /usr/share/plymouth/themes/pix/splash.png"

working "Installing default crontab"
ssh "crontab /home/pi/crontab.example"

working "Rebooting the Pi"
ssh "sudo reboot"

question "Once the Pi has rebooted into Chromium:"
echo "* Tell Chromium we don't want to sign in"
echo "* Configure Chromium to start \"where you left off\""
echo "  * F11 to exit full screen"
echo "  * Alt + F, then S to go to Settings"
echo "  * Type \"continue\" to filter the options"
echo "  * Tab to select \"Continue where you left off\""
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

working "Removing SSH host keys & enable regeneration"
ssh "sudo rm -f -v /etc/ssh/ssh_host_*_key* && sudo systemctl enable regenerate_ssh_host_keys"

working "Removing temporary SSH pubkey & disabling SSH"
ssh "(echo > .ssh/authorized_keys) && sudo systemctl disable ssh"

working "Powering off the Pi"
ssh "sudo poweroff"

question "Eject the SD card from the Pi, and mount it back to this computer"
echo "(press enter when ready)"
read

# We do this again now just to be safe
working "Figuring out SD card device"
figureOutSdCard

question "Based on the above, SD card determined to be \"$DISK\" (should be e.g. \"$DISK_SAMPLE\"), press enter to continue"
read

working "Making boot quieter (part 1)" # https://scribles.net/customizing-boot-up-screen-on-raspberry-pi/
echo "Updating: $BOOT_CONFIG_TXT"
perl -i -p0e "s/#disable_overscan=1/disable_overscan=1/g" "$BOOT_CONFIG_TXT" # "perl" is more cross-platform than "sed -i"
echo -e "\ndisable_splash=1" >> "$BOOT_CONFIG_TXT"

working "Making boot quieter (part 2)" # https://scribles.net/customizing-boot-up-screen-on-raspberry-pi/
echo "You may want to revert these changes if you ever need to debug the startup process"
echo "Updating: $BOOT_CMDLINE_TXT"
cat "$BOOT_CMDLINE_TXT" \
  | sed 's/console=tty1/console=tty3/' \
  | sed 's/$/ splash plymouth.ignore-serial-consoles logo.nologo vt.global_cursor_default=0/' \
  > temp
mv temp "$BOOT_CMDLINE_TXT"

working "Safely unmounting the card"
unmountSdCard

working "Dumping the image from the card"
cd ..
echo "This may take a long time"
echo "You may be prompted for your password by sudo"
sudo dd bs="$SD_DD_BS" count="$SD_SIZE_SAFE" if="$DISK" of="chilipie-kiosk-$TAG.img" "$SD_DD_PROGRESS"

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
