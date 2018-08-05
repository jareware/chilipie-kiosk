#!/bin/bash

sudo tvservice -p > /dev/null && sudo chvt 2 && sudo chvt 1 # for whatever reason, cycling virtual terminals helps wake up the display in some cases
