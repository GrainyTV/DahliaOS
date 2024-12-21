#!/bin/bash

CONFIG="$HOME/.config"
HYPR="$CONFIG/hypr"
EWW="$CONFIG/eww"

# ======================= #
# Creating a DBUS session #
# ======================= #

dbus-daemon --fork --session --address=unix:path=$XDG_RUNTIME_DIR/bus

# ================================== #
# Opening EWW instance and statusbar #
# ================================== #

eww daemon
eww open statusbar

# =========================== #
# Populating the app launcher #
# =========================== #

$EWW/scripts/search.zig
# eww update searchContent="$( eww get filteredSearchContent )"
