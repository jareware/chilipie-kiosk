#!/bin/bash

nitrogen --set-centered background.png

xset s off         # don't activate screensaver
xset -dpms         # disable DPMS (Energy Star) features.
xset s noblank     # don't blank the video device

unclutter -idle 5 -root & # hide cursor afer 5 seconds of inactivity

exec matchbox-window-manager -use_titlebar no
