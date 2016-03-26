#!/bin/bash

# Make sure Chromium profile is marked clean, even if it crashed
# https://stedolan.github.io/jq/manual/
if [ -f .config/chromium/Default/Preferences ]; then
    cat .config/chromium/Default/Preferences \
        | jq '.profile.exit_type = "SessionEnded" | .profile.exited_cleanly = true' \
        > .config/chromium/Default/Preferences-clean
    mv .config/chromium/Default/Preferences{-clean,}
fi

# http://peter.sh/experiments/chromium-command-line-switches/
chromium-browser --start-fullscreen
