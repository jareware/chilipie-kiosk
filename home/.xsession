#!/bin/bash

xset s off         # don't activate screensaver
xset -dpms         # disable DPMS (Energy Star) features.
xset s noblank     # don't blank the video device

unclutter -idle 5 -root & # hide cursor afer 5 seconds of inactivity

~/on-pi-startup.sh & # start our default application

sudo nitrogen --set-centered background.png # set X screen background

exec matchbox-window-manager -use_titlebar no # switch to our window manager
