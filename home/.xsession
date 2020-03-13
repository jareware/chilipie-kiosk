#!/bin/bash

export DISPLAY=:0.0

# Start cursor at the top-left corner, as opposed to the default of dead-center
# (so it doesn't accidentally trigger hover styles on elements on the page)
xdotool mousemove 0 0

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
# Note that under matchbox, starting in full-screen without a window size doesn't behave well when you try to exit full screen (see https://unix.stackexchange.com/q/273989)
chromium-browser \
  --start-fullscreen \
  --window-position=9000,9000 \
  --disable-infobars \
  --check-for-update-interval=1 --simulate-critical-update \
  &
# See https://github.com/futurice/chilipie-kiosk/issues/99#issuecomment-597119842 for the need for the fishy-sounding "--check-for-update-interval=1 --simulate-critical-update" switches; TODO: remove when not needed

# Hide Chromium while it's starting/loading the page
wid=`xdotool search --sync --onlyvisible --class chromium`
xdotool windowunmap $wid
sleep 10 # give the web page time to load
xdotool windowmap $wid

# Finally, switch process to our window manager
exec matchbox-window-manager -use_titlebar no
