#!/bin/bash

# If this is a tty, and the one where we want to run X, do so
if [ "$(tty)" == "/dev/tty1" ]; then
  exec startx
fi
