#!/bin/sh
# Capture an emulator screenshot: tool/shot.sh <name>
adb exec-out screencap -p > ".impeccable/review/$1.png"
