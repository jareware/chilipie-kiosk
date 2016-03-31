#!/bin/bash

# Make sure Chromium profile is marked clean, even if it crashed
# https://stedolan.github.io/jq/manual/
if [ -f .config/chromium/Default/Preferences ]; then
    cat .config/chromium/Default/Preferences \
        | jq '.profile.exit_type = "SessionEnded" | .profile.exited_cleanly = true' \
        > .config/chromium/Default/Preferences-clean
    mv .config/chromium/Default/Preferences{-clean,}
fi

# Remove notes of previous sessions, if any
find .config/chromium/ -name "Last *" | xargs rm

# http://peter.sh/experiments/chromium-command-line-switches/
chromium-browser --start-fullscreen

# If you need to run Chromium manually for whatever reason:
# $ DISPLAY=:0.0 chromium-browser &
