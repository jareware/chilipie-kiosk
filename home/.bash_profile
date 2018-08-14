#!/bin/bash

# If this is a tty, and the one where we want to run X, do so
if [ "$(tty)" == "/dev/tty1" ]; then
  # Redirect any output so it doesn't briefly appear when starting X
  exec startx >/dev/null 2>&1
fi

# If this is a tty, and the one where we want to run raspi-config, do so
if [ "$(tty)" == "/dev/tty2" ]; then
  sudo raspi-config
fi
