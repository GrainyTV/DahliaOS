#!/bin/bash

eww daemon
sleep 1s

eww open statusbar
sleep 1s

EWW="$HOME/.config/eww"
$EWW/scripts/search.zig &