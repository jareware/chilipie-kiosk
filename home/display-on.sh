#!/bin/bash

sudo tvservice -p > /dev/null && sudo chvt 1 && sudo chvt 8 # for whatever reason, cycling virtual terminals helps wake up the display in some cases
