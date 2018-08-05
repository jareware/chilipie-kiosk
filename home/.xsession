#!/bin/bash

# Start cursor at the top-left corner, as opposed to the default of dead-center
# (so it doesn't accidentally trigger hover styles on elements on the page)
DISPLAY=:0.0 xdotool mousemove 0 0

# Set some useful X preferences
xset s off # don't activate screensaver
xset -dpms # disable DPMS (Energy Star) features.
xset s noblank # don't blank the video device

# Set X screen background
sudo nitrogen --set-centered background.png

# Hide cursor afer 5 seconds of inactivity
unclutter -idle 5 -root &

# Make sure Chromium profile is marked clean, even if it crashed
if [ -f .config/chromium/Default/Preferences ]; then
    cat .config/chromium/Default/Preferences \
        | jq '.profile.exit_type = "SessionEnded" | .profile.exited_cleanly = true' \
        > .config/chromium/Default/Preferences-clean
    mv .config/chromium/Default/Preferences{-clean,}
fi

# Remove notes of previous sessions, if any
find .config/chromium/ -name "Last *" | xargs rm

# Start and detach Chromium
# http://peter.sh/experiments/chromium-command-line-switches/
chromium-browser --start-fullscreen --disable-infobars &

# Finally, switch process to our window manager
exec matchbox-window-manager -use_titlebar no
