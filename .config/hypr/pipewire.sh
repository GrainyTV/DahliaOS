#!/bin/bash

#
# Wait for dbus user session to start
#
while [[ ! -S "$XDG_RUNTIME_DIR/bus" ]]; do
    sleep 1
done

pipewire &
while pw-cli info all 2>&1 | grep -q "failed to connect: Host is down"; do
    sleep 1
done

pipewire-pulse &
while pactl info 2>&1 | grep -q "Connection failure: Connection refused"; do
    sleep 1
done

wireplumber &
while wpctl inspect @DEFAULT_SINK@ 2>&1 | grep -q "Translate ID error: '-1' is not a valid ID"; do
    sleep 1
done
